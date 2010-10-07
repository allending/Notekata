//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaUI.h"

@class NKTCaret;
@class NKTHighlightRegion;
@class NKTLine;
@class NKTTextPosition;
@class NKTTextRange;

@protocol NKTSelectionDisplayControllerDelegate;

// NKTSelectionDisplayController manages the display of text selection elements within a view. It
// supports input carets, selected text ranges, marked text ranges, and provisional text ranges.
// The receiver's delegate provides the controller information about text ranges and text range
// geometry.
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

#pragma mark Configuring Selection Elements

@property (nonatomic, getter = isCaretVisible) BOOL caretVisible;
@property (nonatomic, getter = isSelectedTextRegionVisible) BOOL selectedTextRegionVisible;
@property (nonatomic, getter = isMarkedTextRegionVisible) BOOL markedTextRegionVisible;

#pragma mark Updating Selection Elements

// Updates the selection elements. This should be called whenever the layout of the text or any
// relevant text ranges change.
- (void)updateSelectionDisplay;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------

// NKTSelectionDisplayControllerDelegate
@protocol NKTSelectionDisplayControllerDelegate

#pragma mark Getting Text Ranges

@property (nonatomic, readonly) NKTTextRange *gestureTextRange;
@property (nonatomic, readonly) NKTTextRange *selectedTextRange;
@property (nonatomic, readonly) NKTTextRange *markedTextRange;

#pragma mark Geometry and Hit-Testing

- (CGRect)caretRectForTextPosition:(NKTTextPosition *)textPosition
          applyInputTextAttributes:(BOOL)applyTextInputAttributes;
- (NSArray *)rectsForTextRange:(UITextRange *)textRange;

#pragma mark Managing Selection Views

- (void)addOverlayView:(UIView *)view;
- (void)addUnderlayView:(UIView *)view;

@end
