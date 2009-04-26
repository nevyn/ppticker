#import "PPTickerViewController.h"


@interface PPTickerViewController ()

@property (nonatomic, retain, readwrite) IBOutlet UILabel *countField;
@property (nonatomic, retain, readwrite) IBOutlet UILabel *rateField;
@property (nonatomic, retain, readwrite) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, retain, readwrite) IBOutlet UILabel *connectionFailureLabel;
@property (nonatomic, retain, readwrite) IBOutlet PPTickerStatisticsManager *statisticsManager;

- (void) setDisplayCount:(NSUInteger)count
		 secondaryString:(NSString *)secondaryString
		  secondaryColor:(UIColor *)secondaryColor;

@end


@implementation PPTickerViewController

@synthesize countField = _countField, rateField = _rateField, spinner = _spinner, connectionFailureLabel = _connectionFailureLabel, statisticsManager = _statisticsManager;


- (void)dealloc
{
	self.countField = nil;
	self.rateField = nil;
	self.spinner = nil;
	self.connectionFailureLabel = nil;
	self.statisticsManager = nil;
	
    [super dealloc];
}


- (void)didReceiveMemoryWarning
{
	self.countField = nil;
	self.rateField = nil;
	self.spinner = nil;
	self.connectionFailureLabel = nil;
	
    [super didReceiveMemoryWarning];
}


- (void) viewDidLoad
{
	[self.spinner startAnimating];
}


#pragma mark Statistics manager delegate

- (void) statisticsManagerUpdated:(PPTickerStatisticsManager *)statsManager
{
	NSString		*string = nil;
	UIColor			*color = nil;
	
	if (statsManager.hasMeaningfulGrowthRate)
	{
		double displayRate = statsManager.growthRate;
		if (abs(displayRate) < 10)
		{
			string = [NSString stringWithFormat:@"%+.1f/h", displayRate];
		}
		else
		{
			string = [NSString stringWithFormat:@"%+d/h", lround(displayRate)];
		}
		
		if (displayRate >= 0)
		{
			color = [UIColor colorWithHue:110.0 / 360.0	// Green
							   saturation:1.0
							   brightness:0.7
									alpha:1.0];
		}
		else
		{
			color = [UIColor colorWithHue:0		// Red
							   saturation:1.0
							   brightness:0.9
									alpha:1.0];
		}
	}
	
	[self setDisplayCount:statsManager.memberCount
		  secondaryString:string
		   secondaryColor:color];
	
	self.connectionFailureLabel.hidden = YES;
}


- (void) statisticsManagerUpdateFailed:(PPTickerStatisticsManager *)statsManager
{
	UIColor *color = [UIColor colorWithHue:45.0 / 360.0	// Orange-yellow
								saturation:1.0
								brightness:1.0
									 alpha:1.0];
	
	[self setDisplayCount:statsManager.memberCount
		  secondaryString:@"?"
		   secondaryColor:color];
	
	self.connectionFailureLabel.hidden = NO;
}


- (void) statisticsManagerStartedDownload:(PPTickerStatisticsManager *)statsManager
{
	[self.spinner startAnimating];
}


- (void) statisticsManagerEndedDownload:(PPTickerStatisticsManager *)statsManager
{
	[self.spinner stopAnimating];
}


- (void) setDisplayCount:(NSUInteger)count
		 secondaryString:(NSString *)secondaryString
		  secondaryColor:(UIColor *)secondaryColor
{
	NSString *countString = [NSString stringWithFormat:@"%ld", (long)count];
	self.countField.text = countString;
	self.rateField.text = secondaryString ?: @"";
	self.rateField.textColor = secondaryColor ?: [UIColor blackColor];
}

@end
