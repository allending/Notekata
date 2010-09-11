//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTTextView.h"
#import <CoreText/CoreText.h>
#import "KBCFont.h"
#import "NKTDragGestureRecognizer.h"
#import "NKTLine.h"
#import "NKTLoupe.h"
#import "NKTTextPosition.h"
#import "NKTTextRange.h"
#import "NKTTextSection.h"
#import "NKTTextViewGestureRecognizerDelegate.h"

@interface NKTTextView()

#pragma mark Initializing

- (void)NKTTextView_requiredInit;
- (void)createGestureRecognizers;

#pragma mark Generating the View Contents

- (void)regenerateContents;

#pragma mark Typesetting

- (void)typesetLines;

#pragma mark Tiling Sections

- (void)tileSections;
- (void)untileVisibleSections;
- (BOOL)isDisplayingSectionAtIndex:(NSInteger)index;
- (NKTTextSection *)dequeueReusableSection;
- (void)configureSection:(NKTTextSection *)section atIndex:(NSInteger)index;
- (CGRect)frameForSectionAtIndex:(NSInteger)index;

#pragma mark Responding to Gestures

@property (nonatomic, retain) NKTTextPosition *doubleTapStartTextPosition;

- (void)handleTap:(UIGestureRecognizer *)gestureRecognizer;
- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer;
- (void)handleDoubleTapAndDrag:(UIGestureRecognizer *)gestureRecognizer;

#pragma mark Getting Lines

- (NSInteger)virtualIndexForLineContainingPoint:(CGPoint)point;
- (NKTLine *)closestLineContainingPoint:(CGPoint)point;
- (NKTLine *)lineContainingTextPosition:(NKTTextPosition *)textPosition;

#pragma mark Getting Fonts at Text Positions

- (UIFont *)fontAtTextPosition:(NKTTextPosition *)textPosition;

#pragma mark Managing Loupes

@property (nonatomic, readonly) NKTLoupe *bandLoupe;
@property (nonatomic, readonly) NKTLoupe *roundLoupe;

- (void)showLoupe:(NKTLoupe *)loupe atPoint:(CGPoint)point anchorToLine:(BOOL)anchorToLine;
- (void)showLoupe:(NKTLoupe *)loupe atTextPosition:(NKTTextPosition *)textPosition;

#pragma mark Working with Marked and Selected Text

- (void)setProvisionalTextRange:(NKTTextRange *)provisionalTextRange;
- (void)confirmProvisionalTextRange;
- (void)setMarkedTextRange:(NKTTextRange *)markedTextRange;

#pragma mark Geometry and Hit-Testing

- (CGPoint)originForLineAtIndex:(NSUInteger)index;
- (CGPoint)convertPoint:(CGPoint)point toLine:(NKTLine *)line;
- (CGRect)rectForLine:(NKTLine *)line;

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

@synthesize inputDelegate;

@synthesize nonEditTapGestureRecognizer;
@synthesize tapGestureRecognizer;
@synthesize longPressGestureRecognizer;
@synthesize doubleTapAndDragGestureRecognizer;
@synthesize doubleTapStartTextPosition = doubleTapStartTextPosition_;

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        self.opaque = NO;
        self.clearsContextBeforeDrawing = YES;
        [self NKTTextView_requiredInit];
    }
    
    return self;
}

- (void)awakeFromNib
{
    [self NKTTextView_requiredInit];
}

- (void)NKTTextView_requiredInit
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
    underlayViews = [[NSMutableSet alloc] init];
    overlayViews = [[NSMutableSet alloc] init];
    
    selectionDisplayController_ = [[NKTSelectionDisplayController alloc] init];
    selectionDisplayController_.delegate = self;
    
    [self createGestureRecognizers];
}

