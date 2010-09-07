//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaCore.h"

@class NKTCaret;

@protocol NKTSelectionDisplayControllerDelegate;

//--------------------------------------------------------------------------------------------------
// NKTSelectionDisplayController manages the display and update of textual selection elements such
// as highlighted selection ranges in a view.
//--------------------------------------------------------------------------------------------------

@interface NKTSelectionDisplayController : NSObject
{
@private
    id <NKTSelectionDisplayControllerDelegate> delegate_;

    NKTCaret *caret_;
    BOOL caretVisible_;
    
    UIView *selectionBandTop_;
    UIView *selectionBandMiddle_;
    UIView *selectionBandBottom_;
    BOOL selectionBandVisible_;
}

#pragma mark Setting the Delegate

@property (nonatomic, readwrite, assign) id <NKTSelectionDisplayControllerDelegate> delegate;

#pragma mark Controlling Selection Element Display

@property (nonatomic, readwrite, getter = isCaretVisible) BOOL caretVisible;
@property (nonatomic, readwrite, getter = isCaretBlinkingEnabled) BOOL caretBlinkingEnabled;

@property (nonatomic, readwrite, getter = isSelectionBandVisible) BOOL selectionBandVisible;

#pragma mark Informing the Controller of Selection Changes

- (void)selectedTextRangeDidChange;

#pragma mark Getting Selection Element Geometry

- (CGRect)caretRectForPosition:(UITextPosition *)textPosition;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------
// NKTSelectionDisplayControllerDelegate defines the protocol used by NKTSelectionDisplayController
// to obtain information needed to correctly display selections in view with text. It shares
// some methods with the UITextInput protocol but does not conform to it because the protocol does
// not require clients to handle any sort of text input.
//--------------------------------------------------------------------------------------------------

@protocol NKTSelectionDisplayControllerDelegate

#pragma mark Working with Marked and Selected Text

- (UITextRange *)selectedTextRange;

#pragma mark Geometry and Hit-Testing Methods

- (NSArray *)rectsForTextRange:(UITextRange *)textRange;
- (CGPoint)characterOriginForPosition:(UITextPosition *)textPosition;

#pragma mark Returning Text Styling Information

- (NSDictionary *)textStylingAtPosition:(UITextPosition *)position inDirection:(UITextStorageDirection)direction;

#pragma mark Returning the View For Selection Elements

- (UIView *)selectionElementsView;

@end
