//
//  PPTickerStatsTracker.h
//  PPTicker
//
//  Created by Jens Ayton on 2009-04-23.
//  Copyright 2009 Jens Ayton. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PPTickerStatsTracker: NSObject
{
@private
	NSString					*_preferencesKey;
	NSMutableArray				*_data;
	NSTimeInterval				_maximumAge;
	NSTimeInterval				_growthRateTimeSpan;
	double						_growthRate;
	NSDate						*_date;
	BOOL						_growthRateDirty;
}

- (id) initWithPreferencesKey:(NSString *)prefsKey;

@property (readonly, copy) NSString *preferencesKey;

@property NSTimeInterval maximumAge;			// Maximum age for which data is tracked
@property NSTimeInterval growthRateTimeSpan;	// Time span over which growth rate is tracked

- (void) addDataPoint:(NSUInteger)memberCount withTimeStamp:(NSDate *)timeStamp;

@property (readonly) double growthRate;			// Growth rate in members/hour

// Nominal current date. If nil, [NSDate date] is used.
@property (copy) NSDate *date;

@property (readonly) BOOL hasMeaningfulGrowthRate;

@end
