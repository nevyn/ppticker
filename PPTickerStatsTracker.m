//
//  PPTickerStatsTracker.m
//  PPTicker
//
//  Created by Jens Ayton on 2009-04-23.
//  Copyright 2009 Jens Ayton. All rights reserved.
//

#import "PPTickerStatsTracker.h"


#define kMemberCountKey				@"member count"
#define kTimeStampKey				@"time stamp"
#define kDefaultMaximumAge			(7 * 24 * 60 * 60)	/* One week */
#define kDefaultGrowthRateTimeSpan	(60 * 60)			/* One hour */
#define kUsefulDataThreshold		10					/* Samples required for growth rate to be considered useful */


// Takes a normalized time in the range 0 (beginning of filter span) to 1 (now); returns a weight. Negative values are possible!
typedef double (*FilterFunction)(double);


@interface PPTickerStatsTracker ()

@property (readwrite, copy) NSString *preferencesKey;
@property (readonly) NSTimeInterval workingDate;

- (void) loadData;
- (void) writeData;

- (void) calculateGrowthRate;

- (void) clearOldEntries;

- (void) doAddDataPoint:(NSUInteger)memberCount withTimeStamp:(NSTimeInterval)timeStamp;
- (NSUInteger) findDataIndexForTimeStamp:(NSTimeInterval)timeStamp;
- (void) getDataPoint:(NSUInteger *)outMemberCount andTimeStamp:(NSTimeInterval *)outTimeStamp atIndex:(NSUInteger)index;

- (double) calculateGrowthRateWithFilter:(FilterFunction)filter;

@end


CFComparisonResult CompareEntries(const void *val1, const void *val2, void *context);


static double BoxFilter(double t)
{
	return 1.0;
}


static double LinearRampFilter(double t)
{
	return t;
}


static double SineEaseOutFilter(double t)
{
	return sin(M_PI_2 * t);
}


static double CubicFilter(double t)
{
	/*	Cubic ease in/ease out curve. (This is the cubic Hermite basis function
		h2(t), or h01(t) in Wikipedia's notation.) This is very close to a
		cosine interpolation, (1 - cos πx) / 2 (maximum error 1% in [0..1]).
	*/
	return -2.0 * t * t * t + 3.0 * t * t;
}


@implementation PPTickerStatsTracker

@synthesize preferencesKey = _preferencesKey, maximumAge = _maximumAge, growthRateTimeSpan = _growthRateTimeSpan, date = _date;


- (id) initWithPreferencesKey:(NSString *)prefsKey
{
	if ((self = [super init]))
	{
		self.preferencesKey = prefsKey;
		self.maximumAge = kDefaultMaximumAge;
		self.growthRateTimeSpan = kDefaultGrowthRateTimeSpan;
		
		[self loadData];
	}
	return self;
}


- (void) dealloc
{
	self.preferencesKey = nil;
	[_data release];
	_data = nil;
	
	[super dealloc];
}


- (void) setMaximumAge:(NSTimeInterval)maximumAge
{
	NSParameterAssert(maximumAge > 0);
	
	if (maximumAge < _maximumAge)  [self clearOldEntries];
	_maximumAge = maximumAge;
}


- (void) addDataPoint:(NSUInteger)memberCount withTimeStamp:(NSDate *)timeStamp
{
	[self doAddDataPoint:memberCount withTimeStamp:[timeStamp timeIntervalSinceReferenceDate]];
	[self clearOldEntries];
	[self writeData];
}


- (double) growthRate
{
	if (_growthRateDirty)
	{
		[self calculateGrowthRate];
	}
	return _growthRate;
}


- (BOOL) hasMeaningfulGrowthRate
{
	// Initial zeros are pointless.
	NSUInteger count = _data.count;
	NSUInteger startOfMeaningfulData = [self findDataIndexForTimeStamp:self.workingDate - self.growthRateTimeSpan];
	return count - startOfMeaningfulData >= kUsefulDataThreshold;
}


