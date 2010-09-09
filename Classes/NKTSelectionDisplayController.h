//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaCore.h"

@class NKTCaret;
@class NKTHighlightRegion;

@protocol NKTSelectionDisplayControllerDelegate;

//--------------------------------------------------------------------------------------------------
// NKTSelectionDisplayController manages the display and update of textual selection elements such
// as highlighted selection ranges in a view.
//--------------------------------------------------------------------------------------------------

@interface NKTSelectionDisplayController : NSObject
{
@private
    id <NKTSelectionDisplayControllerDelegate> delegate_;

    BOOL caretVisible_;
    BOOL selectedTextRegionVisible_;
    BOOL markedTextRegionVisible_;
    
    NKTCaret *caret_;
    NKTHighlightRegion *selectedTextRegion_;
    NKTHighlightRegion *markedTextRegion_;
}

#pragma mark Setting the Delegate

@property (nonatomic, readwrite, assign) id <NKTSelectionDisplayControllerDelegate> delegate;

#pragma mark Controlling Selection Element Display

@property (nonatomic, getter = isCaretVisible) BOOL caretVisible;
@property (nonatomic, getter = isCaretBlinkingEnabled) BOOL caretBlinkingEnabled;
@property (nonatomic, getter = isSelectedTextRegionVisible) BOOL selectedTextRegionVisible;
@property (nonatomic, getter = isMarkedTextRegionVisible) BOOL markedTextRegionVisible;

#pragma mark Informing the Controller of Selection Changes

- (void)selectedTextRangeDidChange;
- (void)markedTextRangeDidChange;

#pragma mark Getting Selection Geometry

- (CGRect)caretRectForPosition:(UITextPosition *)textPosition;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------
// NKTSelectionDisplayControllerDelegate
//--------------------------------------------------------------------------------------------------

@protocol NKTSelectionDisplayControllerDelegate

#pragma mark Working with Marked and Selected Text

- (UITextRange *)selectedTextRange;
- (UITextRange *)markedTextRange;

#pragma mark Geometry and Hit-Testing Methods

- (NSArray *)rectsForTextRange:(UITextRange *)textRange;
- (CGPoint)characterOriginForPosition:(UITextPosition *)textPosition;

#pragma mark Returning Text Styling Information

- (NSDictionary *)textStylingAtPosition:(UITextPosition *)position inDirection:(UITextStorageDirection)direction;

#pragma mark Managing Selection Views

- (void)addOverlayView:(UIView *)view;
- (void)addUnderlayView:(UIView *)view;

@end
