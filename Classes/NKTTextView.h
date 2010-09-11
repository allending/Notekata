//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaCore.h"
#import "NKTSelectionDisplayController.h"

@class NKTDragGestureRecognizer;
@class NKTLoupe;
@class NKTTextPosition;
@class NKTTextRange;
@class NKTTextView;
@class NKTTextViewGestureRecognizerDelegate;

//--------------------------------------------------------------------------------------------------
// NKTTextView implements the behavior for a view with support for text styling and printed-page
// look styling.
//--------------------------------------------------------------------------------------------------

@interface NKTTextView : UIScrollView <UITextInput, UIGestureRecognizerDelegate, NKTSelectionDisplayControllerDelegate>
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
    NSMutableSet *underlayViews;
    NSMutableSet *overlayViews;
    
    NKTTextRange *selectedTextRange;
    NKTTextRange *markedTextRange;
    NSDictionary *markedTextStyle;
    NSString *markedText;
    NKTTextRange *provisionalTextRange_;
    
    id <UITextInputDelegate> inputDelegate;
    UITextInputStringTokenizer *tokenizer;
    
    NKTSelectionDisplayController *selectionDisplayController_;
    NKTLoupe *bandLoupe_;
    NKTLoupe *roundLoupe_;
    
    NKTTextViewGestureRecognizerDelegate *gestureRecognizerDelegate;
    UITapGestureRecognizer *nonEditTapGestureRecognizer;
    UITapGestureRecognizer *tapGestureRecognizer;
    UILongPressGestureRecognizer *longPressGestureRecognizer;
    NKTDragGestureRecognizer *doubleTapAndDragGestureRecognizer;
    NKTTextPosition *doubleTapStartTextPosition_;
}

#pragma mark Accessing the Text

@property (nonatomic, retain) NSMutableAttributedString *text;

#pragma mark Configuring Text Layout and Style

@property (nonatomic, readwrite) UIEdgeInsets margins;
@property (nonatomic, readwrite) CGFloat lineHeight;

@property (nonatomic) BOOL horizontalRulesEnabled;
@property (nonatomic, retain) UIColor *horizontalRuleColor;
@property (nonatomic) CGFloat horizontalRuleOffset;
@property (nonatomic) BOOL verticalMarginEnabled;
@property (nonatomic, retain) UIColor *verticalMarginColor;
@property (nonatomic) CGFloat verticalMarginInset;

#pragma mark Accessing Gesture Recognizers

@property (nonatomic, readonly) UITapGestureRecognizer *nonEditTapGestureRecognizer;
@property (nonatomic, readonly) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, readonly) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, readonly) NKTDragGestureRecognizer *doubleTapAndDragGestureRecognizer;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------------------------------------

@protocol NKTTextViewDelegate <UIScrollViewDelegate>

@optional

- (UIColor *)loupeFillColor;
- (UIView *)addLoupe:(UIView *)view;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------

@interface NKTTextView(PropertyRedeclarations)

@property (nonatomic, readwrite, assign) id <NKTTextViewDelegate> delegate;

@end
