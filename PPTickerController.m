#import "PPTickerController.h"


@interface PPTickerController ()

@property (readwrite, retain, nonatomic) IBOutlet NSTextField *countField;
@property (readwrite, retain, nonatomic) IBOutlet NSProgressIndicator *spinner;
@property (readwrite, retain, nonatomic) IBOutlet NSPanel *panel;
@property (readwrite, retain, nonatomic) IBOutlet PPTickerStatisticsManager *statisticsManager;

#if DUMP_CSV
@property FILE *debugOut;
#endif

- (void) setDisplayCount:(NSUInteger)count
		 secondaryString:(NSString *)secondaryString
		  secondaryColor:(NSColor *)secondaryColor
		   secondarySize:(CGFloat)secondarySize;

@end


@implementation PPTickerController

@synthesize countField = _countField, spinner = _spinner, panel = _panel, statisticsManager = _statisticsManager;


-(void)awakeFromNib
{
	[self.countField setStringValue:NSLocalizedString(@"Loading...", NULL)];
	[self.panel setFloatingPanel:YES];
	[self.panel setHidesOnDeactivate:NO];
	
#if DUMP_CSV
	self.debugOut = fopen("debug.csv", "w");
	if (self.debugOut != NULL)  fputs("Time,Interval (s),Count,Delta,Instantaneous rate/h,Smoothed rate/h\n", debugOut);
#endif
}


#pragma mark Statistics manager delegate

- (void) statisticsManagerUpdated:(PPTickerStatisticsManager *)statsManager
{
	NSString		*string = nil;
	NSColor			*color = nil;
	
	if (statsManager.hasMeaningfulGrowthRate)
	{
		double displayRate = statsManager.growthRate;
		if (abs(displayRate) < 10)
		{
			string = [NSString stringWithFormat:@"(%+.1f/h)", displayRate];
		}
		else
		{
			string = [NSString stringWithFormat:@"(%+d/h)", lround(displayRate)];
		}
		
		if (displayRate > 0)
		{
			color = [NSColor colorWithCalibratedHue:110.0 / 360.0	// Green
										 saturation:1.0
										 brightness:0.7
											  alpha:1.0];
		}
		else
		{
			color = [NSColor colorWithCalibratedHue:0		// Red
										 saturation:1.0
										 brightness:0.9
											  alpha:1.0];
		}
	}
	
	[self setDisplayCount:statsManager.memberCount
		  secondaryString:string
		   secondaryColor:color
			secondarySize:[NSFont smallSystemFontSize]];
}


- (void) statisticsManagerUpdateFailed:(PPTickerStatisticsManager *)statsManager
{
	NSColor *color = [NSColor colorWithCalibratedHue:45.0 / 360.0	// Orange-yellow
										  saturation:1.0
										  brightness:1.0
											   alpha:1.0];
	
	[self setDisplayCount:statsManager.memberCount
		  secondaryString:@"?"
		   secondaryColor:color
			secondarySize:[NSFont smallSystemFontSize]];
}


- (void) statisticsManagerStartedDownload:(PPTickerStatisticsManager *)statsManager
{
	[self.spinner startAnimation:self];
}


- (void) statisticsManagerEndedDownload:(PPTickerStatisticsManager *)statsManager
{
	[self.spinner stopAnimation:self];
}


- (void) setDisplayCount:(NSUInteger)count
		 secondaryString:(NSString *)secondaryString
		  secondaryColor:(NSColor *)secondaryColor
		   secondarySize:(CGFloat)secondarySize
{
	NSMutableAttributedString *displayString = [[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld", (long)count]] autorelease];
	
	if (secondaryString != nil)
	{
		secondaryString = [@"  " stringByAppendingString:secondaryString];
		if (secondaryColor == nil)  secondaryColor = [NSColor whiteColor];
		
		NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
							  secondaryColor, NSForegroundColorAttributeName,
							   [NSFont systemFontOfSize:secondarySize], NSFontAttributeName,
							   nil];
		
		[displayString appendAttributedString:[[[NSAttributedString alloc] initWithString:secondaryString attributes:attrs] autorelease]];
	}
	
	[displayString setAlignment:NSCenterTextAlignment range:NSMakeRange(0, displayString.length)];
	self.countField.objectValue = displayString;
}


#pragma mark Window delegate

- (void)windowWillClose:(NSNotification *)notification
{
	if (notification.object == self.panel)
	{
		[self.panel orderOut:self];
		[NSApp terminate:self];
	}
}

@end
