//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTTextView.h"
#import <CoreText/CoreText.h>
#import "KBCGeometry.h"
#import "NKTCaret.h"
#import "NKTDragGestureRecognizer.h"
#import "NKTFont.h"
#import "NKTGestureRecognizerUtilites.h"
#import "NKTLine.h"
#import "NKTLoupe.h"
#import "NKTTextPosition.h"
#import "NKTTextRange.h"
#import "NKTTextSection.h"
#import "NKTTextViewGestureRecognizerDelegate.h"

struct NKTTextHitResult
{
    NKTTextPosition *textPosition;
    NKTLine *line;
};

typedef struct NKTTextHitResult NKTTextHitResult;

#pragma mark -

//--------------------------------------------------------------------------------------------------

@interface NKTTextView()

#pragma mark Initializing

- (void)requiredInit_NKTTextView;
- (void)createSelectionViews;
- (void)createGestureRecognizers;

#pragma mark Generating the View Contents

- (void)regenerateContents;

#pragma mark Typesetting

- (void)typesetText;

#pragma mark Tiling Sections

- (void)tileSections;
- (void)untileVisibleSections;
- (BOOL)isDisplayingSectionAtIndex:(NSInteger)index;
- (NKTTextSection *)dequeueReusableSection;
- (void)configureSection:(NKTTextSection *)section atIndex:(NSInteger)index;
- (CGRect)frameForSectionAtIndex:(NSInteger)index;

#pragma mark Responding to Gestures

- (void)handleTap:(UIGestureRecognizer *)gestureRecognizer;
- (void)handleDoubleTapAndDrag:(UIGestureRecognizer *)gestureRecognizer;

#pragma mark Hit-Testing

- (NKTTextHitResult)textHitTestAtPoint:(CGPoint)point;

#pragma mark Getting and Converting Coordinates

- (CGPoint)originForLineAtIndex:(NSUInteger)index;
- (CGPoint)convertPoint:(CGPoint)point toLine:(NKTLine *)line;

#pragma mark Getting Line Indices

- (NKTLine *)lineContainingTextPosition:(NKTTextPosition *)textPosition;

#pragma mark Getting Fonts at Text Positions

- (NKTFont *)fontAtTextPosition:(NKTTextPosition *)textPosition;

#pragma mark Managing Selection Visuals

- (void)showSelectionCaretOnLine:(NKTLine *)line;
- (void)hideSelectionCaret;

- (void)showSelectionBand;
- (void)hideSelectionBand;

- (void)showSelectionBandLoupeWithTouchLocation:(CGPoint)point onLine:(NKTLine *)line;
- (void)hideSelectionBandLoupe;

- (CGRect)frameForCaretAtTextPosition:(NKTTextPosition *)textPosition;
- (CGRect)frameForCaretAtTextPosition:(NKTTextPosition *)textPosition onLine:(NKTLine *)line;

#pragma mark Working with Marked and Selected Text

- (void)setSelectedTextPosition:(NKTTextPosition *)textPosition;
- (void)setSelectedTextPosition:(NKTTextPosition *)textPosition placingCaretOnLine:(NKTLine *)line;
- (void)setSelectedTextRange:(UITextRange *)textRange;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------

@implementation NKTTextView

@synthesize text;

@synthesize margins;
@synthesize lineHeight;

@synthesize horizontalRulesEnabled;
@synthesize horizontalRuleColor;
@synthesize horizontalRuleOffset;
@synthesize verticalMarginEnabled;
@synthesize verticalMarginColor;
@synthesize verticalMarginInset;

@synthesize preFirstResponderTapGestureRecognizer;
@synthesize tapGestureRecognizer;
@synthesize doubleTapAndDragGestureRecognizer;

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        self.opaque = NO;
        self.clearsContextBeforeDrawing = YES;
        [self requiredInit_NKTTextView];
    }
    
    return self;
}

- (void)awakeFromNib
{
    [self requiredInit_NKTTextView];
}

