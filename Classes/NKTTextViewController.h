//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaUI.h"
#import "NKTTextView.h"

//--------------------------------------------------------------------------------------------------
// NotekataViewController
//--------------------------------------------------------------------------------------------------

@interface NKTTextViewController : UIViewController <NKTTextViewDelegate>
{
@private
    UIToolbar *toolbar_;
    UIView *edgeView_;
    NKTTextView *textView_;
    KUIToggleButton *boldToggleButton_;
    KUIToggleButton *italicToggleButton_;
    KUIToggleButton *underlineToggleButton_;
}

#pragma mark Managing Views

@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UIView *edgeView;
@property (nonatomic, retain) IBOutlet NKTTextView *textView;

@end