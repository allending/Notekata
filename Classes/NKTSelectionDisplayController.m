//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTSelectionDisplayController.h"
#import "NKTCaret.h"

@interface NKTSelectionDisplayController()

#pragma mark Managing Selection Element Views

@property (nonatomic, readonly) NKTCaret *caret;
@property (nonatomic, readonly) UIView *selectionBandTop;
@property (nonatomic, readonly) UIView *selectionBandMiddle;
@property (nonatomic, readonly) UIView *selectionBandBottom;

- (void)showSelectionCaret;
- (void)hideSelectionCaret;

- (void)showSelectionBand;
- (void)hideSelectionBand;

- (void)updateDisplay;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------

@implementation NKTSelectionDisplayController

@synthesize delegate = delegate_;
@synthesize caretVisible = caretVisible_;
@synthesize selectionBandVisible = selectionBandVisible_;

#pragma mark Initializing

- (id)init
{
    if ((self = [super init]))
    {
        caretVisible_ = YES;
        selectionBandVisible_ = YES;
    }
    
    return self;
}

- (void)dealloc
{
    [caret_ release];
    [selectionBandTop_ release];
    [selectionBandMiddle_ release];
    [selectionBandBottom_ release];
    [super dealloc];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Setting the Delegate

- (void)setDelegate:(id <NKTSelectionDisplayControllerDelegate>)delegate
{
    delegate_ = delegate;
    [self updateDisplay];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Managing Selection Element Views

- (NKTCaret *)caret
{
    if (caret_ == nil)
    {
        caret_ = [[NKTCaret alloc] init];
        caret_.hidden = !caretVisible_;
        [delegate_.selectionElementsView addSubview:caret_];
    }
    
    return caret_;
}

- (UIView *)createSelectionBandRegion
{
    UIView *selectionBandRegion = [[[UIView alloc] init] autorelease];
    selectionBandRegion.backgroundColor = [UIColor colorWithRed:0.25 green:0.45 blue:0.9 alpha:0.3];
    selectionBandRegion.userInteractionEnabled = NO;
    selectionBandRegion.hidden = !selectionBandVisible_;
    [delegate_.selectionElementsView addSubview:selectionBandRegion];
    return selectionBandRegion;
}

- (UIView *)selectionBandTop
{
    if (selectionBandTop_ == nil)
    {
        selectionBandTop_ = [[self createSelectionBandRegion] retain];
    }
    
    return selectionBandTop_;
}

- (UIView *)selectionBandMiddle
{
    if (selectionBandMiddle_ == nil)
    {
        selectionBandMiddle_ = [[self createSelectionBandRegion] retain];
    }
    
    return selectionBandMiddle_;
}

- (UIView *)selectionBandBottom
{
    if (selectionBandBottom_ == nil)
    {
        selectionBandBottom_ = [[self createSelectionBandRegion] retain];
    }
    
    return selectionBandBottom_;
}

- (void)showSelectionCaret
{
    UITextRange *selectedTextRange = [delegate_ selectedTextRange];
    self.caret.frame = [self caretRectForPosition:selectedTextRange.start];
    self.caret.hidden = NO;
    [self.caret restartBlinking];
}

- (void)hideSelectionCaret
{
    self.caret.hidden = YES;
}

- (void)showSelectionBand
{
    UITextRange *selectedTextRange = [delegate_ selectedTextRange];
    NSArray *rects = [delegate_ orderedRectsForTextRange:selectedTextRange];
    
    if ([rects count] == 0)
    {
        self.selectionBandTop.hidden = YES;
        self.selectionBandMiddle.hidden = YES;
        self.selectionBandBottom.hidden = YES;
        return;
    }
    else if ([rects count] == 1)
    {
        self.selectionBandTop.frame = [[rects objectAtIndex:0] CGRectValue];
        self.selectionBandTop.hidden = NO;
        self.selectionBandMiddle.hidden = YES;
        self.selectionBandBottom.hidden = YES;
    }
    else
    {
        CGRect topRect = [[rects objectAtIndex:0] CGRectValue];
        self.selectionBandTop.frame = topRect;
        self.selectionBandTop.hidden = NO;
        
        CGRect bottomRect = [[rects objectAtIndex:[rects count] - 1] CGRectValue];
        self.selectionBandBottom.frame = bottomRect;
        self.selectionBandBottom.hidden = NO;
        
        CGRect middleRect = CGRectMake(CGRectGetMinX(bottomRect),
                                       CGRectGetMaxY(topRect),
                                       CGRectGetMaxX(topRect) - CGRectGetMinX(bottomRect),
                                       CGRectGetMinY(bottomRect) - CGRectGetMaxY(topRect));
        
        // First and last lines overlap, don't need to draw middle band
        if (middleRect.size.height <= 0.0)
        {
            self.selectionBandMiddle.hidden = YES;
        }
        else
        {
            self.selectionBandMiddle.frame = middleRect;
            self.selectionBandMiddle.hidden = NO;
        }
    }
}

- (void)hideSelectionBand
{
    self.selectionBandTop.hidden = YES;
    self.selectionBandMiddle.hidden = YES;
    self.selectionBandBottom.hidden = YES;
}

- (void)updateDisplay
{
    UITextRange *selectedTextRange = [delegate_ selectedTextRange];
    
    if (selectedTextRange != nil && selectedTextRange.empty && caretVisible_)
    {
        [self showSelectionCaret];
        [self hideSelectionBand];
    }
    else if (selectedTextRange != nil && selectionBandVisible_)
    {
        [self hideSelectionCaret];
        [self showSelectionBand];
    }
    else
    {
        [self hideSelectionCaret];
        [self hideSelectionBand];
    }
}

//--------------------------------------------------------------------------------------------------

#pragma mark Controlling Selection Element Display

- (void)setCaretVisible:(BOOL)selectionElementsVisibleFlag
{
    caretVisible_ = selectionElementsVisibleFlag;
    [self updateDisplay];
}

- (BOOL)isCaretBlinkingEnabled
{
    return self.caret.isBlinkingEnabled;
}

- (void)setCaretBlinkingEnabled:(BOOL)caretBlinkingEnabled
{
    caret_.blinkingEnabled = caretBlinkingEnabled;
}

- (void)setSelectionBandVisible:(BOOL)selectionBandVisible
{
    selectionBandVisible_ = selectionBandVisible;
    [self updateDisplay];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Informing the Controller of Selection Changes

- (void)selectedTextRangeDidChange
{
    [self updateDisplay];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Selection Element Geometry

- (CGRect)caretRectForPosition:(UITextPosition *)textPosition
{
    CGPoint charOrigin = [delegate_ characterOriginForPosition:textPosition];
    NSDictionary *textStyling = [delegate_ textStylingAtPosition:textPosition inDirection:UITextStorageDirectionForward];
    UIFont *charFont = [textStyling objectForKey:UITextInputTextFontKey];
    
    const CGFloat caretWidth = 2.0;
    const CGFloat caretVerticalPadding = 1.0;
    
    CGRect caretFrame = CGRectZero;
    caretFrame.origin.x = charOrigin.x;
    caretFrame.origin.y = charOrigin.y - charFont.ascender - caretVerticalPadding;
    caretFrame.size.width = caretWidth;
    caretFrame.size.height = charFont.ascender + (-charFont.descender) + (caretVerticalPadding * 2.0);
    return caretFrame;
}

@end
