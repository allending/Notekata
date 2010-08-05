//
//  Copyright Allen Ding 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NKTPaperView;
@class NKTTextView;

@interface NotekataViewController : UIViewController {
@private
    UIToolbar *toolbar;
    UIView *edgeView;
    NKTTextView *textView;
    NKTPaperView *firstPaperView;
    NKTPaperView *secondPaperView;
}

@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UIView *edgeView;
@property (nonatomic, retain) IBOutlet NKTTextView *textView;
@property (nonatomic, retain) NKTPaperView *firstPaperView;
@property (nonatomic, retain) NKTPaperView *secondPaperView;

@end
