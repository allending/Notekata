//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTSelectionDisplayController.h"
#import "NKTCaret.h"
#import "NKTHandle.h"
#import "NKTHighlightRegion.h"
#import "NKTSelectedTextRegion.h"
#import "NKTTextRange.h"

@interface NKTSelectionDisplayController()

#pragma mark Managing Selection Elements

@property (nonatomic, readonly) NKTCaret *caret;
@property (nonatomic, readonly) NKTSelectedTextRegion *selectedTextRegion;
@property (nonatomic, readonly) NKTHighlightRegion *markedTextRegion;

#pragma mark Updating Selection Elements

- (void)updateCaret;
- (void)updateSelectedTextRegion;
- (void)updateMarkedTextRegion;

@end

#pragma mark -

@implementation NKTSelectionDisplayController

@synthesize delegate = delegate_;
@synthesize caretVisible = caretVisible_;
@synthesize selectedTextRegionVisible = selectedTextRegionVisible_;
@synthesize markedTextRegionVisible = markedTextRegionVisible_;

#pragma mark -
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

#pragma mark -
#pragma mark Setting the Delegate

- (void)setDelegate:(id <NKTSelectionDisplayControllerDelegate>)delegate
{
    delegate_ = delegate;
    [self updateSelectionDisplay];
}

#pragma mark -
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

- (NKTSelectedTextRegion *)selectedTextRegion
{
    if (selectedTextRegion_ == nil)
    {
        selectedTextRegion_ = [[NKTSelectedTextRegion alloc] init];
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

- (NKTHandle *)backwardHandle
{
    if (backwardHandle_ == nil)
    {
        backwardHandle_ = [[NKTHandle alloc] initWithStyle:NKTHandleStyleTopTip];
        backwardHandle_.hidden = !selectedTextRegionVisible_;
        [delegate_ addOverlayView:backwardHandle_];
    }
    
    return backwardHandle_;
}

- (NKTHandle *)forwardHandle
{
    if (forwardHandle_ == nil)
    {
        forwardHandle_ = [[NKTHandle alloc] initWithStyle:NKTHandleStyleBottomTip];
        forwardHandle_.hidden = !selectedTextRegionVisible_;
        [delegate_ addOverlayView:forwardHandle_];
    }
    
    return forwardHandle_;
}

#pragma mark -
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

#pragma mark -
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
        CGRect caretRect = [delegate_ caretRectForTextPosition:gestureTextRange.start applyInputTextAttributes:NO];
        self.caret.frame = caretRect;
        self.caret.blinkingEnabled = NO;
        self.caret.hidden = NO;
    }
    else if (caretVisible_ && gestureTextRange == nil && selectedTextRange != nil && selectedTextRange.empty)
    {
        CGRect caretRect = [delegate_ caretRectForTextPosition:selectedTextRange.start applyInputTextAttributes:YES];
        self.caret.frame = caretRect;
        self.caret.blinkingEnabled = YES;
        [self.caret restartBlinking];
        self.caret.hidden = NO;
    }
    else
    {
        self.caret.hidden = YES;
    }
}

static const CGFloat HandleRectWidth = 2.0;

- (void)updateSelectedTextRegion
{    
    if (selectedTextRegionVisible_)
    {
        NKTTextRange *gestureTextRange = delegate_.gestureTextRange;
        NKTTextRange *selectedTextRange = delegate_.selectedTextRange;
        NKTTextRange *targetTextRange = gestureTextRange != nil ? gestureTextRange : selectedTextRange;
        
        if (targetTextRange != nil && !targetTextRange.empty)
        {
            // TODO: make sure delegate must return valid rects
            CGRect firstRect = [delegate_ firstRectForTextRange:targetTextRange];
            CGRect lastRect = [delegate_ lastRectForTextRange:targetTextRange];
            
            self.selectedTextRegion.firstRect = firstRect;
            self.selectedTextRegion.lastRect = lastRect;
            self.selectedTextRegion.hidden = NO;
            
            CGRect backwardHandleRect = firstRect;
            backwardHandleRect.origin.x -= HandleRectWidth;
            backwardHandleRect.size.width = HandleRectWidth;
            self.backwardHandle.frame = backwardHandleRect;
            self.backwardHandle.hidden = NO;
            
            CGRect forwardHandleRect = lastRect;
            forwardHandleRect.origin.x = CGRectGetMaxX(forwardHandleRect);
            forwardHandleRect.size.width = HandleRectWidth;
            self.forwardHandle.frame = forwardHandleRect;
            self.forwardHandle.hidden = NO;
            return;
        }
    }
    
    self.selectedTextRegion.hidden = YES;
    self.backwardHandle.hidden = YES;
    self.forwardHandle.hidden = YES;
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
