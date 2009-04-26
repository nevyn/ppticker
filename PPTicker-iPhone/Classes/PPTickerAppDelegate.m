//
//  PPTicker_iPhoneAppDelegate.m
//  PPTicker-iPhone
//
//  Created by Jens Ayton on 2009-04-26.
//  Copyright Jens Ayton 2009. All rights reserved.
//

#import "PPTickerAppDelegate.h"
#import "PPTickerViewController.h"

@implementation PPTickerAppDelegate

@synthesize window;
@synthesize viewController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {    
    
    // Override point for customization after app launch    
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
}


- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}


@end
