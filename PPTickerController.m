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
static const double kSmooth = 0.9;

@interface PPTickerController ()
@property (retain, nonatomic) NSURLConnection *conn;
@property (retain, nonatomic) NSTimer *timer;
@property (retain, nonatomic) NSDate *previousTime;
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
	[countField setStringValue:NSLocalizedString(@"Loading...", NULL)];
	[self makeRequest];
	[panel setFloatingPanel:YES];
	[panel setHidesOnDeactivate:NO];
	rateAccumulator = NAN;
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
	BOOL failed = NO;
	NSString *newCountString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	NSInteger newCount = [newCountString integerValue];
	if (newCount < 0)
	{
		newCount = previousCount;
		failed = YES;
	}
	if(initialValue == 0)
		initialValue = newCount;
	
	NSInteger diff = newCount - initialValue;
	
	NSString *diffString = [NSString stringWithFormat:@"%+d", diff];
	
	if (!failed)
	{
		NSDate *now = [NSDate date];
		if (self.previousTime != nil)
		{
			NSInteger deltaN = newCount - previousCount;
			NSTimeInterval deltaT = [now timeIntervalSinceDate:self.previousTime];
			double rate = (double)(deltaN * 3600) / deltaT;
			
			if (isnan(rateAccumulator))  rateAccumulator = rate;
			else  rateAccumulator = kSmooth * rateAccumulator + (1.0 - kSmooth) * rate;
			
			// NSLog(@"DeltaN: %d, deltaT: %g, rate: %g, accum: %g", deltaN, deltaT, rate, rateAccumulator);
			
			if (abs(rateAccumulator) < 10)
			{
				diffString = [diffString stringByAppendingFormat:@", %+.1f/h", rateAccumulator];
			}
			else
			{
				diffString = [diffString stringByAppendingFormat:@", %+d/h", lround(rateAccumulator)];
			}
		}
		self.previousTime = now;
		previousCount = newCount;
	}
	
	NSString *countString = [NSString stringWithFormat:@"%d%s", newCount, failed ? "?" : ""];
	diffString = [NSString stringWithFormat:@"  (%@)", diffString];
	
	NSDictionary *diffAttr = [NSDictionary dictionaryWithObjectsAndKeys:
							  [NSColor colorWithCalibratedRed:0.10 green:0.60 blue:0 alpha:1.0],NSForegroundColorAttributeName,
							  [NSFont systemFontOfSize:11.0], NSFontAttributeName,
							  nil];
	
	NSMutableAttributedString *displayString = [[[NSMutableAttributedString alloc] initWithString:countString] autorelease];
	NSAttributedString *displayDiffString = [[[NSAttributedString alloc] initWithString:diffString attributes:diffAttr] autorelease];
	[displayString appendAttributedString:displayDiffString];
	[displayString setAlignment:NSCenterTextAlignment range:NSMakeRange(0, displayString.length)];
	[countField setObjectValue:displayString];
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
@synthesize previousTime;
-(void)setTimer:(NSTimer*)timer_;
{
	if(timer == timer_) return;
	
	[timer invalidate];
	[timer release];
	[timer_ retain];
	timer = timer_;
}
@end