- (void)requiredInit_NKTTextView
{
    self.alwaysBounceVertical = YES;
    
    text = [[NSMutableAttributedString alloc] init];
    
    margins = UIEdgeInsetsMake(60.0, 80.0, 80.0, 60.0);
    lineHeight = 32.0;
    //margins = UIEdgeInsetsMake(90.0, 90.0, 120.0, 90.0);
    //lineHeight = 30.0;
    
    horizontalRulesEnabled = YES;
    horizontalRuleColor = [[UIColor colorWithRed:0.72 green:0.72 blue:0.59 alpha:1.0] retain];
    horizontalRuleOffset = 3.0;
    verticalMarginEnabled = YES;
    verticalMarginColor = [[UIColor colorWithRed:0.7 green:0.3 blue:0.29 alpha:1.0] retain];
    verticalMarginInset = 60.0;
    
    visibleSections = [[NSMutableSet alloc] init];
    reusableSections = [[NSMutableSet alloc] init];
    
    [self createSelectionViews];
    [self createGestureRecognizers];
}

- (void)createSelectionViews
{
    selectionCaret = [[NKTCaret alloc] initWithFrame:CGRectMake(0.0, 0.0, 3.0, 30.0)];
    selectionCaret.hidden = YES;
    [self addSubview:selectionCaret];
    
    selectionBandTop = [[UIView alloc] initWithFrame:self.bounds];
    selectionBandTop.backgroundColor = [UIColor colorWithRed:0.25 green:0.45 blue:0.9 alpha:0.3];
    selectionBandTop.hidden = YES;
    [self addSubview:selectionBandTop];
    
    selectionBandMiddle = [[UIView alloc] initWithFrame:self.bounds];
    selectionBandMiddle.backgroundColor = [UIColor colorWithRed:0.25 green:0.45 blue:0.9 alpha:0.3];
    selectionBandMiddle.hidden = YES;
    [self addSubview:selectionBandMiddle];
    
    selectectionBandBottom = [[UIView alloc] initWithFrame:self.bounds];
    selectectionBandBottom.backgroundColor = [UIColor colorWithRed:0.25 green:0.45 blue:0.9 alpha:0.3];
    selectectionBandBottom.hidden = YES;
    [self addSubview:selectectionBandBottom];
}

- (void)createGestureRecognizers
{
    gestureRecognizerDelegate = [[NKTTextViewGestureRecognizerDelegate alloc] initWithTextView:self];
    
    preFirstResponderTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    preFirstResponderTapGestureRecognizer.delegate = gestureRecognizerDelegate;
    
    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapGestureRecognizer.delegate = gestureRecognizerDelegate;
    
    doubleTapAndDragGestureRecognizer = [[NKTDragGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapAndDrag:)];
    doubleTapAndDragGestureRecognizer.delegate = gestureRecognizerDelegate;
    
    [preFirstResponderTapGestureRecognizer requireGestureRecognizerToFail:doubleTapAndDragGestureRecognizer];
    [self addGestureRecognizer:tapGestureRecognizer];
    [self addGestureRecognizer:preFirstResponderTapGestureRecognizer];
    [self addGestureRecognizer:doubleTapAndDragGestureRecognizer];
}

