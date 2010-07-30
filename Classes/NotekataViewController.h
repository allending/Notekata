//
//  Copyright Allen Ding 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NKTPageView;
@class NKTTextView;

@interface NotekataViewController : UIViewController {
    
}

@property (nonatomic, retain) IBOutlet NKTTextView *textView;
@property (nonatomic, retain) IBOutlet UIView *coverView;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;

@end
