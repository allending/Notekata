//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

@class NKTCaret;
@class NKTDragGestureRecognizer;
@class NKTTextPosition;
@class NKTTextRange;
@class NKTTextViewGestureRecognizerDelegate;

//--------------------------------------------------------------------------------------------------
// NKTTextView implements the behavior for a view similar to UITextView, but with support for text
// styling with attributes, and customizations to simulate printed pages.
//--------------------------------------------------------------------------------------------------

@interface NKTTextView : UIScrollView <UIKeyInput, UIGestureRecognizerDelegate>
{
@private
    NSMutableAttributedString *text;
    
    UIEdgeInsets margins;
    CGFloat lineHeight;
    
    BOOL horizontalRulesEnabled;
    UIColor *horizontalRuleColor;
    CGFloat horizontalRuleOffset;
    BOOL verticalMarginEnabled;
    UIColor *verticalMarginColor;
    CGFloat verticalMarginInset;
    
    NSMutableArray *typesettedLines;
    
    NSMutableSet *visibleSections;
    NSMutableSet *reusableSections;
    
    NKTTextRange *selectedTextRange;
    
    NKTCaret *selectionCaret;
    UIView *selectionBandTop;
    UIView *selectionBandMiddle;
    UIView *selectectionBandBottom;
    
    NKTTextViewGestureRecognizerDelegate *gestureRecognizerDelegate;
    UITapGestureRecognizer *preFirstResponderTapGestureRecognizer;
    UITapGestureRecognizer *tapGestureRecognizer;
    NKTDragGestureRecognizer *doubleTapAndDragGestureRecognizer;
    NKTTextPosition *doubleTapStartTextPosition;
}

#pragma mark Accessing the Text

@property (nonatomic, readwrite, retain) NSMutableAttributedString *text;

#pragma mark Configuring Text Layout and Style

@property (nonatomic, readwrite) UIEdgeInsets margins;
@property (nonatomic, readwrite) CGFloat lineHeight;

@property (nonatomic, readwrite) BOOL horizontalRulesEnabled;
@property (nonatomic, readwrite, retain) UIColor *horizontalRuleColor;
@property (nonatomic, readwrite) CGFloat horizontalRuleOffset;
@property (nonatomic, readwrite) BOOL verticalMarginEnabled;
@property (nonatomic, readwrite, retain) UIColor *verticalMarginColor;
@property (nonatomic, readwrite) CGFloat verticalMarginInset;

#pragma mark Accessing Gesture Recognizers

@property (nonatomic, readonly) UITapGestureRecognizer *preFirstResponderTapGestureRecognizer;
@property (nonatomic, readonly) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, readonly) NKTDragGestureRecognizer *doubleTapAndDragGestureRecognizer;

@end
