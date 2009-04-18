//
//  PPTickerController.h
//  PPTicker
//
//  Created by Joachim Bengtsson on 2009-04-18.
//  Copyright 2009 Third Cog Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PPTickerController : NSObject {
	IBOutlet NSTextField *count;
	IBOutlet NSTextField *countAdded;
	NSInteger initialValue;
	NSURLConnection *conn;
	NSTimer *timer;
	IBOutlet NSProgressIndicator *spinner;
	IBOutlet NSPanel *panel;
}

@end
