//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>
#import "NKTTextView.h"

//--------------------------------------------------------------------------------------------------
// NotekataViewController
//--------------------------------------------------------------------------------------------------

@interface NotekataViewController : UIViewController <NKTTextViewDelegate>
{
@private
    UIToolbar *toolbar;
    UIView *edgeView;
    NKTTextView *textView;
}

@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UIView *edgeView;
@property (nonatomic, retain) IBOutlet NKTTextView *textView;

@end
