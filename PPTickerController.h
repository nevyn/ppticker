#import <Cocoa/Cocoa.h>
#import "PPTickerStatisticsManager.h"


@interface PPTickerController: NSObject <PPTickerStatisticsManagerDelegate>
{
#if !__OBJC2__
	NSTextField					*_countField;
	NSProgressIndicator			*_spinner;
	NSPanel						*_panel;
	PPTickerStatisticsManager	*_statisticsManager;
#endif
}

@property (readonly, retain, nonatomic) IBOutlet NSTextField *countField;
@property (readonly, retain, nonatomic) IBOutlet NSProgressIndicator *spinner;
@property (readonly, retain, nonatomic) IBOutlet NSPanel *panel;
@property (readonly, retain, nonatomic) IBOutlet PPTickerStatisticsManager *statisticsManager;

@end
