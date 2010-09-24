//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaUI.h"

//--------------------------------------------------------------------------------------------------
// NKTFontPickerView
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

#pragma mark Accessing the Font Picker Subviews

@property (nonatomic, retain) KUISegmentedControl *fontSizeSegmentedControl;
@property (nonatomic, retain) UITableView *fontFamilyTableView;

@end
