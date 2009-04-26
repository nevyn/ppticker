#import "PPTickerStatisticsManager.h"
#import "PPTickerStatsTracker.h"


static NSString *PPTickerURL = @"http://lekstuga.piratpartiet.se/membersfeed";

#define kDesiredInterval	15.0
#define kMinimumInterval	10.0
#define kLatencySmooth		0.667


@interface PPTickerStatisticsManager () <PPTickerStatisticsManagerDelegate>

@property (readwrite, nonatomic) NSUInteger memberCount;
@property (retain, nonatomic) PPTickerStatsTracker *statsTracker;
@property (retain, nonatomic) NSURLConnection *connection;
@property (retain, nonatomic) NSTimer *timer;
@property (retain, nonatomic) NSDate *previousTime;
@property (nonatomic) NSUInteger initialValue;
@property (nonatomic) NSTimeInterval latency;

-(void)makeRequest;
-(void)scheduleRequest;

@end


@implementation PPTickerStatisticsManager

- (id) init
{
	if ((self = [super init]))
	{
		[self makeRequest];
		self.statsTracker = [[[PPTickerStatsTracker alloc] initWithPreferencesKey:@"statistics"] autorelease];
		self.previousTime = [NSDate date];
		self.latency = NAN;
		
#if DUMP_CSV
		_debugOut = fopen("debug.csv", "w");
		if (_debugOut != NULL)  fputs("Time,Interval (s),Count,Delta,Instantaneous rate/h,Smoothed rate/h\n", _debugOut);
#endif
	}
	return self;
}


- (void) dealloc
{
	self.statsTracker = nil;
	[self.connection cancel];
	self.connection = nil;
	self.timer = nil;
	self.previousTime = nil;
	
	[super dealloc];
}


-(void)makeRequest
{
	self.connection = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:PPTickerURL]]  delegate:self];
	[self statisticsManagerStartedDownload:self];
}


-(void)scheduleRequest
{
	[self statisticsManagerEndedDownload:self];
	self.connection = nil;
	
	NSTimeInterval delay = fmax(kDesiredInterval - self.latency, kMinimumInterval);
	
	self.timer = [NSTimer scheduledTimerWithTimeInterval:delay
												  target:self
												selector:@selector(makeRequest)
												userInfo:nil
												 repeats:NO];
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
	[self statisticsManagerUpdateFailed:self];
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	NSString *newCountString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	NSInteger newCount = [newCountString integerValue];
	NSDate *now = [NSDate date];
	
	/*	Update running latency estimate.
		This is smoothed (in a simple way) to avoid transient spikes.
	*/
	BOOL firstTime = isnan(self.latency);
	
	NSTimeInterval deltaT = [now timeIntervalSinceDate:self.previousTime];
	if (firstTime)  self.latency = deltaT;
	else  self.latency += (deltaT - kDesiredInterval) * (1.0 - kLatencySmooth);
	
#if DUMP_CSV
	if (_debugOut != NULL && !firstTime)
	{
		NSInteger deltaN = newCount - self.memberCount;
		double rate = (double)(deltaN * 3600) / deltaT;
		fprintf(_debugOut, "%s,%g,%lu,%li,%g,%g\n", [[now description] UTF8String], deltaT, (unsigned long)deltaN, (long)(newCount - self.memberCount), rate, self.statsTracker.growthRate);
		fflush(_debugOut);
	}
#endif
	
	if (newCount <= 0)
	{
		[self statisticsManagerUpdateFailed:self];
		return;
	}
	
	if (self.initialValue == 0)  self.initialValue = newCount;
	
	// Update growth rate estimate.
	[self.statsTracker addDataPoint:newCount withTimeStamp:now];
	
	self.memberCount = newCount;
	[self statisticsManagerUpdated:self];
}


#pragma mark
#pragma mark Delegate handling

- (void) statisticsManagerUpdated:(PPTickerStatisticsManager *)statsManager
{
	if ([self.delegate respondsToSelector:@selector(statisticsManagerUpdated:)] && self.delegate != self)
	{
		[self.delegate statisticsManagerUpdated:self];
	}
}


- (void) statisticsManagerUpdateFailed:(PPTickerStatisticsManager *)statsManager
{
	if ([self.delegate respondsToSelector:@selector(statisticsManagerUpdated:)] && self.delegate != self)
	{
		[self.delegate statisticsManagerUpdateFailed:self];
	}
}


- (void) statisticsManagerStartedDownload:(PPTickerStatisticsManager *)statsManager
{
	if ([self.delegate respondsToSelector:@selector(statisticsManagerStartedDownload:)] && self.delegate != self)
	{
		[self.delegate statisticsManagerStartedDownload:self];
	}
}


- (void) statisticsManagerEndedDownload:(PPTickerStatisticsManager *)statsManager
{
	if ([self.delegate respondsToSelector:@selector(statisticsManagerEndedDownload:)] && self.delegate != self)
	{
		[self.delegate statisticsManagerEndedDownload:self];
	}
}


#pragma mark
#pragma mark Accessors

@synthesize delegate = _delegate;
@synthesize memberCount = _memberCount;
@synthesize statsTracker = _statsTracker;
@synthesize connection = _connection;
@synthesize timer = _timer;
@synthesize previousTime = _previousTime;
@synthesize initialValue = _initialValue;
@synthesize latency = _latency;


-(void)setTimer:(NSTimer*)timer;
{
	if(_timer == timer) return;
	
	[_timer invalidate];
	[_timer release];
	[timer retain];
	_timer = timer;
}


- (double) growthRate
{
	return self.statsTracker.growthRate;
}


- (BOOL) hasMeaningfulGrowthRate
{
	return self.statsTracker.hasMeaningfulGrowthRate;
}

@end
