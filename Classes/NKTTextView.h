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

#pragma mark Tokenizing

- (NKTTextRange *)textRangeForLineContainingTextPosition:(UITextPosition *)textPosition;

@end

#pragma mark -

// NKTTextViewDelegate declares methods that allow clients to respond to messages from NKTTextView.
@protocol NKTTextViewDelegate <UIScrollViewDelegate>

@optional

#pragma mark Getting Text Attributes

- (NSDictionary *)defaultCoreTextAttributes;

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