- (void)createGestureRecognizers
{
    gestureRecognizerDelegate = [[NKTTextViewGestureRecognizerDelegate alloc] initWithTextView:self];
    
    doubleTapAndDragGestureRecognizer = [[NKTDragGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapAndDrag:)];
    doubleTapAndDragGestureRecognizer.delegate = gestureRecognizerDelegate;
    
    nonEditTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    nonEditTapGestureRecognizer.delegate = gestureRecognizerDelegate;
    [nonEditTapGestureRecognizer requireGestureRecognizerToFail:doubleTapAndDragGestureRecognizer];
    
    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapGestureRecognizer.delegate = gestureRecognizerDelegate;
    
    longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPressGestureRecognizer.delegate = gestureRecognizerDelegate;
    
    [self addGestureRecognizer:tapGestureRecognizer];
    [self addGestureRecognizer:nonEditTapGestureRecognizer];
    [self addGestureRecognizer:longPressGestureRecognizer];
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
    [underlayViews release];
    [overlayViews release];
    
    [selectedTextRange release];
    [markedTextRange release];
    [markedTextStyle release];
    [markedText release];
    [provisionalTextRange_ release];
    
    [tokenizer release];
    
    [selectionDisplayController_ release];
    [bandLoupe_ release];
    [roundLoupe_ release];
    
    [gestureRecognizerDelegate release];
    [nonEditTapGestureRecognizer release];
    [tapGestureRecognizer release];
    [longPressGestureRecognizer release];
    [doubleTapAndDragGestureRecognizer release];
    [doubleTapStartTextPosition_ release];
    
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
    // Don't need to typeset lines because the line width is not changing
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
    [self typesetLines];
    [self untileVisibleSections];
    [self tileSections];
    [self updateContentSize];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Typesetting

- (void)typesetLines
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
            NSUInteger insertionIndex = [underlayViews count];
            [self insertSubview:section atIndex:insertionIndex];
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
    // Make sure the view is the first responder
    if (![self isFirstResponder])
    {
        if (![self becomeFirstResponder])
        {
            return;
        }
    }
    
    CGPoint touchLocation = [gestureRecognizer locationInView:self];
    NKTTextPosition *textPosition = (NKTTextPosition *)[self closestPositionToPoint:touchLocation];
    [inputDelegate selectionWillChange:self];
    [self setSelectedTextRange:[textPosition textRange]];
    [inputDelegate selectionDidChange:self];
    
    // Clear the marked text range when tapping outside it
    if (![markedTextRange containsTextPosition:textPosition])
    {
        [self setMarkedTextRange:nil];
    }
    
    selectionDisplayController_.caretVisible = YES;
}

- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer
{    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan || gestureRecognizer.state == UIGestureRecognizerStateChanged)
    {    
        CGPoint touchLocation = [gestureRecognizer locationInView:self];
        NKTTextPosition *textPosition = nil;
        
        // Computed text position depends on whether there is marked text or not
        if (markedTextRange != nil && !markedTextRange.empty)
        {
            textPosition = (NKTTextPosition *)[self closestPositionToPoint:touchLocation withinRange:markedTextRange];
            [self showLoupe:self.bandLoupe atTextPosition:textPosition];
        }
        else
        {
            textPosition = (NKTTextPosition *)[self closestPositionToPoint:touchLocation];
            [self showLoupe:self.roundLoupe atPoint:touchLocation anchorToLine:NO];
        }
        
        [self setProvisionalTextRange:[textPosition textRange]];
    }
    else
    {
        [self confirmProvisionalTextRange];
        [self.bandLoupe setHidden:YES animated:YES];
        [self.roundLoupe setHidden:YES animated:YES];
        selectionDisplayController_.caretVisible = [self isFirstResponder];
    }
}

- (void)handleDoubleTapAndDrag:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint touchLocation = [gestureRecognizer locationInView:self];
    NKTTextPosition *textPosition = (NKTTextPosition *)[self closestPositionToPoint:touchLocation];
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        self.doubleTapStartTextPosition = textPosition;
    }
    else if (gestureRecognizer.state == UIGestureRecognizerStateChanged)
    {
        [self showLoupe:self.bandLoupe atPoint:touchLocation anchorToLine:YES];
        NKTTextRange *textRange = [self.doubleTapStartTextPosition textRangeUntilTextPosition:textPosition];
        [self setProvisionalTextRange:textRange];
    }
    else
    {
        [self confirmProvisionalTextRange];
        [self.bandLoupe setHidden:YES animated:YES];
        self.doubleTapStartTextPosition = nil;
    }
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Lines

- (NSInteger)virtualIndexForLineContainingPoint:(CGPoint)point
{
    return (NSInteger)floor((point.y - margins.top) / lineHeight);
}

- (NKTLine *)closestLineContainingPoint:(CGPoint)point
{
    NSUInteger lineCount = [typesettedLines count];
    
    if (lineCount == 0)
    {
        return nil;
    }
    
    NSInteger virtualLineIndex = [self virtualIndexForLineContainingPoint:point];
    NSUInteger lineIndex = (NSUInteger)MAX(virtualLineIndex, 0);
    lineIndex = MIN(lineIndex, lineCount - 1);
    return [typesettedLines objectAtIndex:lineIndex];
}

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

