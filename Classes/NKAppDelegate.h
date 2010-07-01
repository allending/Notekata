//
//  Copyright Allen Ding 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NKViewController;

@interface NKAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    NKViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet NKViewController *viewController;

@end
