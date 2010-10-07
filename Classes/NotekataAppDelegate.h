//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

@class NKTTextViewController;

// NotekataAppDelegate
@interface NotekataAppDelegate : NSObject <UIApplicationDelegate>
{
    UIWindow *window;
    NKTTextViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet NKTTextViewController *viewController;

@end
