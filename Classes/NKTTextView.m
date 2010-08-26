//  The MIT License
//  
//  Copyright (c) 2010 TropicalPixels, Jeffrey Sambells
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTTextView.h"
#import <CoreText/CoreText.h>
#import "NKTCaret.h"
#import "NKTLine.h"
#import "NKTTextPosition.h"
#import "NKTTextRange.h"
#import "NKTTextSection.h"
#import "NKTTextViewGestureRecognizerDelegate.h"

@interface NKTTextView()

#pragma mark Initializing

- (void)commonInit_NKTTextView;
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

- (void)handleNonFirstResponderTap;
- (void)handleTap;
- (void)handleDoubleTapAndDrag;

#pragma mark Hit-Testing

- (void)getClosestTextPosition:(NKTTextPosition **)textPosition sourceLineIndex:(NSUInteger *)originatingLineIndex toPoint:(CGPoint)point;

#pragma mark Getting and Converting Coordinates

- (CGPoint)originForLineAtIndex:(NSUInteger)index;
- (CGPoint)convertPoint:(CGPoint)point toLineAtIndex:(NSUInteger)index;

#pragma mark Getting Line Indices

- (NSInteger)indexForVirtualLineSpanningVerticalOffset:(CGFloat)verticalOffset;
- (NSUInteger)indexForLineContainingTextPosition:(NKTTextPosition *)textPosition;

#pragma mark Getting Font Metrics at Text Positions

- (void)getFontAscent:(CGFloat *)ascent descent:(CGFloat *)descent atTextPosition:(NKTTextPosition *)textPosition;

#pragma mark Managing Selection Visuals

- (void)showSelectedTextPositionCaretWithSourceLineAtIndex:(NSUInteger)index;
- (void)showSelectedTextRangeBand;
- (void)hideSelectedTextPositionCaret;
- (void)hideSelectedTextRangeBand;
- (CGRect)frameForCaretAtTextPosition:(NKTTextPosition *)textPosition withSourceLineAtIndex:(NSUInteger)sourceLineIndex;

#pragma mark Working with Marked and Selected Text

- (void)selectClosestTextPositionToPoint:(CGPoint)point;
- (void)setSelectedTextRange:(NKTTextRange *)textRange withSourceLineAtIndex:(NSUInteger)sourceLineIndex;

@property(nonatomic, readwrite, copy) UITextRange *selectedTextRange;

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

@synthesize nonFirstResponderTapGestureRecognizer;
@synthesize tapGestureRecognizer;
@synthesize doubleTapAndDragGestureRecognizer;

@synthesize selectedTextRange;

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        self.opaque = NO;
        self.clearsContextBeforeDrawing = YES;
        [self commonInit_NKTTextView];
    }
    
    return self;
}

- (void)awakeFromNib
{
    [self commonInit_NKTTextView];
}

- (void)commonInit_NKTTextView
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
    selectedTextPositionCaret = [[NKTCaret alloc] initWithFrame:CGRectMake(0.0, 0.0, 3.0, 30.0)];
    selectedTextPositionCaret.hidden = YES;
    [self addSubview:selectedTextPositionCaret];
    
    selectedTextRangeBandTop = [[UIView alloc] initWithFrame:self.bounds];
    selectedTextRangeBandTop.backgroundColor = [UIColor colorWithRed:0.25 green:0.45 blue:0.9 alpha:0.3];
    selectedTextRangeBandTop.hidden = YES;
    [self addSubview:selectedTextRangeBandTop];
    
    selectedTextRangeBandMiddle = [[UIView alloc] initWithFrame:self.bounds];
    selectedTextRangeBandMiddle.backgroundColor = [UIColor colorWithRed:0.25 green:0.45 blue:0.9 alpha:0.3];
    selectedTextRangeBandMiddle.hidden = YES;
    [self addSubview:selectedTextRangeBandMiddle];
    
    selectedTextRangeBandBottom = [[UIView alloc] initWithFrame:self.bounds];
    selectedTextRangeBandBottom.backgroundColor = [UIColor colorWithRed:0.25 green:0.45 blue:0.9 alpha:0.3];
    selectedTextRangeBandBottom.hidden = YES;
    [self addSubview:selectedTextRangeBandBottom];
}

