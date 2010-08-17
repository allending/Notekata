//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NKTCaret;

@interface NKTTextView : UIScrollView <UIKeyInput> {
@private
    NSAttributedString *text;
    
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
    
    UITapGestureRecognizer *tapGestureRecognizer;
    NKTCaret *caret;
    
#if !defined(NKT_STRIP_DEBUG_SUPPORT)
    
    BOOL debug_alternatesSectionBackgroundColors;
    
#endif // #if !defined(NKT_STRIP_DEBUG_SUPPORT)
}

#pragma mark -
#pragma mark Accessing the Text

@property (nonatomic, readwrite, copy) NSAttributedString *text;

#pragma mark -
#pragma mark Configuring Text Layout

@property (nonatomic, readwrite) UIEdgeInsets margins;
@property (nonatomic, readwrite) CGFloat lineHeight;

#pragma mark -
#pragma mark Configuring the View Style

@property (nonatomic, readwrite) BOOL horizontalRulesEnabled;
@property (nonatomic, readwrite, retain) UIColor *horizontalRuleColor;
@property (nonatomic, readwrite) CGFloat horizontalRuleOffset;

@property (nonatomic, readwrite) BOOL verticalMarginEnabled;
@property (nonatomic, readwrite, retain) UIColor *verticalMarginColor;
@property (nonatomic, readwrite) CGFloat verticalMarginInset;

#if !defined(NKT_STRIP_DEBUG_SUPPORT)

#pragma mark -
#pragma mark Debugging

@property (nonatomic, readwrite) BOOL debug_alternatesSectionBackgroundColors;

#endif // #if !defined(NKT_STRIP_DEBUG_SUPPORT)

@end