- (void) loadData
{
	if (self.preferencesKey == nil)  return;
	
	NSArray *data = [[NSUserDefaults standardUserDefaults] arrayForKey:self.preferencesKey];
	if (data == nil)  return;
	
	for (NSDictionary *dataPoint in data)
	{
		if (![dataPoint isKindOfClass:[NSDictionary class]])  continue;
		
		NSNumber *memberCount = [dataPoint objectForKey:kMemberCountKey];
		NSNumber *timeStamp = [dataPoint objectForKey:kTimeStampKey];
		
		if (![memberCount respondsToSelector:@selector(unsignedIntegerValue)] ||
			![timeStamp respondsToSelector:@selector(doubleValue)])  continue;
		
		[self doAddDataPoint:[memberCount unsignedIntegerValue]
			   withTimeStamp:[timeStamp doubleValue]];
	}
}


- (void) writeData
{
	if (self.preferencesKey == nil || _data == nil)  return;
	
	[[NSUserDefaults standardUserDefaults] setObject:_data forKey:self.preferencesKey];
}


#if 0
- (void) calculateGrowthRate
{
	NSTimeInterval now = [[NSDate date] timeIntervalSinceReferenceDate];
	
	NSUInteger index = [self findDataIndexForTimeStamp:now - self.growthRateTimeSpan];
	if (index >= _data.count)
	{
		_growthRate = 0.0f;
	}
	else
	{
		// Simple box filter. A linearly weighted average would probably be better. Comparing a few options would definitely be better.
		NSUInteger startCount, endCount;
		NSTimeInterval startTime, endTime;
		[self getDataPoint:&startCount andTimeStamp:&startTime atIndex:index];
		[self getDataPoint:&endCount andTimeStamp:&endTime atIndex:_data.count - 1];
		
		_growthRate = ((double)endCount - (double)startCount) * 3600.0 / (endTime - startTime);
		
		// Triangle filter
		double weightAccum = 0, totalAccum = 0;
		NSUInteger initialCount;
		[self getDataPoint:&initialCount andTimeStamp:NULL atIndex:index];
		for (NSUInteger i = index; i < _data.count; i++)
		{
			NSUInteger count;
			NSTimeInterval time;
			[self getDataPoint:&count andTimeStamp:&time atIndex:i];
			double weight = 1.0 - (now - time) / self.growthRateTimeSpan;
			if (weight < 0.0)  weight = 0.0;
			weightAccum += weight;
			totalAccum += weight * ((NSInteger)count - (NSInteger)initialCount);
		}
		_growthRateTri = totalAccum / weightAccum;
		
		// Cubic s-curve filter
		weightAccum = 0;
		totalAccum = 0;
		for (NSUInteger i = index; i < _data.count; i++)
		{
			NSUInteger count;
			NSTimeInterval time;
			[self getDataPoint:&count andTimeStamp:&time atIndex:i];
			double weight = InterpolateCubic((now - time) / self.growthRateTimeSpan);
			if (weight < 0.0)  weight = 0.0;
			weightAccum += weight;
			totalAccum += weight * ((NSInteger)count - (NSInteger)initialCount);
		}
		_growthRateCub = totalAccum / weightAccum;
	}
	_growthRateDirty = NO;
}
#else
- (void) calculateGrowthRate
{
	_growthRate = [self calculateGrowthRateWithFilter:SineEaseOutFilter];
}
#endif


