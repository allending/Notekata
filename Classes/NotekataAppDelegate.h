//
//  Copyright Allen Ding 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NotekataViewController;

@interface NotekataAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    NotekataViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet NotekataViewController *viewController;

@end
