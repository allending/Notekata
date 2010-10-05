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
    [self updateSelectionElements];
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

- (void)updateSelectionElements
{
    [self updateCaret];
    [self updateSelectedTextRegion];
    [self updateMarkedTextRegion];
}

- (void)updateCaret
{
    if (!caretVisible_)
    {
        self.caret.hidden = YES;
        return;
    }
    
    NKTTextRange *interimSelectedTextRange = delegate_.interimSelectedTextRange;
    NKTTextRange *selectedTextRange = delegate_.selectedTextRange;
    
    if (interimSelectedTextRange != nil && interimSelectedTextRange.empty)
    {
        self.caret.frame = [delegate_ caretRectForTextPosition:interimSelectedTextRange.start
                                      applyInputTextAttributes:YES];
        self.caret.blinkingEnabled = NO;
        self.caret.hidden = NO;
        return;
    }
    else if (selectedTextRange != nil && selectedTextRange.empty)
    {
        self.caret.frame = [delegate_ caretRectForTextPosition:selectedTextRange.start applyInputTextAttributes:NO];
        self.caret.blinkingEnabled = YES;
        [self.caret restartBlinking];
        self.caret.hidden = NO;
        return;
    }
}

- (void)updateSelectedTextRegion
{
    if (!selectedTextRegionVisible_)
    {
        self.selectedTextRegion.hidden = YES;
        return;
    }
    
    NKTTextRange *interimSelectedTextRange = delegate_.interimSelectedTextRange;
    NKTTextRange *selectedTextRange = delegate_.selectedTextRange;
    
    if (interimSelectedTextRange != nil && !interimSelectedTextRange.empty)
    {
        self.selectedTextRegion.rects = [delegate_ rectsForTextRange:interimSelectedTextRange];
        self.selectedTextRegion.hidden = NO;
    }
    else if (selectedTextRange != nil && !selectedTextRange.empty)
    {
        self.selectedTextRegion.rects = [delegate_ rectsForTextRange:selectedTextRange];
        self.selectedTextRegion.hidden = NO;
    }
}

- (void)updateMarkedTextRegion
{
    if (!markedTextRegionVisible_)
    {
        self.markedTextRegion.hidden = YES;
        return;
    }
    
    UITextRange *markedTextRange = delegate_.markedTextRange;
    
    if (markedTextRange != nil && !markedTextRange.empty)
    {
        self.markedTextRegion.rects = [delegate_ rectsForTextRange:markedTextRange];
        self.markedTextRegion.hidden = NO;
    }
}

@end
