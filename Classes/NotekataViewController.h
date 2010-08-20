//
//  Copyright Allen Ding 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NKTTextView;

@interface NotekataViewController : UIViewController <UIScrollViewDelegate> {
@private
    UIToolbar *toolbar;
    UIView *edgeView;
    NKTTextView *textView;
}

@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UIView *edgeView;
@property (nonatomic, retain) IBOutlet NKTTextView *textView;

@end
