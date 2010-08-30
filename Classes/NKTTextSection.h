//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaCore.h"

//--------------------------------------------------------------------------------------------------
// NKTTextSection renders a frame's worth of typesetted text. It is used internally by NKTTextView.
//--------------------------------------------------------------------------------------------------

@interface NKTTextSection : UIView
{
@private
    NSInteger index;
    
    NSArray *typesettedLines;
    
    UIEdgeInsets margins;
    CGFloat lineHeight;
    NSUInteger numberOfSkirtLines;

    BOOL horizontalRulesEnabled;
    UIColor *horizontalRuleColor;
    CGFloat horizontalRuleOffset;
    
    BOOL verticalMarginEnabled;
    UIColor *verticalMarginColor;
    CGFloat verticalMarginInset;
}

#pragma mark Configuring the Text Section

@property (nonatomic, readwrite) NSInteger index;

@property (nonatomic, readwrite, retain) NSArray *typesettedLines;

@property (nonatomic, readwrite) UIEdgeInsets margins;
@property (nonatomic, readwrite) CGFloat lineHeight;
@property (nonatomic, readwrite) NSUInteger numberOfSkirtLines;

@property (nonatomic, readwrite) BOOL horizontalRulesEnabled;
@property (nonatomic, readwrite, retain) UIColor *horizontalRuleColor;
@property (nonatomic, readwrite) CGFloat horizontalRuleOffset;

@property (nonatomic, readwrite) BOOL verticalMarginEnabled;
@property (nonatomic, readwrite, retain) UIColor *verticalMarginColor;
@property (nonatomic, readwrite) CGFloat verticalMarginInset;

@end