#pragma mark Getting Fonts at Text Positions

// Returns font at the text position if available, otherwise returns the default system font.
- (UIFont *)fontAtTextPosition:(NKTTextPosition *)textPosition
{
    UIFont *font = nil;
    
    if ([text length] > 0)
    {
        // Look for available font attribute at the previous text position
        NSUInteger sourceIndex = (NSUInteger)MAX(0, (NSInteger)textPosition.index);
        sourceIndex = (NSUInteger)MIN(sourceIndex, ((NSInteger)[text length] - 1));
        NSDictionary *textAttributes = [text attributesAtIndex:sourceIndex effectiveRange:NULL];
        CTFontRef ctFont = (CTFontRef)[textAttributes objectForKey:(id)kCTFontAttributeName];
        
        if (ctFont != NULL)
        {
            font = KBCUIFontForCTFont(ctFont);
            
            if (font == nil)
            {
                KBCLogWarning(@"could not create UIFont for CTFont");
            }
        }
    }
    
    if (font == nil)
    {
        font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    }
    
    return font;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Managing Loupes

- (NKTLoupe *)bandLoupe
{    
    if (bandLoupe_ == nil)
    {
        bandLoupe_ = [[NKTLoupe alloc] initWithStyle:NKTLoupeStyleBand];
        bandLoupe_.hidden = YES;
        bandLoupe_.zoomedView = self;
        
        if ([self.delegate respondsToSelector:@selector(loupeFillColor)])
        {
            bandLoupe_.fillColor = [self.delegate loupeFillColor];
        }
        
        if ([self.delegate respondsToSelector:@selector(addLoupeView:)])
        {
            [self.delegate addLoupe:bandLoupe_];
        }
        else
        {
            [self.superview addSubview:bandLoupe_];
        }
    }
    
    return bandLoupe_;
}

- (NKTLoupe *)roundLoupe
{
    if (roundLoupe_ == nil)
    {
        roundLoupe_ = [[NKTLoupe alloc] initWithStyle:NKTLoupeStyleRound];
        roundLoupe_.hidden = YES;
        roundLoupe_.zoomedView = self;

        if ([self.delegate respondsToSelector:@selector(loupeFillColor)])
        {
            roundLoupe_.fillColor = [self.delegate loupeFillColor];
        }
        
        if ([self.delegate respondsToSelector:@selector(addLoupeView:)])
        {
            [self.delegate addLoupe:roundLoupe_];
        }
        else
        {
            [self.superview addSubview:roundLoupe_];
        }
    }
    
    return roundLoupe_;
}

- (void)showLoupe:(NKTLoupe *)loupe atPoint:(CGPoint)point anchorToLine:(BOOL)anchorToLine
{
    if (anchorToLine)
    {
        NKTLine *line = [self closestLineContainingPoint:point];
        CGPoint lineOrigin = [self originForLineAtIndex:line.index];
        CGPoint zoomCenter = CGPointMake(point.x, lineOrigin.y);
        loupe.zoomCenter = [self convertPoint:zoomCenter toView:loupe.zoomedView];
        
        CGPoint anchor = CGPointMake(point.x, lineOrigin.y - (lineHeight * 0.8));
        anchor = KBCClampPointToRect(anchor, self.bounds);
        loupe.anchor = [self convertPoint:anchor toView:loupe.superview];
    }
    else
    {
        loupe.zoomCenter = [self convertPoint:point toView:loupe.zoomedView];;
        
        CGPoint anchor = KBCClampPointToRect(point, self.bounds);
        loupe.anchor = [self convertPoint:anchor toView:loupe.superview];
    }
    
    [loupe setHidden:NO animated:YES];
}

- (void)showLoupe:(NKTLoupe *)loupe atTextPosition:(NKTTextPosition *)textPosition
{    
    NKTLine *line = [self lineContainingTextPosition:textPosition];
    CGPoint lineOrigin = [self originForLineAtIndex:line.index];
    CGFloat charOffset = [line offsetForCharAtTextPosition:textPosition];
    
    CGPoint zoomCenter = CGPointMake(margins.left + charOffset, lineOrigin.y);
    loupe.zoomCenter = [self convertPoint:zoomCenter toView:loupe.zoomedView];
    
    CGPoint anchor = CGPointMake(margins.left + charOffset, lineOrigin.y - (lineHeight * 0.8));
    anchor = KBCClampPointToRect(anchor, self.bounds);
    loupe.anchor = [self convertPoint:anchor toView:loupe.superview];

    [loupe setHidden:NO animated:YES];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Inserting and Deleting Text

- (BOOL)hasText
{
    return [text length] > 0;
}

- (void)insertText:(NSString *)theText
{
    if (markedTextRange == nil && selectedTextRange == nil)
    {
        KBCLogWarning(@"marked text range and selected text range are nil, ignoring");
        return;
    }
    
    NKTTextRange *insertionTextRange = nil;
    
    if (markedTextRange != nil)
    {
        insertionTextRange = markedTextRange;
    }
    else
    {
        insertionTextRange = selectedTextRange;
    }
    
    [text replaceCharactersInRange:insertionTextRange.nsRange withString:theText];
    [self regenerateContents];
    
    NKTTextPosition *textPosition = [insertionTextRange.start textPositionByApplyingOffset:[theText length]];
    [self setMarkedTextRange:nil];
    [self setSelectedTextRange:[textPosition textRange]];
}

- (void)deleteBackward
{
    if (markedTextRange == nil && selectedTextRange == nil)
    {
        KBCLogWarning(@"marked text range and selected text range are nil, ignoring");
        return;
    }
    
    NKTTextRange *deletionTextRange = nil;
    
    // TODO: why can't we just use the selected text range?
    if (markedTextRange != nil)
    {
        deletionTextRange = [markedTextRange textRangeByGrowingLeft];
    }
    else
    {
        deletionTextRange = [selectedTextRange textRangeByGrowingLeft];
    }
    
    [text deleteCharactersInRange:deletionTextRange.nsRange];
    [self regenerateContents];
    
    // The marked text range no longer exists
    [self setMarkedTextRange:nil];
    [self setSelectedTextRange:[deletionTextRange.start textRange]];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Replacing and Returning Text

- (NSString *)textInRange:(NKTTextRange *)textRange
{
    return [[text string] substringWithRange:textRange.nsRange];
}

- (void)replaceRange:(NKTTextRange *)textRange withText:(NSString *)replacementText
{
    [text replaceCharactersInRange:textRange.nsRange withString:replacementText];
    [self regenerateContents];
    
    // The text range to be replaced lies fully before the selected text range
    if (textRange.end.index <= selectedTextRange.start.index)
    {
        NSInteger charChangeCount = [replacementText length] - textRange.length;
        NSUInteger newStartIndex = selectedTextRange.start.index + charChangeCount;
        NKTTextRange *newTextRange = [selectedTextRange textRangeByReplacingStartIndexWithIndex:newStartIndex];
        [self setSelectedTextRange:newTextRange];
    }
    // The text range overlaps the selected text range
    else if (textRange.start.index >= selectedTextRange.start.index && textRange.start.index < selectedTextRange.end.index)
    {
        NSUInteger newLength = textRange.start.index - selectedTextRange.start.index;
        NKTTextRange *newTextRange = [NKTTextRange textRangeWithTextPosition:selectedTextRange.start length:newLength];
        [self setSelectedTextRange:newTextRange];
    }
}

//--------------------------------------------------------------------------------------------------

#pragma mark Working with Marked and Selected Text

- (UITextRange *)selectedTextRange
{
    return selectedTextRange;
}

- (void)setSelectedTextRange:(NKTTextRange *)newSelectedTextRange
{
    [selectedTextRange autorelease];
    selectedTextRange = [newSelectedTextRange copy];
    [selectionDisplayController_ selectedTextRangeDidChange];
}

- (UITextRange *)provisionalTextRange
{
    return provisionalTextRange_;
}

- (void)setProvisionalTextRange:(NKTTextRange *)provisionalTextRange
{
    if ([provisionalTextRange_ isEqualToTextRange:provisionalTextRange])
    {
        return;
    }
    
    [provisionalTextRange retain];
    [provisionalTextRange_ release];
    provisionalTextRange_ = provisionalTextRange;
    [selectionDisplayController_ provisionalTextRangeDidChange];
}

- (void)confirmProvisionalTextRange
{
    NKTTextRange *provisionalTextRange = (NKTTextRange *)self.provisionalTextRange;
    [provisionalTextRange retain];
    self.provisionalTextRange = nil;
    [inputDelegate selectionWillChange:self];
    self.selectedTextRange = provisionalTextRange;
    [inputDelegate selectionDidChange:self];
    [provisionalTextRange release];
}

- (UITextRange *)markedTextRange
{
    return markedTextRange;
}

- (NSDictionary *)markedTextStyle
{
    return markedTextStyle;
}

- (void)setMarkedTextStyle:(NSDictionary *)newMarkedTextStyle
{
    if (markedTextStyle == newMarkedTextStyle)
    {
        return;
    }
    
    [markedTextStyle release];
    markedTextStyle = [newMarkedTextStyle copy];
}

- (void)setMarkedTextRange:(NKTTextRange *)newMarkedTextRange
{
    [markedTextRange autorelease];
    markedTextRange = [newMarkedTextRange copy];
    [selectionDisplayController_ markedTextRangeDidChange];
}

- (void)setMarkedText:(NSString *)newMarkedText selectedRange:(NSRange)relativeSelectedRange
{
    [markedText autorelease];
    markedText = [newMarkedText copy];
    
    if (markedText == nil)
    {
        markedText = @"";
    }

    // Replace the current marked text
    if (markedTextRange != nil)
    {
        [text replaceCharactersInRange:markedTextRange.nsRange withString:markedText];
        [self regenerateContents];
        NKTTextRange *textRange = [NKTTextRange textRangeWithTextPosition:markedTextRange.start length:[markedText length]];
        [self setMarkedTextRange:textRange];
    }
    else
    {
        [text replaceCharactersInRange:selectedTextRange.nsRange withString:markedText];
        [self regenerateContents];
        NKTTextRange *textRange = [NKTTextRange textRangeWithTextPosition:selectedTextRange.start length:[markedText length]];
        [self setMarkedTextRange:textRange];
    }
    
    // Update the selected text range within the marked text
    NSUInteger newIndex = markedTextRange.start.index + relativeSelectedRange.location;
    NKTTextRange *newTextRange = [NKTTextRange textRangeWithIndex:newIndex length:relativeSelectedRange.length];
    [self setSelectedTextRange:newTextRange];
}

- (void)unmarkText
{
    [self setMarkedTextRange:nil];
    [markedText release];
    markedText = nil;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Computing Text Ranges and Text Positions

- (UITextRange *)textRangeFromPosition:(NKTTextPosition *)fromPosition toPosition:(NKTTextPosition *)toPosition
{    
    return [fromPosition textRangeUntilTextPosition:toPosition];
}

- (UITextPosition *)positionFromPosition:(NKTTextPosition *)textPosition offset:(NSInteger)offset
{    
    NSInteger index = (NSInteger)textPosition.index + offset;
    
    if (index < 0 || index > [text length])
    {
        return nil;
    }
    
    return [NKTTextPosition textPositionWithIndex:index];
}

- (UITextPosition *)positionFromPosition:(NKTTextPosition *)textPosition inDirection:(UITextLayoutDirection)direction offset:(NSInteger)offset
{
    NKTTextPosition *offsetTextPosition = nil;
    
    switch (direction)
    {
        case UITextLayoutDirectionRight:
        {
            offsetTextPosition = (NKTTextPosition *)[self positionFromPosition:textPosition offset:offset];
            break;
        }
        case UITextLayoutDirectionLeft:
        {
            offsetTextPosition = (NKTTextPosition *)[self positionFromPosition:textPosition offset:-offset];
            break;
        }
        case UITextLayoutDirectionUp:
        {
            CGRect caretFrame = [self caretRectForPosition:textPosition];
            CGPoint pointAboveCaret = caretFrame.origin;
            pointAboveCaret.y += (0.5 * lineHeight);
            pointAboveCaret.y -= ((CGFloat)offset * lineHeight);
            offsetTextPosition = (NKTTextPosition *)[self closestPositionToPoint:pointAboveCaret];
            break;
        }
        case UITextLayoutDirectionDown:
        {
            CGRect caretFrame = [self caretRectForPosition:textPosition];
            CGPoint pointAboveCaret = caretFrame.origin;
            pointAboveCaret.y += (0.5 * lineHeight);
            pointAboveCaret.y += ((CGFloat)offset * lineHeight);
            offsetTextPosition = (NKTTextPosition *)[self closestPositionToPoint:pointAboveCaret];
            break;
        }
    }
    
    return offsetTextPosition;
}

- (UITextPosition *)beginningOfDocument
{
    return [NKTTextPosition textPositionWithIndex:0];
}

- (UITextPosition *)endOfDocument
{
    return [NKTTextPosition textPositionWithIndex:[text length]];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Evaluating Text Positions

- (NSComparisonResult)comparePosition:(NKTTextPosition *)textPosition toPosition:(NKTTextPosition *)otherTextPosition
{
    if (textPosition.index < otherTextPosition.index)
    {
        return NSOrderedAscending;
    }
    else if (textPosition.index > otherTextPosition.index)
    {
        return NSOrderedDescending;
    }
    else
    {
        return NSOrderedSame;
    }
}

- (NSInteger)offsetFromPosition:(NKTTextPosition *)fromPosition toPosition:(NKTTextPosition *)toPosition
{
    return (toPosition.index - fromPosition.index);
}

//--------------------------------------------------------------------------------------------------

#pragma mark Determining Layout and Writing Direction

- (UITextPosition *)positionWithinRange:(NKTTextRange *)textRange farthestInDirection:(UITextLayoutDirection)direction
{
    NKTTextPosition *textPosition = nil;
    
    switch (direction)
    {
        case UITextLayoutDirectionRight:
        {
            textPosition = textRange.end;
            break;
        }
        case UITextLayoutDirectionLeft:
        {
            textPosition = textRange.start;
            break;
        }
        case UITextLayoutDirectionUp:
        {
            textPosition = textRange.start;
            break;
        }
        case UITextLayoutDirectionDown:
        {
            textPosition = textRange.end;
            break;
        }
    }
    
    return textPosition;
}

- (UITextRange *)characterRangeByExtendingPosition:(NKTTextPosition *)textPosition inDirection:(UITextLayoutDirection)direction
{
    UITextRange *textRange = nil;
    
    switch (direction)
    {
        case UITextLayoutDirectionRight:
        {
            NKTLine *line = [self lineContainingTextPosition:textPosition];
            textRange = [textPosition textRangeUntilTextPosition:line.textRange.end];
            break;
        }
        case UITextLayoutDirectionLeft:
        {
            NKTLine *line = [self lineContainingTextPosition:textPosition];
            textRange = [textPosition textRangeUntilTextPosition:line.textRange.start];
            break;
        }
        case UITextLayoutDirectionUp:
        {
            textRange = [textPosition textRangeUntilTextPosition:(NKTTextPosition *)[self beginningOfDocument]];
            break;
        }
        case UITextLayoutDirectionDown:
        {
            textRange = [textPosition textRangeUntilTextPosition:(NKTTextPosition *)[self endOfDocument]];
            break;
        }
    }
    
    return textRange;
}

- (UITextWritingDirection)baseWritingDirectionForPosition:(NKTTextPosition *)textPosition inDirection:(UITextStorageDirection)direction
{
    UITextWritingDirection writingDirection = UITextWritingDirectionLeftToRight;
    CTParagraphStyleRef paragraphStyle = (CTParagraphStyleRef)[text attribute:(id)kCTParagraphStyleAttributeName atIndex:textPosition.index effectiveRange:NULL];
    
    if (paragraphStyle != NULL)
    {        
        CTParagraphStyleGetValueForSpecifier(paragraphStyle,
                                             kCTParagraphStyleSpecifierBaseWritingDirection,
                                             sizeof(CTWritingDirection), &writingDirection);
    }
    
    return writingDirection;
}

- (void)setBaseWritingDirection:(UITextWritingDirection)writingDirection forRange:(NKTTextRange *)textRange
{
    // WTF ... this is one fucked up API
    CTParagraphStyleSetting settings[1];
    settings[0].spec = kCTParagraphStyleSpecifierBaseWritingDirection;
    settings[0].valueSize = sizeof(CTWritingDirection);
    settings[0].value = &writingDirection;
    
    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(settings, 1);
    NSDictionary *attributes = [NSDictionary dictionaryWithObject:(id)paragraphStyle forKey:(id)kCTParagraphStyleAttributeName];
    CFRelease(paragraphStyle);
    // TODO: This should really be an attribute merge right?
    [text addAttributes:attributes range:textRange.nsRange];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Geometry and Hit-Testing

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

- (CGRect)rectForLine:(NKTLine *)line
{
    CGFloat ascent = MIN(line.ascent, lineHeight);
    CGFloat height = MIN(line.ascent + line.descent, lineHeight);
    CGFloat width = self.bounds.size.width - margins.left - margins.right;
    CGPoint origin = [self originForLineAtIndex:line.index];
    const CGFloat heightPadding = 1.0;
    origin.y -= (ascent + heightPadding);
    return CGRectMake(origin.x, origin.y, width, height + (heightPadding * 2.0));
}

- (CGPoint)originForTextPosition:(NKTTextPosition *)textPosition
{
    NKTLine *line = [self lineContainingTextPosition:textPosition];
    CGPoint lineOrigin = [self originForLineAtIndex:line.index];
    CGFloat offset = [line offsetForCharAtTextPosition:textPosition];
    return CGPointMake(margins.left + offset, lineOrigin.y);
}

- (CGPoint)characterOriginForPosition:(NKTTextPosition *)textPosition
{
    CGPoint lineOrigin = CGPointZero;
    CGFloat charOffset = 0.0;
    
    // Use fake first line if no typesetted lines exist
    if ([typesettedLines count] == 0 || textPosition.index == 0)
    {
        lineOrigin = [self originForLineAtIndex:0];
    }
    // Text position beyond the end of the document, special handling required
    else if (textPosition.index >= [text length])
    {
        // Line break at end, so use origin of the line beyond the last typesetted one
        if ([[text string] hasSuffix:@"\n"])
        {
            lineOrigin = [self originForLineAtIndex:[typesettedLines count]];
        }
        // Last character is not a line break, use the last typesetted line
        else
        {
            NKTLine *lastLine = [typesettedLines objectAtIndex:[typesettedLines count] - 1];
            lineOrigin = [self originForLineAtIndex:lastLine.index];
            charOffset = [lastLine offsetForCharAtTextPosition:textPosition];
        }
    }
    // Text position within the bounds of the text
    else
    {
        NKTLine *line = [self lineContainingTextPosition:textPosition];
        lineOrigin = [self originForLineAtIndex:line.index];
        charOffset = [line offsetForCharAtTextPosition:textPosition];
    }
    
    return CGPointMake(lineOrigin.x + charOffset, lineOrigin.y);
}

- (NSArray *)rectsForTextRange:(NKTTextRange *)textRange
{
    NKTLine *firstLine = [self lineContainingTextPosition:textRange.start];
 
    // First line does not exist, so no rects exist
    if (firstLine == nil)
    {
        return nil;
    }
    
    NKTLine *lastLine = [self lineContainingTextPosition:textRange.end];
    
    // Use the last typesetted line if no line contains the end of the text range
    if (lastLine == nil)
    {
        lastLine = [typesettedLines objectAtIndex:[typesettedLines count] - 1];
    }
    
    // Dealing with a single rect
    if (firstLine == lastLine)
    {
        CGRect rect = [self rectForLine:firstLine];
        CGFloat charOffset = [firstLine offsetForCharAtTextPosition:textRange.start];
        rect.origin.x += charOffset;
        
        // Use entire line if end of the text range is a line break at the end of document
        if (textRange.end.index == [text length] && [[text string] hasSuffix:@"\n"])
        {
            rect.size.width -= charOffset;
        }
        else
        {
            CGFloat endOffset = [firstLine offsetForCharAtTextPosition:textRange.end];
            rect.size.width = endOffset - charOffset;
        }
        
        return [NSArray arrayWithObject:[NSValue valueWithCGRect:rect]];
    }
    
    // Multiple rects for text range
    NSMutableArray *rects = [[[NSMutableArray alloc] init] autorelease];
    
    // Rect for first line
    CGRect firstRect = [self rectForLine:firstLine];
    CGFloat firstCharOffset = [firstLine offsetForCharAtTextPosition:textRange.start];
    firstRect.origin.x += firstCharOffset;
    firstRect.size.width -= firstCharOffset;
    [rects addObject:[NSValue valueWithCGRect:firstRect]];
    
    // Rects for lines in between
    for (NSUInteger lineIndex = firstLine.index + 1; lineIndex < lastLine.index; ++lineIndex)
    {
        NKTLine *line = [typesettedLines objectAtIndex:lineIndex];
        CGRect rect = [self rectForLine:line];
        [rects addObject:[NSValue valueWithCGRect:rect]];
    }
    
    // Rect for last line
    CGRect lastRect = [self rectForLine:lastLine];
    
    // Use entire line if end of the text range is a line break at the end of document
    if (textRange.end.index != [text length] || ![[text string] hasSuffix:@"\n"])
    {
        CGFloat lastCharOffset = [lastLine offsetForCharAtTextPosition:textRange.end];
        lastRect.size.width = lastCharOffset;
    }
    
    [rects addObject:[NSValue valueWithCGRect:lastRect]];
    
    return rects;
}

- (CGRect)firstRectForRange:(NKTTextRange *)textRange
{
    NSArray *rects = [self rectsForTextRange:textRange];
    
    if (rects != nil)
    {
        return [[rects objectAtIndex:0] CGRectValue];
    }
    else
    {
        return CGRectZero;
    }
}

- (CGRect)caretRectForPosition:(UITextPosition *)textPosition
{
    // Ask the controller since it is the one doing the actual caret display
    return [selectionDisplayController_ caretRectForPosition:textPosition];
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point
{
    NSInteger virtualLineIndex = [self virtualIndexForLineContainingPoint:point];
    
    if (virtualLineIndex < 0 || [typesettedLines count] == 0)
    {
        return [NKTTextPosition textPositionWithIndex:0];
    }
    else if ((NSUInteger)virtualLineIndex >= [typesettedLines count])
    {
        return [NKTTextPosition textPositionWithIndex:[text length]];
    }
    else
    {
        NKTLine *line = [typesettedLines objectAtIndex:(NSUInteger)virtualLineIndex];
        CGPoint localPoint = [self convertPoint:point toLine:line];
        return [line closestTextPositionToPoint:localPoint];
    }
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point withinRange:(NKTTextRange *)textRange
{
    NKTTextPosition *textPosition = (NKTTextPosition *)[self closestPositionToPoint:point];
    
    if ([textRange containsTextPosition:textPosition])
    {
        return textPosition;
    }
    
    // The closest text position lies on either the line containing the start of the text range or
    // the line containing the end of the text range
    NKTLine *firstLine = [self lineContainingTextPosition:textRange.start];
    
    if (firstLine == nil)
    {
        return textRange.start;
    }
    
    CGPoint firstLineOrigin = [self originForLineAtIndex:firstLine.index];
    CGPoint localPoint = CGPointMake(point.x - margins.left, 0.0);
    
    if (point.y <= firstLineOrigin.y)
    {
        return [firstLine closestTextPositionToPoint:localPoint withinRange:textRange];
    }
    else
    {
        NKTLine *lastLine = [self lineContainingTextPosition:textRange.end];
        
        if (lastLine == nil)
        {
            lastLine = [typesettedLines objectAtIndex:[typesettedLines count] - 1];
        }
        
        return [lastLine closestTextPositionToPoint:localPoint withinRange:textRange];    
    }
}

- (UITextRange *)characterRangeAtPoint:(CGPoint)point
{
    NKTTextPosition *textPosition = (NKTTextPosition *)[self closestPositionToPoint:point];
    return [textPosition textRange];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Text Input Delegate and Text Input Tokenizer

- (id <UITextInputTokenizer>)tokenizer
{
    if (tokenizer == nil)
    {
        tokenizer = [[UITextInputStringTokenizer alloc] initWithTextInput:self];
    }
    
    return tokenizer;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Returning Text Styling Information

- (NSDictionary *)textStylingAtPosition:(NKTTextPosition *)textPosition inDirection:(UITextStorageDirection)direction
{
    UIFont *textFont = [self fontAtTextPosition:textPosition];
    UIColor *textColor = [UIColor blackColor];
    UIColor *textBackgroundColor = self.backgroundColor;
    return [NSDictionary dictionaryWithObjectsAndKeys:textBackgroundColor, UITextInputTextBackgroundColorKey,
                                                      textColor, UITextInputTextColorKey,
                                                      textFont, UITextInputTextFontKey, nil];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Returning the Text Input View

- (UIView *)textInputView
{
    return self;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Managing Selection Views

- (void)addUnderlayView:(UIView *)view
{
    [self insertSubview:view atIndex:[underlayViews count]];
    [underlayViews addObject:view];
}

- (void)addOverlayView:(UIView *)view
{
    [self insertSubview:view atIndex:[underlayViews count] + [visibleSections count]];
    [overlayViews addObject:view];
}

@end
