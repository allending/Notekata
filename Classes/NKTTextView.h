//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KobaUI.h"
#import "NKTSelectionDisplayController.h"
#import "NKTTextPosition.h"
#import "NKTTextRange.h"

@class NKTFramesetter;
@class NKTDragGestureRecognizer;
@class NKTLoupe;
@class NKTTextViewGestureRecognizerDelegate;
@class NKTTextViewTokenizer;

// NKTTextView implements the behavior for a view with support for text and page styling.
@interface NKTTextView : UIScrollView <UITextInput, UIGestureRecognizerDelegate, NKTSelectionDisplayControllerDelegate>
{
@private
    // Text Storage
    NSMutableAttributedString *text_;
    
    // Background
    UIView *backgroundView_;
    
    // Styling
    UIEdgeInsets margins_;
    CGFloat lineHeight_;
    BOOL horizontalRulesEnabled_;
    UIColor *horizontalRuleColor_;
    CGFloat horizontalRuleOffset_;
    BOOL verticalMarginEnabled_;
    UIColor *verticalMarginColor_;
    CGFloat verticalMarginInset_;
    
    // Framesetting
    NKTFramesetter *framesetter_;
    
    // Tiling
    NSMutableSet *visibleSections_;
    NSMutableSet *reusableSections_;
    
    // Selection Display
    NSMutableSet *underlayViews_;
    NSMutableSet *overlayViews;
    NKTSelectionDisplayController *selectionDisplayController_;
    NKTLoupe *textRangeLoupe_;
    NKTLoupe *caretLoupe_;
    
    // Text Ranges
    NKTTextRange *gestureTextRange_;
    NKTTextRange *selectedTextRange_;
    NKTTextRange *markedTextRange_;
    NSDictionary *markedTextStyle_;
    NSString *markedText_;
    
    // Input Attributes
    NSDictionary *inputTextAttributes_;
    
    // Input Delegate
    id <UITextInputDelegate> inputDelegate_;
    
    // Tokenization
    NKTTextViewTokenizer *tokenizer_;
    
    // Gesture Recognizers
    NKTTextViewGestureRecognizerDelegate *gestureRecognizerDelegate_;
    UITapGestureRecognizer *nonEditTapGestureRecognizer_;
    UITapGestureRecognizer *tapGestureRecognizer_;
    UILongPressGestureRecognizer *longPressGestureRecognizer_;
    NKTDragGestureRecognizer *doubleTapDragGestureRecognizer_;
    NKTTextRange *initialDoubleTapTextRange_;
    NKTDragGestureRecognizer *backwardHandleGestureRecognizer_;
    NKTDragGestureRecognizer *forwardHandleGestureRecognizer_;
}

#pragma mark Memory

- (void)purgeCachedResources;

#pragma mark Accessing the Text

@property (nonatomic, copy) NSAttributedString *text;

#pragma mark Styling Text

@property (nonatomic, copy) NSDictionary *inputTextAttributes;

- (void)styleTextRange:(UITextRange *)textRange withTarget:(id)target selector:(SEL)selector;

#pragma mark Configuring the Background

@property (nonatomic, retain) UIView *backgroundView;

#pragma mark Configuring Text Layout and Style

@property (nonatomic) UIEdgeInsets margins;
@property (nonatomic) CGFloat lineHeight;
@property (nonatomic, getter = areHorizontalRulesEnabled) BOOL horizontalRulesEnabled;
@property (nonatomic, retain) UIColor *horizontalRuleColor;
@property (nonatomic) CGFloat horizontalRuleOffset;
@property (nonatomic, getter = isVerticalMarginEnabled) BOOL verticalMarginEnabled;
@property (nonatomic, retain) UIColor *verticalMarginColor;
@property (nonatomic) CGFloat verticalMarginInset;

#pragma mark Scrolling

- (void)scrollTextRangeToVisible:(UITextRange *)textRange animated:(BOOL)animated;

#pragma mark Accessing Gesture Recognizers

@property (nonatomic, readonly) UITapGestureRecognizer *nonEditTapGestureRecognizer;
@property (nonatomic, readonly) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, readonly) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, readonly) NKTDragGestureRecognizer *doubleTapDragGestureRecognizer;

#pragma mark Selection

- (void)updateSelectionDisplay;
- (NKTTextRange *)guessedTextRangeAtTextPosition:(NKTTextPosition *)textPosition wordRange:(NKTTextRange **)wordRange;
- (void)setSelectedTextRange:(NKTTextRange *)textRange notifyInputDelegate:(BOOL)notifyInputDelegate;
- (void)replaceRange:(NKTTextRange *)textRange withText:(NSString *)replacementText notifyInputDelegate:(BOOL)notifyInputDelegate;
- (void)replaceRange:(NKTTextRange *)textRange withAttributedString:(NSAttributedString *)attributedString notifyInputDelegate:(BOOL)notifyInputDelegate;
- (NSDictionary *)inheritedAttributesForTextRange:(NKTTextRange *)textRange;
- (NKTTextRange *)selectedTextRangeAfterReplacingRange:(NKTTextRange *)textRange withText:(NSString *)replacementText;

#pragma mark Tokenizing

- (NKTTextRange *)textRangeForLineContainingTextPosition:(UITextPosition *)textPosition;

#pragma mark Editing

@property (nonatomic, readonly, getter = isEditing) BOOL editing;

@end

#pragma mark -

// NKTTextViewDelegate declares methods that allow clients to respond to messages from NKTTextView.
@protocol NKTTextViewDelegate <UIScrollViewDelegate>

@optional

#pragma mark Managing Loupes

- (UIColor *)loupeFillColor;
- (UIView *)addLoupe:(UIView *)view;

#pragma mark Getting Text Attributes

- (NSDictionary *)defaultCoreTextAttributes;

#pragma mark Responding to Editing Notifications

- (void)textViewDidBeginEditing:(NKTTextView *)textView;
- (void)textViewDidEndEditing:(NKTTextView *)textView;
- (void)textView:(NKTTextView *)textView didChangeFromTextPosition:(NKTTextPosition *)textPosition;
- (void)textViewDidChangeSelection:(NKTTextView *)textView;

#pragma mark Gestures

- (void)textViewDidRecognizeTap:(NKTTextView *)textView previousSelectedTextRange:(NKTTextRange *)previousSelectedTextRange;
- (void)textViewLongPressDidBegin:(NKTTextView *)textView;
- (void)textViewLongPressDidEnd:(NKTTextView *)textView;
- (void)textViewDoubleTapDragDidBegin:(NKTTextView *)textView;
- (void)textViewDoubleTapDragDidEnd:(NKTTextView *)textView;
- (void)textViewDragBackwardDidBegin:(NKTTextView *)textView;
- (void)textViewDragBackwardDidEnd:(NKTTextView *)textView;
- (void)textViewDragForwardDidBegin:(NKTTextView *)textView;
- (void)textViewDragForwardDidEnd:(NKTTextView *)textView;

@end