- (void)createGestureRecognizers
{
    gestureRecognizerDelegate = [[NKTTextViewGestureRecognizerDelegate alloc] initWithTextView:self];
    
    nonFirstResponderTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleNonFirstResponderTap)];
    nonFirstResponderTapGestureRecognizer.delegate = gestureRecognizerDelegate;
    
    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    tapGestureRecognizer.delegate = gestureRecognizerDelegate;
    
    doubleTapAndDragGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapAndDrag)];
    doubleTapAndDragGestureRecognizer.delegate = gestureRecognizerDelegate;
    doubleTapAndDragGestureRecognizer.numberOfTapsRequired = 1;
    doubleTapAndDragGestureRecognizer.allowableMovement = 10000.0;
    doubleTapAndDragGestureRecognizer.minimumPressDuration = 0.001;
    
    [nonFirstResponderTapGestureRecognizer requireGestureRecognizerToFail:doubleTapAndDragGestureRecognizer];
    [self addGestureRecognizer:nonFirstResponderTapGestureRecognizer];
    [self addGestureRecognizer:tapGestureRecognizer];
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
    
    [selectedTextPositionCaret release];
    [selectedTextRangeBandTop release];
    [selectedTextRangeBandMiddle release];
    [selectedTextRangeBandBottom release];

    [gestureRecognizerDelegate release];
    [nonFirstResponderTapGestureRecognizer release];
    [tapGestureRecognizer release];
    [doubleTapAndDragGestureRecognizer release];
    [doubleTapStartTextPosition release];
    
    [super dealloc];
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
    // Don't need to typeset since the line width is not changing
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

