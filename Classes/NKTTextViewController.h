//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaUI.h"
#import "NKTFontPickerViewController.h"
#import "NKTTextView.h"

typedef enum
{
    NKTPageStylePlain,
    NKTPageStylePlainRuled,
    NKTPageStylePlainRuledVerticalMargin,
    NKTPageStyleCream,
    NKTPageStyleCreamRuled,
    NKTPageStyleCreamRuledVerticalMargin
} NKTPageStyle;

// NotekataViewController
@interface NKTTextViewController : UIViewController <NKTTextViewDelegate, NKTFontPickerViewControllerDelegate>
{
@private
    UIToolbar *toolbar_;
    UILabel *titleLabel_;
    UIView *edgeView_;
    NKTTextView *textView_;
    
    KUIToggleButton *boldToggleButton_;
    KUIToggleButton *italicToggleButton_;
    KUIToggleButton *underlineToggleButton_;
    UIButton *fontButton_;
    UIBarButtonItem *fontToolbarItem_;
    NKTFontPickerViewController *fontPickerViewController_;
    UIPopoverController *fontPopoverController_;
    
    NKTPageStyle pageStyle_;
}

#pragma mark Managing Views

@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) IBOutlet UIView *edgeView;
@property (nonatomic, retain) IBOutlet NKTTextView *textView;

#pragma mark Configuring the Page Style

@property (nonatomic) NKTPageStyle pageStyle;

@end