- (void)dealloc
{
    [text release];
    
    [horizontalRuleColor release];
    [verticalMarginColor release];
    
    [typesettedLines release];
    
    [visibleSections release];
    [reusableSections release];
    
    [selectedTextRange release];
    
    [selectionCaret release];
    [selectionBandTop release];
    [selectionBandMiddle release];
    [selectectionBandBottom release];
    [selectionBandLoupe release];

    [gestureRecognizerDelegate release];
    [preFirstResponderTapGestureRecognizer release];
    [tapGestureRecognizer release];
    [doubleTapAndDragGestureRecognizer release];
    [doubleTapStartTextPosition release];
    
    [super dealloc];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Managing the Delegate

- (id <NKTTextViewDelegate>)delegate
{
    return (id <NKTTextViewDelegate>)[super delegate];
}

- (void)setDelegate:(id <NKTTextViewDelegate>)delegate
{
    [super setDelegate:delegate];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Updating the Content Size

- (void)updateContentSize
{
    CGSize size = self.bounds.size;
    size.height = ((CGFloat)[typesettedLines count] *  lineHeight) + margins.top + margins.bottom;
    self.contentSize = size;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Modifying the Bounds and Frame Rectangles

- (void)setFrame:(CGRect)frame
{
    if (CGRectEqualToRect(self.frame, frame))
    {
        return;
    }
    
    [super setFrame:frame];
    [self regenerateContents];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Laying out Views

- (void)layoutSubviews 
{
    [super layoutSubviews];
    [self tileSections];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Accessing the Text

// TODO: follow UITextView conventions on ownership
- (void)setText:(NSMutableAttributedString *)newText
{
    [newText retain];
    [text release];
    text = newText;
    [self regenerateContents];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Configuring Text Layout and Style

- (void)setLineHeight:(CGFloat)newLineHeight 
{
    lineHeight = newLineHeight;
    // Don't need to typeset because the line width is not changing
    [self untileVisibleSections];
    [self tileSections];
    [self updateContentSize];
}

- (void)setMargins:(UIEdgeInsets)newMargins
{
    margins = newMargins;
    [self regenerateContents];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Generating the View Contents

// TODO: use a dirty marker instead and call this as needed
// e.g.: [self setLineWidthDirty];
- (void)regenerateContents
{
    [self typesetText];
    [self untileVisibleSections];
    [self tileSections];
    [self updateContentSize];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Typesetting

// TODO: delegate this work to someone else
- (void)typesetText
{
    [typesettedLines release];
    typesettedLines = nil;
    
    if ([text length] == 0)
    {
        return;
    }

    typesettedLines = [[NSMutableArray alloc] init];
    CTTypesetterRef typesetter = CTTypesetterCreateWithAttributedString((CFAttributedStringRef)text);
    CFIndex length = (CFIndex)[text length];
    CGFloat lineWidth = CGRectGetWidth(self.bounds) - (margins.left + margins.right);
    CFIndex charIndex = 0;
    NSUInteger lineIndex = 0;
    
    while (charIndex < length)
    {
        CFIndex charCount = CTTypesetterSuggestLineBreak(typesetter, charIndex, lineWidth);
        // TODO: white space fucks this up
        CFRange range = CFRangeMake(charIndex, charCount);
        CTLineRef ctLine = CTTypesetterCreateLine(typesetter, range);
        NKTLine *line = [[NKTLine alloc] initWithIndex:lineIndex text:text CTLine:ctLine];
        CFRelease(ctLine);
        [typesettedLines addObject:line];
        [line release];
        charIndex += charCount;
        ++lineIndex;
    }
    
    CFRelease(typesetter);
}

//--------------------------------------------------------------------------------------------------

#pragma mark Tiling Sections

- (void)tileSections
{
    CGRect bounds = self.bounds;
    NSInteger firstVisibleSectionIndex = (NSInteger)floorf(CGRectGetMinY(bounds) / CGRectGetHeight(bounds));
    NSInteger lastVisibleSectionIndex = (NSInteger)floorf((CGRectGetMaxY(bounds) - 1.0) / CGRectGetHeight(bounds));
    
    // Recycle no longer visible sections
    for (NKTTextSection *section in visibleSections)
    {
        if (section.index < firstVisibleSectionIndex || section.index > lastVisibleSectionIndex)
        {
            [reusableSections addObject:section];
            [section removeFromSuperview];
        }
    }
    
    [visibleSections minusSet:reusableSections];
    
    // Add missing sections
    for (NSInteger index = firstVisibleSectionIndex; index <= lastVisibleSectionIndex; ++index)
    {
        if (![self isDisplayingSectionAtIndex:index])
        {
            NKTTextSection *section = [self dequeueReusableSection];
            
            if (section == nil)
            {
                section = [[NKTTextSection alloc] initWithFrame:self.bounds];
            }
            
            [self configureSection:section atIndex:index];
            [self insertSubview:section atIndex:0];
            [visibleSections addObject:section];
        }
    }
}

- (void)untileVisibleSections
{
    for (NKTTextSection *section in visibleSections)
    {
        [reusableSections addObject:section];
        [section removeFromSuperview];
    }
    
    [visibleSections removeAllObjects];
}

- (BOOL)isDisplayingSectionAtIndex:(NSInteger)index
{
    for (NKTTextSection *section in visibleSections)
    {
        if (section.index == index)
        {
            return YES;
        }
    }
    
    return NO;
}

- (NKTTextSection *)dequeueReusableSection
{
    NKTTextSection *section = [reusableSections anyObject];
    
    if (section != nil)
    {
        [[section retain] autorelease];
        [reusableSections removeObject:section];
        return section;
    }
    
    return nil;
}

- (void)configureSection:(NKTTextSection *)section atIndex:(NSInteger)index
{
    section.frame = [self frameForSectionAtIndex:index];
    
    section.index = index;

    section.typesettedLines = typesettedLines;
    
    section.margins = margins;
    section.lineHeight = lineHeight;
    
    section.horizontalRulesEnabled = horizontalRulesEnabled;
    section.horizontalRuleColor = horizontalRuleColor;
    section.horizontalRuleOffset = horizontalRuleOffset;
    
    section.verticalMarginEnabled = verticalMarginEnabled;
    section.verticalMarginColor = verticalMarginColor;
    section.verticalMarginInset = verticalMarginInset;
    
    [section setNeedsDisplay];
}

- (CGRect)frameForSectionAtIndex:(NSInteger)index
{
    CGRect sectionFrame = self.bounds;
    sectionFrame.origin.x = 0.0;
    sectionFrame.origin.y = (CGFloat)index * CGRectGetHeight(sectionFrame);
    return sectionFrame;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Managing the Responder Chain

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)resignFirstResponder
{
    BOOL resignsFirstResponder = [super resignFirstResponder];
    
    if (!resignsFirstResponder)
    {
        return NO;
    }
    
    [self setSelectedTextRange:nil];

    return YES;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Responding to Gestures

- (void)handleTap:(UIGestureRecognizer *)gestureRecognizer
{   
    if (![self isFirstResponder])
    {
        if (![self becomeFirstResponder])
        {
            return;
        }
    }
    
    CGPoint touchLocation = [gestureRecognizer locationInView:self];
    NKTTextHitResult hitResult = [self textHitTestAtPoint:touchLocation];
    [self setSelectedTextPosition:hitResult.textPosition placingCaretOnLine:hitResult.line];
}

- (void)handleDoubleTapAndDrag:(UIGestureRecognizer *)gestureRecognizer
{    
    CGPoint touchLocation = [gestureRecognizer locationInView:self];
    NKTTextHitResult hitResult = [self textHitTestAtPoint:touchLocation];
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        doubleTapStartTextPosition = [hitResult.textPosition retain];
        [self showSelectionBandLoupeWithTouchLocation:touchLocation onLine:hitResult.line];
    }
    else if (gestureRecognizer.state == UIGestureRecognizerStateChanged)
    {
        NKTTextRange *textRange = [NKTTextRange textRangeWithTextPosition:doubleTapStartTextPosition textPosition:hitResult.textPosition];
        [self setSelectedTextRange:textRange];
        [self showSelectionBandLoupeWithTouchLocation:touchLocation onLine:hitResult.line];
    }
    else
    {
        [self hideSelectionBandLoupe];
        [doubleTapStartTextPosition release];
        doubleTapStartTextPosition = nil;
    }
}

//--------------------------------------------------------------------------------------------------

#pragma mark Hit Testing

// TODO: get rid of this and move extra line info into the text position
- (NKTTextHitResult)textHitTestAtPoint:(CGPoint)point
{
    NKTTextHitResult result;
    NSInteger lineIndex = (NSInteger)floor((point.y - margins.top) / lineHeight);
    
    if (lineIndex < 0 || [typesettedLines count] == 0)
    {
        result.textPosition = [NKTTextPosition textPositionWithIndex:0];
        result.line = nil;
    }
    else if (lineIndex >= (NSInteger)[typesettedLines count])
    {
        result.textPosition = [NKTTextPosition textPositionWithIndex:[text length]];
        result.line = nil;
    }
    else
    {
        NKTLine *line = [typesettedLines objectAtIndex:(NSUInteger)lineIndex];
        CGPoint localPoint = [self convertPoint:point toLine:line];
        result.textPosition = [line closestTextPositionToPoint:localPoint];
        result.line = line;
    }
    
    return result;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting and Converting Coordinates

- (CGPoint)originForLineAtIndex:(NSUInteger)index
{
    CGFloat y = margins.top + lineHeight + ((CGFloat)index * lineHeight);
    CGPoint lineOrigin = CGPointMake(margins.left, y);
    return lineOrigin;
}

- (CGPoint)convertPoint:(CGPoint)point toLine:(NKTLine *)line
{
    CGPoint lineOrigin = [self originForLineAtIndex:line.index];
    return CGPointMake(point.x - lineOrigin.x, point.y - lineOrigin.y);
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Line Indices

- (NKTLine *)lineContainingTextPosition:(NKTTextPosition *)textPosition
{ 
    for (NKTLine *line in typesettedLines)
    {
        if ([line.textRange containsTextPosition:textPosition])
        {
            return line;
        }
    }
    
    return nil;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Font Metrics at Text Positions

// Returns font at the text position if available, otherwise returns the default system font.
- (NKTFont *)fontAtTextPosition:(NKTTextPosition *)textPosition
{
    // Look for available font attribute at the previous text position
    if ([text length] > 0)
    {
        NSUInteger textIndex = (NSUInteger)MAX(0, (NSInteger)textPosition.index);
        textIndex = (NSUInteger)MIN(textIndex, ((NSInteger)[text length] - 1));
        NSDictionary *textAttributes = [text attributesAtIndex:textIndex effectiveRange:NULL];
        CTFontRef font = (CTFontRef)[textAttributes objectForKey:(id)kCTFontAttributeName];
        
        if (font != NULL)
        {
            return [NKTFont fontWithCTFont:font];
        }
    }
    
    return [NKTFont systemFont];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Managing Selection Visuals

- (void)showSelectionCaretOnLine:(NKTLine *)line
{
    selectionCaret.frame = [self frameForCaretAtTextPosition:(NKTTextPosition *)selectedTextRange.start onLine:line];
    [selectionCaret startBlinking];
    selectionCaret.hidden = NO;
}

- (void)hideSelectionCaret
{
    selectionCaret.hidden = YES;
}

// TODO: refactor this
- (void)showSelectionBand
{
    CGRect startCaretFrame = [self frameForCaretAtTextPosition:(NKTTextPosition *)selectedTextRange.start];
    CGRect endCaretFrame = [self frameForCaretAtTextPosition:(NKTTextPosition *)selectedTextRange.end];
    
    // Single line
    if (startCaretFrame.origin.y == endCaretFrame.origin.y)
    {
        selectionBandTop.frame = CGRectMake(startCaretFrame.origin.x + startCaretFrame.size.width,
                                            startCaretFrame.origin.y,
                                            endCaretFrame.origin.x - startCaretFrame.origin.x - startCaretFrame.size.width,
                                            startCaretFrame.size.height);
        selectionBandTop.hidden = NO;
        selectionBandMiddle.hidden = YES;
        selectectionBandBottom.hidden = YES;
    }
    // Multiline
    else
    {
        selectionBandTop.frame = CGRectMake(startCaretFrame.origin.x + startCaretFrame.size.width,
                                            startCaretFrame.origin.y,
                                            self.bounds.size.width - margins.right - startCaretFrame.origin.x - startCaretFrame.size.width,
                                            startCaretFrame.size.height);    
        selectionBandMiddle.frame = CGRectMake(margins.left,
                                               startCaretFrame.origin.y + startCaretFrame.size.height,
                                               self.bounds.size.width - margins.left - margins.right,
                                               endCaretFrame.origin.y - startCaretFrame.origin.y - startCaretFrame.size.height);
        selectectionBandBottom.frame = CGRectMake(margins.left,
                                                  endCaretFrame.origin.y,
                                                  endCaretFrame.origin.x - margins.left,
                                                  endCaretFrame.size.height);
        selectionBandTop.hidden = NO;
        selectionBandMiddle.hidden = NO;
        selectectionBandBottom.hidden = NO;
    }
}

- (void)hideSelectionBand
{
    selectionBandTop.hidden = YES;
    selectionBandMiddle.hidden = YES;
    selectectionBandBottom.hidden = YES;
}

// TODO: Change name to present/update?
// TODO: Not crazy about having an onLine: component here
- (void)showSelectionBandLoupeWithTouchLocation:(CGPoint)touchLocation onLine:(NKTLine *)line
{
    if (line == nil)
    {
        [selectionBandLoupe setHidden:YES animated:NO];
        return;
    }
    
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    
    if (selectionBandLoupe == nil)
    {
        selectionBandLoupe = [[NKTLoupe alloc] initWithStyle:NKTLoupeStyleBand];
        selectionBandLoupe.hidden = YES;
        UIView *magnifiedView = [self.delegate viewForMagnifyingInTextView:self];
        
        if (magnifiedView == nil)
        {
            magnifiedView = self.superview;
        }
        
        selectionBandLoupe.zoomedView = magnifiedView;
        [keyWindow addSubview:selectionBandLoupe];
    }
    
    CGPoint lineOrigin = [self originForLineAtIndex:line.index];
    
    CGPoint magnifiedCenter = CGPointMake(touchLocation.x, lineOrigin.y);
    magnifiedCenter = [self convertPoint:magnifiedCenter toView:self.superview];
    selectionBandLoupe.zoomCenter = magnifiedCenter;
    
    CGPoint anchor = CGPointMake(touchLocation.x, lineOrigin.y - lineHeight);
    anchor = KBCClampPointToRect(anchor, self.bounds);
    selectionBandLoupe.anchor = [self convertPoint:anchor toView:keyWindow];
    
    [selectionBandLoupe setHidden:NO animated:YES];
}

- (void)hideSelectionBandLoupe
{
    [selectionBandLoupe setHidden:YES animated:YES];
}

- (CGRect)frameForCaretAtTextPosition:(NKTTextPosition *)textPosition
{
    return [self frameForCaretAtTextPosition:textPosition onLine:nil];
}

- (CGRect)frameForCaretAtTextPosition:(NKTTextPosition *)textPosition onLine:(NKTLine *)line
{
    CGPoint lineOrigin = CGPointZero;
    CGFloat charOffset = 0.0;
    NSUInteger textLength = [text length];
    NSUInteger lineCount = [typesettedLines count];
    
    // Line provided
    if (line != nil)
    {
        lineOrigin = [self originForLineAtIndex:line.index];
        charOffset = [line offsetForCharAtTextPosition:textPosition];
    }
    // No lines or start of text
    else if (lineCount == 0 || textPosition.index == 0)
    {
        lineOrigin = [self originForLineAtIndex:0];
    }
    // End of text
    else if (textPosition.index == textLength)
    {
        if ([[text string] characterAtIndex:(textLength - 1)] == '\n')
        {
            lineOrigin = [self originForLineAtIndex:lineCount];
        }
        else
        {
            NKTLine *lastLine = [typesettedLines objectAtIndex:(lineCount - 1)];
            lineOrigin = [self originForLineAtIndex:lastLine.index];
            charOffset = [lastLine offsetForCharAtTextPosition:textPosition];
        }
    }
    // Search for line
    else
    {
        NKTLine *line = [self lineContainingTextPosition:textPosition];
        lineOrigin = [self originForLineAtIndex:line.index];
        charOffset = [line offsetForCharAtTextPosition:textPosition];
    }
    
    const CGFloat caretWidth = 2.0;
    const CGFloat caretVerticalPadding = 1.0;
    
    NKTFont *font = nil;
    
    // The caret is based on the font of the text that would be inserted at the text position
    if (textPosition.index == 0)
    {
        font = [self fontAtTextPosition:textPosition];
    }
    else
    {
        font = [self fontAtTextPosition:[textPosition previousTextPosition]];
    }
    
    CGRect caretFrame = CGRectZero;
    caretFrame.origin.x = lineOrigin.x + charOffset;
    caretFrame.origin.y = lineOrigin.y - font.ascent - caretVerticalPadding;
    caretFrame.size.width = caretWidth;
    caretFrame.size.height = font.ascent + font.descent + (caretVerticalPadding * 2.0);
    return caretFrame;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Working with Marked and Selected Text

- (void)setSelectedTextPosition:(NKTTextPosition *)textPosition
{
    [self setSelectedTextPosition:textPosition placingCaretOnLine:nil];
}

- (void)setSelectedTextPosition:(NKTTextPosition *)textPosition placingCaretOnLine:(NKTLine *)line
{
    [selectedTextRange release];
    selectedTextRange = [[textPosition textRange] copy];
    [self hideSelectionBand];
    [self showSelectionCaretOnLine:line]; 
}

- (void)setSelectedTextRange:(UITextRange *)textRange
{
    [selectedTextRange autorelease];
    selectedTextRange = [textRange copy];
    [self hideSelectionCaret];

    if (selectedTextRange == nil)
    {
        [self hideSelectionBand];
    }
    else
    {
        [self showSelectionBand];
    }
}

//--------------------------------------------------------------------------------------------------

#pragma mark Inserting and Deleting Text

- (BOOL)hasText
{
    return [text length] > 0;
}

- (void)insertText:(NSString *)theText
{
    [text replaceCharactersInRange:selectedTextRange.nsRange withString:theText];
    [self regenerateContents];
    NSUInteger newIndex = selectedTextRange.startIndex + [theText length];
    [self setSelectedTextPosition:[NKTTextPosition textPositionWithIndex:newIndex]];
}

- (void)deleteBackward
{
    NSRange deletionRange;
    
    if (selectedTextRange.startIndex == 0)
    {
        deletionRange = NSMakeRange(0, selectedTextRange.length);
    }
    else
    {
        deletionRange = NSMakeRange(selectedTextRange.startIndex - 1, selectedTextRange.length + 1);
    }
    
    [text deleteCharactersInRange:deletionRange];
    [self regenerateContents];
    [self setSelectedTextPosition:[NKTTextPosition textPositionWithIndex:deletionRange.location]];
}

@end
