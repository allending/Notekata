//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaUI.h"

//--------------------------------------------------------------------------------------------------
// NKTFontPickerView is a view that contains ans lays out a font size control and a font family
// table view. The interface is tuned so that end users can quickly make changes to fonts. Users
// should use NKTFontPickerViewController instead of this class directly.
//--------------------------------------------------------------------------------------------------

@interface NKTFontPickerView : UIView
{
@private
    KUISegmentedControl *fontSizeSegmentedControl_;
    UITableView *fontFamilyTableView_;
    UIImageView *tableViewTopCap_;
    UIImageView *tableViewBottomCap_;
    UIImageView *tableViewLeftBorder_;
    UIImageView *tableViewRightBorder_;
    CGRect lastLayoutFrame_;
}

#pragma mark Accessing Font Picker Subviews

@property (nonatomic, retain) KUISegmentedControl *fontSizeSegmentedControl;
@property (nonatomic, retain) UITableView *fontFamilyTableView;

@end