- (double) calculateGrowthRateWithFilter:(FilterFunction)filter
{
	NSTimeInterval now = self.workingDate;
	
	NSUInteger index = [self findDataIndexForTimeStamp:now - self.growthRateTimeSpan];
	if (index >= _data.count - 1)
	{
		return 0.0;
	}
	else
	{
		double weightAccum = 0.0, totalAccum = 0.0;
		NSUInteger count, previousCount;
		NSTimeInterval time, previousTime;
		[self getDataPoint:&count andTimeStamp:&time atIndex:index];
		
		for (NSUInteger i = index + 1; i < _data.count; i++)
		{
			previousCount = count;
			previousTime = time;
			[self getDataPoint:&count andTimeStamp:&time atIndex:i];
			
			double weight = 1.0 - (now - time) / self.growthRateTimeSpan;
			if (weight < 0.0)  weight = 0.0;
			weight = filter(weight);
			
			weightAccum += weight;
			
			double rate = (double)((NSInteger)count - (NSInteger)previousCount) * 3600.0 / (time - previousTime);
			totalAccum += weight * rate;	//* ((NSInteger)count - (NSInteger)previousCount);
		}
		
		return totalAccum / weightAccum;
	}
}


- (NSTimeInterval) workingDate
{
	return [(self.date ?: [NSDate date]) timeIntervalSinceReferenceDate];
}


- (void) clearOldEntries
{
	NSTimeInterval cutoff = [[NSDate date] timeIntervalSinceReferenceDate] - self.maximumAge;
	
	while (_data.count != 0 && [[[_data objectAtIndex:0] objectForKey:kTimeStampKey] doubleValue] < cutoff)
	{
		[_data removeObjectAtIndex:0];
	}
}


- (void) doAddDataPoint:(NSUInteger)memberCount withTimeStamp:(NSTimeInterval)timeStamp
{
	if (_data == nil)  _data = [[NSMutableArray alloc] init];
	
	NSDictionary *entry = [NSDictionary dictionaryWithObjectsAndKeys:
						   [NSNumber numberWithUnsignedInteger:memberCount], kMemberCountKey,
						   [NSNumber numberWithDouble:timeStamp], kTimeStampKey,
						   nil];
	
	[self willChangeValueForKey:@"hasMeaningfulGrowthRate"];
	[self willChangeValueForKey:@"growthRate"];
	
	NSUInteger index = [self findDataIndexForTimeStamp:timeStamp];
	if (index >= _data.count)  [_data addObject:entry];
	else  [_data insertObject:entry atIndex:index];
	
	_growthRateDirty = YES;
	[self didChangeValueForKey:@"hasMeaningfulGrowthRate"];
	[self didChangeValueForKey:@"growthRate"];
}


- (NSUInteger) findDataIndexForTimeStamp:(NSTimeInterval)timeStamp
{
	NSDictionary *dummyEntry = [NSDictionary dictionaryWithObject:[NSNumber numberWithDouble:timeStamp]
														   forKey:kTimeStampKey];
	return CFArrayBSearchValues((CFArrayRef)_data, CFRangeMake(0, _data.count), dummyEntry, CompareEntries, NULL);
}


- (void) getDataPoint:(NSUInteger *)outMemberCount andTimeStamp:(NSTimeInterval *)outTimeStamp atIndex:(NSUInteger)index
{
	NSDictionary *entry = [_data objectAtIndex:index];
	
	if (outMemberCount != NULL)  *outMemberCount = [[entry objectForKey:kMemberCountKey] unsignedIntegerValue];
	if (outTimeStamp != NULL)  *outTimeStamp = [[entry objectForKey:kTimeStampKey] doubleValue];
}

@end


CFComparisonResult CompareEntries(const void *val1, const void *val2, void *context)
{
	NSDictionary *entry1 = (void *)val1, *entry2 = (void *)val2;
	
	NSTimeInterval time1 = [[entry1 objectForKey:kTimeStampKey] doubleValue];
	NSTimeInterval time2 = [[entry2 objectForKey:kTimeStampKey] doubleValue];
	
	if (time1 < time2)
	{
		return kCFCompareLessThan;
	}
	if (time1 > time2)
	{
		return kCFCompareGreaterThan;
	}
	return kCFCompareEqualTo;
}
