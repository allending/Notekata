//
//  Copyright Allen Ding 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NKTPageView;

@interface NotekataViewController : UIViewController {
    
}

@property (nonatomic, retain) IBOutlet NKTPageView *pageView;
@property (nonatomic, retain) IBOutlet UIView *coverView;

- (IBAction)performAction1;
- (IBAction)performAction2;
- (IBAction)performAction3;
- (IBAction)performAction4;

@end