- (void)regenerateContents
{
    [self typesetText];
    [self untileVisibleSections];
    [self tileSections];
    [self updateContentSize];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Typesetting

- (void)typesetText
{
    [typesettedLines release];
    typesettedLines = nil;
    
    if ([text length] == 0)
    {
        return;
    }

    typesettedLines = [[NSMutableArray alloc] init];
    // TODO: log if this fails
    CTTypesetterRef typesetter = CTTypesetterCreateWithAttributedString((CFAttributedStringRef)text);
    CFIndex length = (CFIndex)[text length];
    CGFloat lineWidth = CGRectGetWidth(self.bounds) - (margins.left + margins.right);
    CFIndex charIndex = 0;
    
    while (charIndex < length)
    {
        CFIndex charCount = CTTypesetterSuggestLineBreak(typesetter, charIndex, lineWidth);
        // TODO: white space fucks this up
        CFRange range = CFRangeMake(charIndex, charCount);
        CTLineRef ctLine = CTTypesetterCreateLine(typesetter, range);
        NKTLine *line = [[NKTLine alloc] initWithText:text CTLine:ctLine];
        CFRelease(ctLine);
        [typesettedLines addObject:line];
        [line release];
        charIndex += charCount;
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

- (void)selectClosestTextPositionToPoint:(CGPoint)point
{
    NKTTextPosition *textPosition = nil;
    NSUInteger sourceLineIndex = NSNotFound;
    [self getClosestTextPosition:&textPosition sourceLineIndex:&sourceLineIndex toPoint:point];
    [self setSelectedTextRange:[textPosition textRange] withSourceLineAtIndex:sourceLineIndex];
}

- (void)handleNonFirstResponderTap
{
    NSLog(@"non first responder tap");
    if (![self isFirstResponder] && ![self becomeFirstResponder])
    {
        return;
    }
    
    CGPoint touchLocation = [nonFirstResponderTapGestureRecognizer locationInView:self];
    [self selectClosestTextPositionToPoint:touchLocation];
}

- (void)handleTap
{
    NSLog(@"regular tap");
    CGPoint touchLocation = [tapGestureRecognizer locationInView:self];
    [self selectClosestTextPositionToPoint:touchLocation];
}

- (void)handleDoubleTapAndDrag
{
    CGPoint touchLocation = [doubleTapAndDragGestureRecognizer locationInView:self];
    
    if (doubleTapAndDragGestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        self.scrollEnabled = NO;
        [self getClosestTextPosition:&doubleTapStartTextPosition sourceLineIndex:NULL toPoint:touchLocation];
        [doubleTapStartTextPosition retain];
    }
    else if (doubleTapAndDragGestureRecognizer.state == UIGestureRecognizerStateChanged)
    {        
        NKTTextPosition *textPosition = nil;
        [self getClosestTextPosition:&textPosition sourceLineIndex:NULL toPoint:touchLocation];
        NKTTextRange *textRange = [NKTTextRange textRangeWithTextPosition:doubleTapStartTextPosition textPosition:textPosition];
        [self setSelectedTextRange:textRange];
    }
    else
    {
        [doubleTapStartTextPosition release];
        doubleTapStartTextPosition = nil;
        self.scrollEnabled = YES;
    }
}

//--------------------------------------------------------------------------------------------------

#pragma mark Inserting and Deleting Text

- (BOOL)hasText
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    return [text length] > 0;
}

- (void)insertText:(NSString *)theText
{
    NSLog(@"%s %@", __PRETTY_FUNCTION__, theText);
    NKTTextPosition *textPosition = (NKTTextPosition *)selectedTextRange.start;
    NSUInteger textIndex = textPosition.index;
    // replaceCharactersInRange: treats the length of the string as a valid range value
    [text replaceCharactersInRange:NSMakeRange(textIndex, 0) withString:theText];
    [self typesetText];
    [self untileVisibleSections];
    [self tileSections];
    [self updateContentSize];
    self.selectedTextRange = [[textPosition nextPosition] textRange];
}

- (void)deleteBackward
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NKTTextPosition *textPosition = (NKTTextPosition *)selectedTextRange.start;
    NSUInteger textIndex = textPosition.index;
    
    if (textIndex == 0)
    {
        return;
    }
    else
    {
        --textIndex;
    }
    
    [text deleteCharactersInRange:NSMakeRange(textIndex, 1)];
    [self typesetText];
    [self untileVisibleSections];
    [self tileSections];
    [self updateContentSize];
    self.selectedTextRange = [NKTTextRange textRangeWithNSRange:NSMakeRange(textIndex, 0)];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Hit Testing

// The index of the text position returned will be between 0 and the last string index plus 1.
- (void)getClosestTextPosition:(NKTTextPosition **)textPosition sourceLineIndex:(NSUInteger *)sourceLineIndex toPoint:(CGPoint)point
{
    NSInteger virtualLineIndex = [self indexForVirtualLineSpanningVerticalOffset:point.y];
    
    // Point lies before the first real line
    if (virtualLineIndex < 0 || [typesettedLines count] == 0)
    {
        if (textPosition != NULL)
        {
            *textPosition = [NKTTextPosition textPositionWithIndex:0];
        }
        
        if (sourceLineIndex != NULL)
        {
            *sourceLineIndex = NSNotFound;
        }
        
        return;
    }
    
    // Point lies beyond the last real line
    if (virtualLineIndex >= (NSInteger)[typesettedLines count])
    {
        if (textPosition != NULL)
        {
            *textPosition = [NKTTextPosition textPositionWithIndex:[text length]];
        }
        
        if (sourceLineIndex != NULL)
        {
            *sourceLineIndex = NSNotFound;
        }
        
        return;
    }
    
    // By this point, the virtual line index indexes a real line, so use it
    
    if (textPosition != NULL)
    {
        CGPoint lineLocalPoint = [self convertPoint:point toLineAtIndex:(NSUInteger)virtualLineIndex];
        NKTLine *line = [typesettedLines objectAtIndex:(NSUInteger)virtualLineIndex];
        *textPosition = [line closestTextPositionToPoint:lineLocalPoint];
    }
    
    if (sourceLineIndex != NULL)
    {
        *sourceLineIndex = (NSUInteger)virtualLineIndex;
    }
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting and Converting Coordinates

- (CGPoint)originForLineAtIndex:(NSUInteger)index
{
    CGFloat y = margins.top + lineHeight + ((CGFloat)index * lineHeight);
    CGPoint lineOrigin = CGPointMake(margins.left, y);
    return lineOrigin;
}

- (CGPoint)convertPoint:(CGPoint)point toLineAtIndex:(NSUInteger)index
{
    CGPoint lineOrigin = [self originForLineAtIndex:index];
    return CGPointMake(point.x - lineOrigin.x, point.y - lineOrigin.y);
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Line Indices

- (NSInteger)indexForVirtualLineSpanningVerticalOffset:(CGFloat)verticalOffset
{
    return (NSInteger)floor((verticalOffset - margins.top) / lineHeight);
}

// Returns NSNotFound if no line contains the text position.
- (NSUInteger)indexForLineContainingTextPosition:(NKTTextPosition *)textPosition
{    
    NSUInteger lineIndex = 0;
    
    for (NKTLine *line in typesettedLines)
    {
        NKTTextRange *textRange = [line textRange];
        
        if ([textRange containsTextPosition:textPosition])
        {
            return lineIndex;
        }
        
        ++lineIndex;
    }
    
    return NSNotFound;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Font Metrics at Text Positions

// Returns font metrics at the text position if available, otherwise returns the default system font
// metrics. The metrics at a text position are found by querying the font attributes of the
// preceding character if available, otherwise of the following character.
- (void)getFontAscent:(CGFloat *)ascent descent:(CGFloat *)descent atTextPosition:(NKTTextPosition *)textPosition
{
    CTFontRef font = NULL;
    
    // Look for available font attribute at the text position
    if ([text length] > 0)
    {
        NSUInteger textIndex = (NSUInteger)MAX(0, (NSInteger)textPosition.index - 1);
        textIndex = (NSUInteger)MIN(textIndex, ((NSInteger)[text length] - 1));
        NSDictionary *textAttributes = [text attributesAtIndex:textIndex effectiveRange:NULL];
        font = (CTFontRef)[textAttributes objectForKey:(id)kCTFontAttributeName];
    }
    
    if (font != NULL)
    {
        if (ascent != NULL)
        {
            *ascent = CTFontGetAscent(font);
        }
        
        if (descent != NULL)
        {
            *descent = CTFontGetDescent(font);
        }
    }
    else
    {
        if (ascent != NULL)
        {
            *ascent = 12.0 * 0.77;
        }
        
        if (descent != NULL)
        {
            *descent = 12.0 * 0.23;
        }
    }
}

//--------------------------------------------------------------------------------------------------

#pragma mark Managing Selection Visuals

- (void)showSelectedTextPositionCaretWithSourceLineAtIndex:(NSUInteger)index
{
    selectedTextPositionCaret.frame = [self frameForCaretAtTextPosition:(NKTTextPosition *)selectedTextRange.start withSourceLineAtIndex:index];
    [selectedTextPositionCaret startBlinking];
    selectedTextPositionCaret.hidden = NO;
}

- (void)showSelectedTextRangeBand
{
    CGRect startCaretFrame = [self frameForCaretAtTextPosition:(NKTTextPosition *)selectedTextRange.start withSourceLineAtIndex:NSNotFound];
    CGRect endCaretFrame = [self frameForCaretAtTextPosition:(NKTTextPosition *)selectedTextRange.end withSourceLineAtIndex:NSNotFound];
    
    // Single line
    if (startCaretFrame.origin.y == endCaretFrame.origin.y)
    {
        selectedTextRangeBandTop.frame = CGRectMake(startCaretFrame.origin.x + startCaretFrame.size.width,
                                                    startCaretFrame.origin.y,
                                                    endCaretFrame.origin.x - startCaretFrame.origin.x - startCaretFrame.size.width,
                                                    startCaretFrame.size.height);
        selectedTextRangeBandTop.hidden = NO;
        selectedTextRangeBandMiddle.hidden = YES;
        selectedTextRangeBandBottom.hidden = YES;
    }
    // Multiline
    else
    {
        selectedTextRangeBandTop.frame = CGRectMake(startCaretFrame.origin.x + startCaretFrame.size.width,
                                                    startCaretFrame.origin.y,
                                                    self.bounds.size.width - margins.right - startCaretFrame.origin.x - startCaretFrame.size.width,
                                                    startCaretFrame.size.height);    
        selectedTextRangeBandMiddle.frame = CGRectMake(margins.left,
                                                       startCaretFrame.origin.y + startCaretFrame.size.height,
                                                       self.bounds.size.width - margins.left - margins.right,
                                                       endCaretFrame.origin.y - startCaretFrame.origin.y - startCaretFrame.size.height);
        selectedTextRangeBandBottom.frame = CGRectMake(margins.left,
                                                       endCaretFrame.origin.y,
                                                       endCaretFrame.origin.x - margins.left,
                                                       endCaretFrame.size.height);
        selectedTextRangeBandTop.hidden = NO;
        selectedTextRangeBandMiddle.hidden = NO;
        selectedTextRangeBandBottom.hidden = NO;
    }
}

- (void)hideSelectedTextPositionCaret
{
    selectedTextPositionCaret.hidden = YES;
}

- (void)hideSelectedTextRangeBand
{
    selectedTextRangeBandTop.hidden = YES;
    selectedTextRangeBandMiddle.hidden = YES;
    selectedTextRangeBandBottom.hidden = YES;
}

- (CGRect)frameForCaretAtTextPosition:(NKTTextPosition *)textPosition withSourceLineAtIndex:(NSUInteger)sourceLineIndex
{
    const CGFloat caretWidth = 2.0;
    const CGFloat caretVerticalPadding = 1.0;

    // Get the ascent and descent at the text position
    CGFloat ascent = 0.0;
    CGFloat descent = 0.0;
    [self getFontAscent:&ascent descent:&descent atTextPosition:textPosition];
    
    // Get the line origin and offset for the text position
    CGPoint lineOrigin = CGPointZero;
    CGFloat charOffset = 0.0;
    
    if (sourceLineIndex != NSNotFound)
    {
        NKTLine *line = [typesettedLines objectAtIndex:sourceLineIndex];
        lineOrigin = [self originForLineAtIndex:sourceLineIndex];
        charOffset = [line offsetForCharAtTextPosition:textPosition];
    }
    else if (textPosition.index == 0)
    {
        lineOrigin = [self originForLineAtIndex:0];
    }
    else if (textPosition.index == [text length])
    {
        NSAssert([typesettedLines count] > 0, @"there should be at least one typesetted line");
        // Text length guaranteed to be > 0 here because we accounted for index 0 above
        
        if ([[text string] characterAtIndex:((NSInteger)[text length] - 1)] == '\n')
        {
            // The last character is a line break, set the line origin to be the origin of where
            // the line beyond the last real line would actually be.
            lineOrigin = [self originForLineAtIndex:[typesettedLines count]];
        }
        else
        {
            // Last character is not a line break, so caret rect lies on the last real line.
            NSUInteger lastLineIndex = [typesettedLines count] - 1;
            NKTLine *line = [typesettedLines objectAtIndex:lastLineIndex];
            lineOrigin = [self originForLineAtIndex:lastLineIndex];
            charOffset = [line offsetForCharAtTextPosition:textPosition];
        }
    }
    else
    {
        // Fallback to getting the line index manually
        NSUInteger lineIndex = [self indexForLineContainingTextPosition:textPosition];
        NSAssert(lineIndex != NSNotFound, @"already accounted for edge cases, so the text position should be on a typesetted line");
        NKTLine *line = [typesettedLines objectAtIndex:lineIndex];
        lineOrigin = [self originForLineAtIndex:lineIndex];
        charOffset = [line offsetForCharAtTextPosition:textPosition];
    }
    
    CGRect caretFrame = CGRectZero;
    caretFrame.origin.x = lineOrigin.x + charOffset;
    caretFrame.origin.y = lineOrigin.y - ascent - caretVerticalPadding;
    caretFrame.size.width = caretWidth;
    caretFrame.size.height = ascent + descent + (caretVerticalPadding * 2.0);
    return caretFrame;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Working with Marked and Selected Text

- (void)setSelectedTextRange:(NKTTextRange *)textRange withSourceLineAtIndex:(NSUInteger)sourceLineIndex
{
    [selectedTextRange autorelease];
    selectedTextRange = [textRange copy];
    
    if (selectedTextRange == nil)
    {
        [self hideSelectedTextRangeBand];
        [self hideSelectedTextPositionCaret];
    }
    if (selectedTextRange.empty)
    {
        [self hideSelectedTextRangeBand];
        [self showSelectedTextPositionCaretWithSourceLineAtIndex:sourceLineIndex];
    }
    else
    {
        [self hideSelectedTextPositionCaret];
        [self showSelectedTextRangeBand];
    }
}

- (void)setSelectedTextRange:(UITextRange *)textRange
{
    [self setSelectedTextRange:(NKTTextRange *)textRange withSourceLineAtIndex:NSNotFound];
}

@end
