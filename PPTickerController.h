#import <Cocoa/Cocoa.h>
#import "PPTickerStatisticsManager.h"

#define	DUMP_CSV	0


@interface PPTickerController: NSObject <PPTickerStatisticsManagerDelegate>
{
#if !__OBJC2__
	NSTextField					*_countField;
	NSProgressIndicator			*_spinner;
	NSPanel						*_panel;
	PPTickerStatisticsManager	*_statisticsManager;
	
#if DUMP_CSV
	FILE						*_debugOut;
#endif
#endif
}

@property (readonly, retain, nonatomic) IBOutlet NSTextField *countField;
@property (readonly, retain, nonatomic) IBOutlet NSProgressIndicator *spinner;
@property (readonly, retain, nonatomic) IBOutlet NSPanel *panel;
@property (readonly, retain, nonatomic) IBOutlet PPTickerStatisticsManager *statisticsManager;

@end
