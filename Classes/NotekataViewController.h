//===================================================================================================
//
// Copyright 2010 Allen Ding. All rights reserved.
//
//===================================================================================================

#import <UIKit/UIKit.h>

@class NKTTextView;

//===================================================================================================
// NotekataViewController
//===================================================================================================

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
