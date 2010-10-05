//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaUI.h"
#import "NKTSelectionDisplayController.h"
#import "NKTTextPosition.h"
#import "NKTTextRange.h"

@class NKTFramesetter;
@class NKTDragGestureRecognizer;
@class NKTLoupe;
@class NKTTextViewGestureRecognizerDelegate;
@class NKTTextViewTokenizer;

//--------------------------------------------------------------------------------------------------
// NKTTextView implements the behavior for a view with support for text styling and printed-page
// look styling.
//--------------------------------------------------------------------------------------------------

@interface NKTTextView : UIScrollView <UITextInput, UIGestureRecognizerDelegate, NKTSelectionDisplayControllerDelegate>
{
@private
    NSMutableAttributedString *text_;
    NKTFramesetter *framesetter_;
    
    // Styling
    UIEdgeInsets margins_;
    CGFloat lineHeight_;
    BOOL horizontalRulesEnabled_;
    UIColor *horizontalRuleColor_;
    CGFloat horizontalRuleOffset_;
    BOOL verticalMarginEnabled_;
    UIColor *verticalMarginColor_;
    CGFloat verticalMarginInset_;
    
    // Input
    NSDictionary *inputTextAttributes_;
    
    // Subview Tiling
    NSMutableSet *visibleSections_;
    NSMutableSet *reusableSections_;
    
    // View Management
    NSMutableSet *underlayViews_;
    NSMutableSet *overlayViews;
    NKTSelectionDisplayController *selectionDisplayController_;
    NKTLoupe *bandLoupe_;
    NKTLoupe *roundLoupe_;
    
    // Selections
    UITextStorageDirection selectionAffinity_;
    NKTTextRange *interimSelectedTextRange_;
    NKTTextRange *selectedTextRange_;
    NKTTextRange *markedTextRange_;
    NSDictionary *markedTextStyle_;
    NSString *markedText_;

    // Input delegate provided by UITextInput
    id <UITextInputDelegate> inputDelegate_;
    
    // Tokenization
    NKTTextViewTokenizer *tokenizer_;
    
    // TODO: pull out into own policy delegate
    // Gesture recognizers
    NKTTextViewGestureRecognizerDelegate *gestureRecognizerDelegate_;
    UITapGestureRecognizer *nonEditTapGestureRecognizer_;
    UITapGestureRecognizer *tapGestureRecognizer_;
    UILongPressGestureRecognizer *longPressGestureRecognizer_;
    NKTDragGestureRecognizer *doubleTapAndDragGestureRecognizer_;
    NKTTextPosition *doubleTapStartTextPosition_;
}

#pragma mark Accessing the Text

@property (nonatomic, retain) NSMutableAttributedString *text;

#pragma mark Configuring Text Layout and Style

@property (nonatomic, readwrite) UIEdgeInsets margins;
@property (nonatomic, readwrite) CGFloat lineHeight;

@property (nonatomic, getter = areHorizontalRulesEnabled) BOOL horizontalRulesEnabled;
@property (nonatomic, retain) UIColor *horizontalRuleColor;
@property (nonatomic) CGFloat horizontalRuleOffset;
@property (nonatomic, getter = isVerticalMarginEnabled) BOOL verticalMarginEnabled;
@property (nonatomic, retain) UIColor *verticalMarginColor;
@property (nonatomic) CGFloat verticalMarginInset;

#pragma mark Styling Text Ranges

- (void)styleTextRange:(UITextRange *)textRange withTarget:(id)target selector:(SEL)selector;

#pragma mark Managing Text Attributes

@property (nonatomic, copy) NSDictionary *inputTextAttributes;

#pragma mark Accessing Gesture Recognizers

@property (nonatomic, readonly) UITapGestureRecognizer *nonEditTapGestureRecognizer;
@property (nonatomic, readonly) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, readonly) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, readonly) NKTDragGestureRecognizer *doubleTapAndDragGestureRecognizer;

#pragma mark Tokenizing

- (NKTTextRange *)textRangeForLineContainingTextPosition:(UITextPosition *)textPosition;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------
// NKTTextViewDelegate
//--------------------------------------------------------------------------------------------------

@protocol NKTTextViewDelegate <UIScrollViewDelegate>

@optional

#pragma mark Getting Text Attributes

- (NSDictionary *)defaultTextAttributes;

#pragma mark Responding to Editing Notifications

- (void)textViewDidBeginEditing:(NKTTextView *)textView;
- (void)textViewDidEndEditing:(NKTTextView *)textView;

#pragma mark Responding to Text Changes

- (void)textViewDidChange:(NKTTextView *)textView;

#pragma mark Responding to Selection Changes

- (void)textViewDidChangeSelection:(NKTTextView *)textView;

#pragma mark Managing Loupes

- (UIColor *)loupeFillColor;
- (UIView *)addLoupe:(UIView *)view;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------

@interface NKTTextView(PropertyRedeclarations)

@property (nonatomic, assign) id <NKTTextViewDelegate> delegate;

//@property (nonatomic, readwrite, copy) NKTTextRange *selectedTextRange;
//@property (nonatomic, readonly, copy) NKTTextRange *markedTextRange;

@end
