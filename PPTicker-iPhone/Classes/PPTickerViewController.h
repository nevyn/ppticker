#import <UIKit/UIKit.h>
#import "PPTickerStatisticsManager.h"


@interface PPTickerViewController: UIViewController <PPTickerStatisticsManagerDelegate>
#if !__OBJC2__
{
@private
	UILabel							*_countField;
	UILabel							*_rateField;
	PPTickerStatisticsManager		*_statisticsManager;
	UILabel							*_connectionFailureLabel;
	UIActivityIndicatorView			*_spinner;
}
#endif

@property (nonatomic, retain, readonly) IBOutlet UILabel *countField;
@property (nonatomic, retain, readonly) IBOutlet UILabel *rateField;
@property (nonatomic, retain, readonly) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, retain, readonly) IBOutlet UILabel *connectionFailureLabel;
@property (nonatomic, retain, readonly) IBOutlet PPTickerStatisticsManager *statisticsManager;

@end
