//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaUI.h"

@class NKTCaret;
@class NKTHighlightRegion;

@protocol NKTSelectionDisplayControllerDelegate;

//--------------------------------------------------------------------------------------------------
// NKTSelectionDisplayController manages the display of text selection elements within a view. It
// supports input carets, selected text ranges, marked text ranges, and provisional text ranges.
// The receiver's delegate provides the controller information about text ranges and text range
// geometry.
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

#pragma mark Configuring Selection Elements

@property (nonatomic, getter = isCaretVisible) BOOL caretVisible;
@property (nonatomic, getter = isSelectedTextRegionVisible) BOOL selectedTextRegionVisible;
@property (nonatomic, getter = isMarkedTextRegionVisible) BOOL markedTextRegionVisible;

#pragma mark Updating Selection Elements

- (void)updateSelectionElements;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------
// NKTSelectionDisplayControllerDelegate
//--------------------------------------------------------------------------------------------------

@protocol NKTSelectionDisplayControllerDelegate

#pragma mark Working with Marked and Selected Text

- (UITextRange *)selectedTextRange;
- (UITextRange *)markedTextRange;
- (UITextRange *)provisionalTextRange;

#pragma mark Geometry and Hit-Testing

- (CGRect)inputCaretRect;
- (CGRect)caretRectForPosition:(UITextPosition *)textPosition;
- (NSArray *)rectsForTextRange:(UITextRange *)textRange;

#pragma mark Managing Selection Views

- (void)addOverlayView:(UIView *)view;
- (void)addUnderlayView:(UIView *)view;

@end
