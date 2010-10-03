//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaUI.h"

@class NKTFramesetter;

//--------------------------------------------------------------------------------------------------
// NKTTextSection renders a frame's worth of typesetted text. It is used internally by NKTTextView.
//--------------------------------------------------------------------------------------------------

@interface NKTTextSection : UIView
{
@private
    NSInteger index_;
    NKTFramesetter *framesetter_;
    UIEdgeInsets margins_;
    CGFloat lineHeight_;
    NSUInteger numberOfSkirtLines_;
    BOOL horizontalRulesEnabled_;
    UIColor *horizontalRuleColor_;
    CGFloat horizontalRuleOffset_;
    BOOL verticalMarginEnabled_;
    UIColor *verticalMarginColor_;
    CGFloat verticalMarginInset_;
}

#pragma mark Configuring the Text Section

@property (nonatomic) NSInteger index;
@property (nonatomic, assign) NKTFramesetter *framesetter;
@property (nonatomic) UIEdgeInsets margins;
@property (nonatomic) CGFloat lineHeight;
@property (nonatomic) NSUInteger numberOfSkirtLines;
@property (nonatomic, getter = areHorizontalRulesEnabled) BOOL horizontalRulesEnabled;
@property (nonatomic, retain) UIColor *horizontalRuleColor;
@property (nonatomic) CGFloat horizontalRuleOffset;
@property (nonatomic, getter = isVerticalMarginEnabled) BOOL verticalMarginEnabled;
@property (nonatomic, retain) UIColor *verticalMarginColor;
@property (nonatomic) CGFloat verticalMarginInset;

@end
