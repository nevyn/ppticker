//
//  PPTickerAppDelegate.h
//  PPTicker-iPhone
//
//  Created by Jens Ayton on 2009-04-26.
//  Copyright Jens Ayton 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PPTickerViewController;

@interface PPTickerAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    PPTickerViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet PPTickerViewController *viewController;

@end

