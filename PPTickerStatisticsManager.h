#import <Foundation/Foundation.h>

@class PPTickerStatsTracker;
@protocol PPTickerStatisticsManagerDelegate;



@interface PPTickerStatisticsManager: NSObject
{
@private
#if !__OBJC2__
	id <PPTickerStatisticsManagerDelegate> _delegate;
	
	NSUInteger					_memberCount;
	NSUInteger					_growthRate;
	
	PPTickerStatsTracker		*_statsTracker;
	NSURLConnection				*_connection;
	NSDate						*_previousTime;
	NSUInteger					_initialValue;
	NSTimeInterval				_latency;
#endif
	NSTimer						*_timer;
}

@property (nonatomic, assign) IBOutlet id <PPTickerStatisticsManagerDelegate> delegate;

@property (readonly, nonatomic) NSUInteger memberCount;
@property (readonly, nonatomic) double growthRate;
@property (readonly, nonatomic) BOOL hasMeaningfulGrowthRate;

@end


@protocol PPTickerStatisticsManagerDelegate <NSObject>
@optional

- (void) statisticsManagerUpdated:(PPTickerStatisticsManager *)statsManager;
- (void) statisticsManagerUpdateFailed:(PPTickerStatisticsManager *)statsManager;

- (void) statisticsManagerStartedDownload:(PPTickerStatisticsManager *)statsManager;
- (void) statisticsManagerEndedDownload:(PPTickerStatisticsManager *)statsManager;

@end
