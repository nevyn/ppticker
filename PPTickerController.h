//
//  PPTickerController.h
//  PPTicker
//
//  Created by Joachim Bengtsson on 2009-04-18.
//  Copyright 2009 Third Cog Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define	DUMP_CSV	0

@class PPTickerStatsTracker;


@interface PPTickerController: NSObject
{
	IBOutlet NSTextField *countField;
	PPTickerStatsTracker *statsTracker;
	NSInteger initialValue;
	NSURLConnection *conn;
	NSTimer *timer;
	IBOutlet NSProgressIndicator *spinner;
	IBOutlet NSPanel *panel;
	NSTimeInterval latency;
	NSDate *previousTime;
	NSInteger previousCount;
	
#if DUMP_CSV
	FILE *debugOut;
#endif
}

@end
