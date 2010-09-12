//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTSelectionDisplayController.h"
#import "NKTCaret.h"
#import "NKTHighlightRegion.h"

@interface NKTSelectionDisplayController()

#pragma mark Managing Selection Elements

@property (nonatomic, readonly) NKTCaret *caret;
@property (nonatomic, readonly) NKTHighlightRegion *selectedTextRegion;
@property (nonatomic, readonly) NKTHighlightRegion *markedTextRegion;

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
    [self updateCaret];
    [self updateSelectedTextRegion];
    [self updateMarkedTextRegion];
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

- (void)updateCaret
{
    UITextRange *textRange = [delegate_ provisionalTextRange];
    BOOL provisional = YES;
    
    if (textRange == nil)
    {
        provisional = NO;
        textRange = [delegate_ selectedTextRange];
    }
    
    if (textRange != nil && textRange.empty && caretVisible_)
    {
        self.caret.frame = [delegate_ caretRectForPosition:textRange.start];
        self.caret.hidden = NO;
        self.caret.blinkingEnabled = !provisional;
        [self.caret restartBlinking];
    }
    else
    {
        self.caret.hidden = YES;
    }
}

- (void)updateSelectedTextRegion
{
    UITextRange *textRange = [delegate_ provisionalTextRange];
    
    if (textRange == nil)
    {
        textRange = [delegate_ selectedTextRange];
    }
    
    if (textRange != nil && !textRange.empty && selectedTextRegionVisible_)
    {
        self.selectedTextRegion.rects = [delegate_ rectsForTextRange:textRange];
        self.selectedTextRegion.hidden = NO;
    }
    else
    {
        self.selectedTextRegion.hidden = YES;
    }
}

- (void)updateMarkedTextRegion
{
    UITextRange *markedTextRange = [delegate_ markedTextRange];
    
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
    selectedTextRegionVisible_ = selectedTextRegionVisible;
    [self updateSelectedTextRegion];
}

- (void)setMarkedTextRegionVisible:(BOOL)markedTextRegionVisible
{
    markedTextRegionVisible_ = markedTextRegionVisible;
    [self updateMarkedTextRegion];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Informing the Controller of Selection Changes

- (void)selectedTextRangeDidChange
{
    [self updateCaret];
    [self updateSelectedTextRegion];
}

- (void)markedTextRangeDidChange
{
    [self updateMarkedTextRegion];
}

- (void)provisionalTextRangeDidChange
{
    [self updateCaret];
    [self updateSelectedTextRegion];
}


@end
