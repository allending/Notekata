//--------------------------------------------------------------------------------------------------
//
// Copyright 2010 Allen Ding. All rights reserved.
//
//--------------------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

@class NotekataViewController;

//--------------------------------------------------------------------------------------------------
// NotekataAppDelegate
//--------------------------------------------------------------------------------------------------

@interface NotekataAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    NotekataViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet NotekataViewController *viewController;

@end
