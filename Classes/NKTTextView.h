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
    
    NKTTextRange *selectedTextRange;
    NKTTextRange *markedTextRange;
    NSDictionary *markedTextStyle;
    NSString *markedText;
    id <UITextInputDelegate> inputDelegate;
    UITextInputStringTokenizer *tokenizer;
    
    NKTSelectionDisplayController *selectionDisplayController_;
    NKTLoupe *selectionCaretLoupe;
    NKTLoupe *selectionBandLoupe;
    
    NKTTextViewGestureRecognizerDelegate *gestureRecognizerDelegate;
    UITapGestureRecognizer *nonEditTapGestureRecognizer;
    UITapGestureRecognizer *tapGestureRecognizer;
    UILongPressGestureRecognizer *longPressGestureRecognizer;
    NKTDragGestureRecognizer *doubleTapAndDragGestureRecognizer;
    NKTTextPosition *doubleTapStartTextPosition;
}

#pragma mark Accessing the Text

@property (nonatomic, readwrite, retain) NSMutableAttributedString *text;

#pragma mark Managing the Delegate

//@property (nonatomic, assign) id <NKTTextViewDelegate> delegate;

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

@property (nonatomic, readonly) UITapGestureRecognizer *nonEditTapGestureRecognizer;
@property (nonatomic, readonly) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, readonly) NKTDragGestureRecognizer *doubleTapAndDragGestureRecognizer;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------------------------------------

@protocol NKTTextViewDelegate <UIScrollViewDelegate>

@optional

- (UIView *)textViewViewForZooming:(NKTTextView *)textView;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------

@interface NKTTextView(PropertyRedeclarations)

@property (nonatomic, readwrite, assign) id <NKTTextViewDelegate> delegate;

@end
