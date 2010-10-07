//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTSelectionDisplayController.h"
#import "NKTCaret.h"
#import "NKTHighlightRegion.h"
#import "NKTTextRange.h"

@interface NKTSelectionDisplayController()

#pragma mark Managing Selection Elements

@property (nonatomic, readonly) NKTCaret *caret;
@property (nonatomic, readonly) NKTHighlightRegion *selectedTextRegion;
@property (nonatomic, readonly) NKTHighlightRegion *markedTextRegion;

#pragma mark Updating Selection Elements

- (void)updateCaret;
- (void)updateSelectedTextRegion;
- (void)updateMarkedTextRegion;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------

@implementation NKTSelectionDisplayController

@synthesize delegate = delegate_;
@synthesize caretVisible = caretVisible_;
@synthesize selectedTextRegionVisible = selectedTextRegionVisible_;
@synthesize markedTextRegionVisible = markedTextRegionVisible_;

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (id)init
{
    if ((self = [super init]))
    {
        caretVisible_ = YES;
        selectedTextRegionVisible_ = YES;
        markedTextRegionVisible_ = YES;
    }
    
    return self;
}

- (void)dealloc
{
    [caret_ release];
    [selectedTextRegion_ release];
    [markedTextRegion_ release];
    [super dealloc];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Setting the Delegate

- (void)setDelegate:(id <NKTSelectionDisplayControllerDelegate>)delegate
{
    delegate_ = delegate;
    [self updateSelectionDisplay];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Managing Selection Element Views

- (NKTCaret *)caret
{
    if (caret_ == nil)
    {
        caret_ = [[NKTCaret alloc] init];
        caret_.hidden = !caretVisible_;
        [delegate_ addOverlayView:caret_];
    }
    
    return caret_;
}

- (NKTHighlightRegion *)selectedTextRegion
{
    if (selectedTextRegion_ == nil)
    {
        selectedTextRegion_ = [[NKTHighlightRegion alloc] init];
        selectedTextRegion_.coalescesRects = YES;
        selectedTextRegion_.strokesRects = NO;
        selectedTextRegion_.fillColor = [UIColor colorWithRed:0.25 green:0.45 blue:0.9 alpha:0.3];
        selectedTextRegion_.hidden = !selectedTextRegionVisible_;
        [delegate_ addOverlayView:selectedTextRegion_];
    }
    
    return selectedTextRegion_;
}

- (NKTHighlightRegion *)markedTextRegion
{
    if (markedTextRegion_ == nil)
    {
        markedTextRegion_ = [[NKTHighlightRegion alloc] init];
        markedTextRegion_.hidden = !markedTextRegionVisible_;
        [delegate_ addUnderlayView:markedTextRegion_];
    }
    
    return markedTextRegion_;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Controlling Selection Element Display

- (void)setCaretVisible:(BOOL)caretVisible
{
    if (caretVisible_ == caretVisible)
    {
        return;
    }
    
    caretVisible_ = caretVisible;
    [self updateCaret];
}

- (void)setSelectedTextRegionVisible:(BOOL)selectedTextRegionVisible
{
    if (selectedTextRegionVisible_ == selectedTextRegionVisible)
    {
        return;
    }
    
    selectedTextRegionVisible_ = selectedTextRegionVisible;
    [self updateSelectedTextRegion];
}

- (void)setMarkedTextRegionVisible:(BOOL)markedTextRegionVisible
{    
    if (markedTextRegionVisible_ == markedTextRegionVisible)
    {
        return;
    }
    
    markedTextRegionVisible_ = markedTextRegionVisible;
    [self updateMarkedTextRegion];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Updating Selection Elements

- (void)updateSelectionDisplay
{
    [self updateCaret];
    [self updateSelectedTextRegion];
    [self updateMarkedTextRegion];
}

- (void)updateCaret
{    
    NKTTextRange *gestureTextRange = delegate_.gestureTextRange;
    NKTTextRange *selectedTextRange = delegate_.selectedTextRange;
    
    if (caretVisible_ && gestureTextRange != nil && gestureTextRange.empty)
    {
        self.caret.frame = [delegate_ caretRectForTextPosition:gestureTextRange.start
                                      applyInputTextAttributes:YES];
        self.caret.blinkingEnabled = NO;
        self.caret.hidden = NO;
    }
    else if (caretVisible_ && gestureTextRange == nil && selectedTextRange != nil && selectedTextRange.empty)
    {
        self.caret.frame = [delegate_ caretRectForTextPosition:selectedTextRange.start applyInputTextAttributes:NO];
        self.caret.blinkingEnabled = YES;
        [self.caret restartBlinking];
        self.caret.hidden = NO;
    }
    else
    {
        self.caret.hidden = YES;
    }
}

- (void)updateSelectedTextRegion
{
    NKTTextRange *gestureTextRange = delegate_.gestureTextRange;
    NKTTextRange *selectedTextRange = delegate_.selectedTextRange;
    
    if (selectedTextRegionVisible_ && gestureTextRange != nil && !gestureTextRange.empty)
    {
        self.selectedTextRegion.rects = [delegate_ rectsForTextRange:gestureTextRange];
        self.selectedTextRegion.hidden = NO;
    }
    else if (selectedTextRegionVisible_ && gestureTextRange == nil && selectedTextRange != nil && !selectedTextRange.empty)
    {
        self.selectedTextRegion.rects = [delegate_ rectsForTextRange:selectedTextRange];
        self.selectedTextRegion.hidden = NO;
    }
    else
    {
        self.selectedTextRegion.hidden = YES;
    }
}

- (void)updateMarkedTextRegion
{
    UITextRange *markedTextRange = delegate_.markedTextRange;
    
    if (markedTextRange != nil && !markedTextRange.empty)
    {
        self.markedTextRegion.rects = [delegate_ rectsForTextRange:markedTextRange];
        self.markedTextRegion.hidden = NO;
    }
    else
    {
        self.markedTextRegion.hidden = YES;
    }
}

@end
