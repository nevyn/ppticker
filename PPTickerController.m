//
//  PPTickerController.m
//  PPTicker
//
//  Created by Joachim Bengtsson on 2009-04-18.
//  Copyright 2009 Third Cog Software. All rights reserved.
//

#import "PPTickerController.h"
#import "PPTickerStatsTracker.h"

static NSString *PPTickerURL = @"http://lekstuga.piratpartiet.se/membersfeed";
#define kDesiredInterval	15.0
#define kMinimumInterval	10.0
#define kLatencySmooth		0.667


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
	NSTimeInterval delay = fmax(kDesiredInterval - latency, kMinimumInterval);
	
	self.timer = [NSTimer scheduledTimerWithTimeInterval:delay
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
	statsTracker = [[PPTickerStatsTracker alloc] initWithPreferencesKey:@"statistics"];
	self.previousTime = [NSDate date];
	latency = NAN;
	
#if DUMP_CSV
	debugOut = fopen("debug.csv", "w");
	if (debugOut != NULL)  fputs("Time,Interval (s),Count,Delta,Instantaneous rate/h,Smoothed rate/h\n", debugOut);
#endif
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
	BOOL firstTime = NO;
	
	NSString *newCountString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	NSInteger newCount = [newCountString integerValue];
	
	firstTime = isnan(latency);
	
	if (newCount <= 0)
	{
		newCount = previousCount;
		failed = YES;
	}
	if(initialValue == 0)
	{
		initialValue = newCount;
	}
	
	NSDate *now = [NSDate date];
	NSString *diffString = nil;
	
	/*	Update running latency estimate.
		This is smoothed (in a simple way) to avoid transient spikes.
	*/
	NSTimeInterval deltaT = [now timeIntervalSinceDate:self.previousTime];
	if (firstTime)  latency = deltaT;
	else  latency = latency + (deltaT - kDesiredInterval) * (1.0 - kLatencySmooth);
	
	if (!failed)
	{
		// Update growth rate estimate.
		[statsTracker addDataPoint:newCount withTimeStamp:now];
		
		if (statsTracker.hasMeaningfulGrowthRate)
		{
			double displayRate = statsTracker.growthRate;
			if (abs(displayRate) < 10)
			{
				diffString = [NSString stringWithFormat:@"%+.1f/h", displayRate];
			}
			else
			{
				diffString = [NSString stringWithFormat:@"%+d/h", lround(displayRate)];
			}
		}
		
#if DUMP_CSV
		// Dump CSV for graphing in spreadsheet.
		if (debugOut != NULL && !firstTime)
		{
			NSInteger deltaN = newCount - previousCount;
			double rate = (double)(deltaN * 3600) / deltaT;
			fprintf(debugOut, "%s,%g,%u,%i,%g,%g\n", [[now description] UTF8String], deltaT, newCount, deltaN, rate, statsTracker.growthRate);
			fflush(debugOut);
			NSLog(@"%lu, %+g (dT: %g, latency: %g, latency update: %g)", newCount, statsTracker.growthRate, [now timeIntervalSinceDate:self.previousTime], latency, deltaT - kDesiredInterval);
			self.previousTime = now;
		}
#endif
	}
	
	previousCount = newCount;
	
	// Build styled string for display.
	NSString *countString = [NSString stringWithFormat:@"%d", newCount];
	NSMutableAttributedString *displayString = [[[NSMutableAttributedString alloc] initWithString:countString] autorelease];
	NSAttributedString *displayDiffString = nil;
	
	if (failed)
	{
		displayDiffString = [[[NSAttributedString alloc] initWithString:@" ?" attributes:[NSDictionary dictionaryWithObject:[NSColor redColor] forKey:NSForegroundColorAttributeName]] autorelease];
	}
	else if (diffString.length != 0)
	{
		diffString = [NSString stringWithFormat:@"  (%@)", diffString];
		
		NSDictionary *diffAttr = [NSDictionary dictionaryWithObjectsAndKeys:
								  [NSColor colorWithCalibratedRed:0.10 green:0.60 blue:0 alpha:1.0],NSForegroundColorAttributeName,
								  [NSFont systemFontOfSize:11.0], NSFontAttributeName,
								  nil];
		
		displayDiffString = [[[NSAttributedString alloc] initWithString:diffString attributes:diffAttr] autorelease];
	}
	
	if (displayDiffString != nil)  [displayString appendAttributedString:displayDiffString];
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
