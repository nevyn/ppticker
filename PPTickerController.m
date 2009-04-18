//
//  PPTickerController.m
//  PPTicker
//
//  Created by Joachim Bengtsson on 2009-04-18.
//  Copyright 2009 Third Cog Software. All rights reserved.
//

#import "PPTickerController.h"

static NSString *PPTickerURL = @"http://lekstuga.piratpartiet.se/membersfeed";
static const NSTimeInterval requestInterval = 5.0;

@interface PPTickerController ()
@property (retain, nonatomic) NSURLConnection *conn;
@property (retain, nonatomic) NSTimer *timer;
@end


@implementation PPTickerController
-(void)makeRequest;
{
	self.conn = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:PPTickerURL]]  delegate:self];
	[self.conn start];
	[spinner startAnimation:nil];
}
-(void)scheduleRequest;
{
	[spinner stopAnimation:nil];
	self.conn = nil;
	self.timer = [NSTimer scheduledTimerWithTimeInterval:requestInterval
												  target:self
												selector:@selector(makeRequest)
												userInfo:nil
												 repeats:NO];
}
-(void)awakeFromNib;
{
	[self makeRequest];
	[count setStringValue:@""];
	[countAdded setStringValue:@""];
	[panel setFloatingPanel:YES];
	[panel setHidesOnDeactivate:NO];
}

#pragma mark Socket callbacks
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[self scheduleRequest];
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[self scheduleRequest];
	NSLog(@"Connection failed: %@", error);
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	NSString *newCountString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	NSInteger newCount = [newCountString integerValue];
	if(initialValue == 0)
		initialValue = newCount;
	
	NSInteger diff = newCount - initialValue;
	
	[count setIntegerValue:newCount];
	[countAdded setStringValue:[NSString stringWithFormat:@"(+%d)", diff]];
}

#pragma mark 
#pragma mark Window delegates
- (void)windowWillClose:(NSNotification *)notification
{
	[NSApp terminate:self];
}

#pragma mark
#pragma mark Accessors
@synthesize conn;
@synthesize timer;
-(void)setTimer:(NSTimer*)timer_;
{
	if(timer == timer_) return;
	
	[timer invalidate];
	[timer release];
	[timer_ retain];
	timer = timer_;
}
@end
