//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTTextView.h"
#import "KobaText.h"
#import "NKTDragGestureRecognizer.h"
#import "NKTLine.h"
#import "NKTLoupe.h"
#import "NKTTextPosition.h"
#import "NKTTextRange.h"
#import "NKTTextSection.h"
#import "NKTTextViewGestureRecognizerDelegate.h"
#import "NKTTextViewTokenizer.h"

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

- (BOOL)indexAddressesNonTypesettedLine:(NSUInteger)lineIndex;
- (NSUInteger)lastLineIndex;
- (NSUInteger)indexForLineContainingTextPosition:(NKTTextPosition *)textPosition;

#pragma mark Managing Loupes

@property (nonatomic, readonly) NKTLoupe *bandLoupe;
@property (nonatomic, readonly) NKTLoupe *roundLoupe;

- (void)configureLoupe:(NKTLoupe *)loupe toMagnifyPoint:(CGPoint)point anchorToClosestLine:(BOOL)anchorToLine;
- (void)configureLoupe:(NKTLoupe *)loupe toMagnifyTextPosition:(NKTTextPosition *)textPosition;

#pragma mark Working with Marked and Selected Text

- (void)setProvisionalTextRange:(NKTTextRange *)provisionalTextRange;
- (void)confirmProvisionalTextRange;
- (void)setSelectedTextRange:(NKTTextRange *)selectedTextRange notifyInputDelegate:(BOOL)notifyInputDelegate;
- (void)setMarkedTextRange:(NKTTextRange *)markedTextRange;

#pragma mark Geometry and Hit-Testing

- (UITextPosition *)closestTextPositionToPoint:(CGPoint)point onLineAtIndex:(NSUInteger)index;
- (CGPoint)originForLineAtIndex:(NSUInteger)index;
- (CGPoint)convertPoint:(CGPoint)point toLine:(NKTLine *)line;
- (CGPoint)convertPoint:(CGPoint)point toLineAtIndex:(NSUInteger)index;
- (CGPoint)originForCharAtTextPosition:(NKTTextPosition *)textPosition;
- (CGRect)caretRectWithOrigin:(CGPoint)origin font:(UIFont *)font;

#pragma mark Getting Fonts at Text Positions

- (UIFont *)fontAtTextPosition:(NKTTextPosition *)textPosition inDirection:(UITextStorageDirection)direction;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------

@implementation NKTTextView

@synthesize text = text_;

@synthesize margins = margins_;
@synthesize lineHeight = lineHeight_;

@synthesize horizontalRulesEnabled = horizontalRulesEnabled_;
@synthesize horizontalRuleColor = horizontalRuleColor_;
@synthesize horizontalRuleOffset = horizontalRuleOffset_;
@synthesize verticalMarginEnabled = verticalMarginEnabled_;
@synthesize verticalMarginColor = verticalMarginColor_;
@synthesize verticalMarginInset = verticalMarginInset_;

@synthesize inputTextAttributes = inputTextAttributes_;

@synthesize inputDelegate = inputDelegate_;

@synthesize nonEditTapGestureRecognizer = nonEditTapGestureRecognizer_;
@synthesize tapGestureRecognizer = tapGestureRecognizer_;
@synthesize longPressGestureRecognizer = longPressGestureRecognizer_;
@synthesize doubleTapAndDragGestureRecognizer = doubleTapAndDragGestureRecognizer_;
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
    
    text_ = [[NSMutableAttributedString alloc] init];
    
    margins_ = UIEdgeInsetsMake(60.0, 80.0, 80.0, 60.0);
    lineHeight_ = 32.0;
    //margins = UIEdgeInsetsMake(90.0, 90.0, 120.0, 90.0);
    //lineHeight = 30.0;
    
    horizontalRulesEnabled_ = YES;
    horizontalRuleColor_ = [[UIColor colorWithRed:0.72 green:0.72 blue:0.59 alpha:1.0] retain];
    //horizontalRuleColor_ = [[UIColor colorWithRed:0.78 green:0.78 blue:0.65 alpha:1.0] retain];
    horizontalRuleOffset_ = 3.0;
    verticalMarginEnabled_ = YES;
    verticalMarginColor_ = [[UIColor colorWithRed:0.7 green:0.3 blue:0.29 alpha:1.0] retain];
    verticalMarginInset_ = 60.0;
    
    visibleSections_ = [[NSMutableSet alloc] init];
    reusableSections_ = [[NSMutableSet alloc] init];    
    underlayViews_ = [[NSMutableSet alloc] init];
    overlayViews = [[NSMutableSet alloc] init];
    
    selectionDisplayController_ = [[NKTSelectionDisplayController alloc] init];
    selectionDisplayController_.delegate = self;
    
    [self createGestureRecognizers];
}

- (void)createGestureRecognizers
{
    gestureRecognizerDelegate_ = [[NKTTextViewGestureRecognizerDelegate alloc] initWithTextView:self];
    
    doubleTapAndDragGestureRecognizer_ = [[NKTDragGestureRecognizer alloc] initWithTarget:self
                                                                                   action:@selector(handleDoubleTapAndDrag:)];
    doubleTapAndDragGestureRecognizer_.delegate = gestureRecognizerDelegate_;
    
    nonEditTapGestureRecognizer_ = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                           action:@selector(handleTap:)];
    nonEditTapGestureRecognizer_.delegate = gestureRecognizerDelegate_;
    [nonEditTapGestureRecognizer_ requireGestureRecognizerToFail:doubleTapAndDragGestureRecognizer_];
    
    tapGestureRecognizer_ = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                    action:@selector(handleTap:)];
    tapGestureRecognizer_.delegate = gestureRecognizerDelegate_;
    
    longPressGestureRecognizer_ = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                action:@selector(handleLongPress:)];
    longPressGestureRecognizer_.delegate = gestureRecognizerDelegate_;
    
    [self addGestureRecognizer:tapGestureRecognizer_];
    [self addGestureRecognizer:nonEditTapGestureRecognizer_];
    [self addGestureRecognizer:longPressGestureRecognizer_];
    [self addGestureRecognizer:doubleTapAndDragGestureRecognizer_];
}

- (void)dealloc
{
    [text_ release];
    
    [horizontalRuleColor_ release];
    [verticalMarginColor_ release];
    
    [typesettedLines_ release];
    
    [visibleSections_ release];
    [reusableSections_ release];
    [underlayViews_ release];
    [overlayViews release];
    
    [inputTextAttributes_ release];
    
    [selectedTextRange_ release];
    [markedTextRange_ release];
    [markedTextStyle_ release];
    [markedText_ release];
    [provisionalTextRange_ release];
    
    [tokenizer_ release];
    
    [selectionDisplayController_ release];
    [bandLoupe_ release];
    [roundLoupe_ release];
    
    [gestureRecognizerDelegate_ release];
    [nonEditTapGestureRecognizer_ release];
    [tapGestureRecognizer_ release];
    [longPressGestureRecognizer_ release];
    [doubleTapAndDragGestureRecognizer_ release];
    [doubleTapStartTextPosition_ release];
    
    [super dealloc];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Updating the Content Size

- (void)updateContentSize
{
    CGSize size = self.bounds.size;
    size.height = ((CGFloat)[typesettedLines_ count] *  lineHeight_) + margins_.top + margins_.bottom;
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

- (void)setText:(NSMutableAttributedString *)text
{
    [text retain];
    [text_ release];
    text_ = text;
    [self regenerateContents];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Configuring Text Layout and Style

- (void)setMargins:(UIEdgeInsets)margins
{
    if (UIEdgeInsetsEqualToEdgeInsets(margins_, margins))
    {
        return;
    }
    
    margins_ = margins;
    [self regenerateContents];
    [selectionDisplayController_ updateSelectionElements];
}

- (void)setLineHeight:(CGFloat)lineHeight 
{
    lineHeight_ = lineHeight;
    // Don't need to typeset lines because the line width is not changing
    [self untileVisibleSections];
    [self tileSections];
    [self updateContentSize];
    [selectionDisplayController_ updateSelectionElements];
}

- (void)setHorizontalRulesEnabled:(BOOL)horizontalRulesEnabled
{
    if (horizontalRulesEnabled_ == horizontalRulesEnabled)
    {
        return;
    }
    
    horizontalRulesEnabled_ = horizontalRulesEnabled;
    [self untileVisibleSections];
    [self tileSections];
    [selectionDisplayController_ updateSelectionElements];
}

- (void)setHorizontalRuleColor:(UIColor *)horizontalRuleColor
{
    if (horizontalRuleColor_ == horizontalRuleColor)
    {
        return;
    }
    
    [horizontalRuleColor_ release];
    horizontalRuleColor_ = [horizontalRuleColor retain];
    [self untileVisibleSections];
    [self tileSections];
    [selectionDisplayController_ updateSelectionElements];
}

- (void)setHorizontalRuleOffset:(CGFloat)horizontalRuleOffset
{
    if (horizontalRuleOffset_ == horizontalRuleOffset)
    {
        return;
    }
    
    horizontalRuleOffset_ = horizontalRuleOffset;
    [self untileVisibleSections];
    [self tileSections];
    [selectionDisplayController_ updateSelectionElements];
}

- (void)setVerticalMarginEnabled:(BOOL)verticalMarginEnabled
{
    if (verticalMarginEnabled_ == verticalMarginEnabled)
    {
        return;
    }
    
    verticalMarginEnabled_ = verticalMarginEnabled;
    [self untileVisibleSections];
    [self tileSections];
    [selectionDisplayController_ updateSelectionElements];
}

- (void)setVerticalMarginColor:(UIColor *)verticalMarginColor
{
    if (verticalMarginColor_ == verticalMarginColor)
    {
        return;
    }
    
    [verticalMarginColor_ release];
    verticalMarginColor_ = [verticalMarginColor retain];
    [self untileVisibleSections];
    [self tileSections];
    [selectionDisplayController_ updateSelectionElements];
}

- (void)setVerticalMarginInset:(CGFloat)verticalMarginInset
{
    if (verticalMarginInset_ == verticalMarginInset)
    {
        return;
    }
    
    verticalMarginInset_ = verticalMarginInset;
    [self untileVisibleSections];
    [self tileSections];
    [selectionDisplayController_ updateSelectionElements];
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
    [typesettedLines_ release];
    typesettedLines_ = nil;
    
    if ([text_ length] == 0)
    {
        return;
    }
    
    typesettedLines_ = [[NSMutableArray alloc] init];
    CTTypesetterRef typesetter = CTTypesetterCreateWithAttributedString((CFAttributedStringRef)text_);
    CFIndex length = (CFIndex)[text_ length];
    CGFloat lineWidth = CGRectGetWidth(self.bounds) - (margins_.left + margins_.right);
    CFIndex charIndex = 0;
    NSUInteger lineIndex = 0;
    
    while (charIndex < length)
    {
        CFIndex charCount = CTTypesetterSuggestLineBreak(typesetter, charIndex, lineWidth);
        CFRange range = CFRangeMake(charIndex, charCount);
        CTLineRef ctLine = CTTypesetterCreateLine(typesetter, range);
        NKTLine *line = [[NKTLine alloc] initWithIndex:lineIndex text:text_ ctLine:ctLine];
        CFRelease(ctLine);
        [typesettedLines_ addObject:line];
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
    for (NKTTextSection *section in visibleSections_)
    {
        if (section.index < firstVisibleSectionIndex || section.index > lastVisibleSectionIndex)
        {
            [reusableSections_ addObject:section];
            [section removeFromSuperview];
        }
    }
    
    [visibleSections_ minusSet:reusableSections_];
    
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
            NSUInteger insertionIndex = [underlayViews_ count];
            [self insertSubview:section atIndex:insertionIndex];
            [visibleSections_ addObject:section];
        }
    }
}

- (void)untileVisibleSections
{
    for (NKTTextSection *section in visibleSections_)
    {
        [reusableSections_ addObject:section];
        [section removeFromSuperview];
    }
    
    [visibleSections_ removeAllObjects];
}

- (BOOL)isDisplayingSectionAtIndex:(NSInteger)index
{
    for (NKTTextSection *section in visibleSections_)
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
    NKTTextSection *section = [reusableSections_ anyObject];
    
    if (section != nil)
    {
        [[section retain] autorelease];
        [reusableSections_ removeObject:section];
        return section;
    }
    
    return nil;
}

- (void)configureSection:(NKTTextSection *)section atIndex:(NSInteger)index
{
    section.frame = [self frameForSectionAtIndex:index];
    section.index = index;
    section.typesettedLines = typesettedLines_;
    section.margins = margins_;
    section.lineHeight = lineHeight_;
    section.horizontalRulesEnabled = horizontalRulesEnabled_;
    section.horizontalRuleColor = horizontalRuleColor_;
    section.horizontalRuleOffset = horizontalRuleOffset_;
    section.verticalMarginEnabled = verticalMarginEnabled_;
    section.verticalMarginColor = verticalMarginColor_;
    section.verticalMarginInset = verticalMarginInset_;
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
    
    [self setSelectedTextRange:nil notifyInputDelegate:NO];
    selectionDisplayController_.caretVisible = NO;

    if ([self.delegate respondsToSelector:@selector(textViewDidEndEditing:)])
    {
        [self.delegate textViewDidEndEditing:self];
    }
    
    return YES;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Responding to Gestures

- (void)handleTap:(UIGestureRecognizer *)gestureRecognizer
{
    BOOL becameFirstResponder = NO;
    
    // Make sure the view is the first responder
    if (![self isFirstResponder])
    {
        if ([self becomeFirstResponder])
        {
            becameFirstResponder = YES;
        }
        else
        {
            return;
        }
    }
    
    // When first responder status is accepted, the caret needs to be visible
    selectionDisplayController_.caretVisible = YES;
    
    CGPoint touchLocation = [gestureRecognizer locationInView:self];
    NKTTextPosition *textPosition = (NKTTextPosition *)[self closestPositionToPoint:touchLocation];
    
    if ([selectedTextRange_ isEqualToTextPosition:textPosition])
    {
        return;
    }
    
    [self setSelectedTextRange:[textPosition textRange] notifyInputDelegate:YES];
    
    // When the tapped text position is outside the marked text range, the marked text loses its
    // provisional status
    if (![markedTextRange_ containsTextPosition:textPosition])
    {
        self.markedTextRange = nil;
    }
    
    // Only inform the delegate that editing started after the selection has been set
    if (becameFirstResponder && [self.delegate respondsToSelector:@selector(textViewDidBeginEditing:)])
    {
        [self.delegate textViewDidBeginEditing:self];        
    }
}

- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer
{    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan ||
        gestureRecognizer.state == UIGestureRecognizerStateChanged)
    {
        CGPoint touchLocation = [gestureRecognizer locationInView:self];
        NKTTextPosition *textPosition = nil;
        
        // Computed text position depends on whether there is marked text or not
        if (markedTextRange_ != nil && !markedTextRange_.empty)
        {
            // TODO: this probably shouldn't use the method below for finding closest positions?
            textPosition = (NKTTextPosition *)[self closestPositionToPoint:touchLocation withinRange:markedTextRange_];
            [self configureLoupe:self.bandLoupe toMagnifyTextPosition:textPosition];
            [self.bandLoupe setHidden:NO animated:YES];
        }
        else
        {
            textPosition = (NKTTextPosition *)[self closestPositionToPoint:touchLocation];
            [self configureLoupe:self.roundLoupe toMagnifyPoint:touchLocation anchorToClosestLine:NO];
            [self.roundLoupe setHidden:NO animated:YES];
        }
        
        self.provisionalTextRange = [textPosition textRange];
        selectionDisplayController_.caretVisible = YES;
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
        self.provisionalTextRange = [textPosition textRange];
    }
    else if (gestureRecognizer.state == UIGestureRecognizerStateChanged)
    {
        [self configureLoupe:self.bandLoupe toMagnifyPoint:touchLocation anchorToClosestLine:YES];
        [self.bandLoupe setHidden:NO animated:YES];
        NKTTextRange *textRange = [self.doubleTapStartTextPosition textRangeWithTextPosition:textPosition];
        self.provisionalTextRange = textRange;
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

// Line indices used within the text view may not actually address a physical typesetted line in
// certain cases (e.g. a fake virtual line added after a line break at the end of the text). This
// method checks to see if an index being used is for such a line, in which case the caller can
// perform some alternative computation.
//
- (BOOL)indexAddressesNonTypesettedLine:(NSUInteger)lineIndex
{
    return lineIndex >= [typesettedLines_ count];
}

// Returns the index of the last typesetted line.
//
// This method should only be called if the caller is sure that there is at least one typesetted
// line.
//
- (NSUInteger)lastTypesettedLineIndex
{
    if ([typesettedLines_ count] == 0)
    {
        KBCLogWarning(@"no typesetted lines exist, returning 0");
        return 0;
    }
    
    return [typesettedLines_ count] - 1;
}

// Returns the last line index.
//
// The last line index may is one beyond the last typesetted line index if the text ends with a
// line break. Otherwise, the last line index is the same as the last typesetted line index.
//
- (NSUInteger)lastLineIndex
{
    // Line break at end - return the line beyond the last typesetted line
    if ([[text_ string] hasSuffix:@"\n"])
    {
        return [typesettedLines_ count];
    }
    // Last character is not a line break - return the last typesetted line
    else
    {
        return [typesettedLines_ count] - 1;
    }
}

// Returns the index for the line that 'appears' to contain the specified text position.
//
// In most cases, the line that 'appears' to contain the text position will be the typesetted line
// whose text range contains the text position.
//
// However, if the text position is beyond the range of the text (and thus, any typesetted lines),
// the index returned will be the last line index.
//
- (NSUInteger)indexForLineContainingTextPosition:(NKTTextPosition *)textPosition
{
    // No typesetted lines
    if ([typesettedLines_ count] == 0)
    {
        return 0;
    }
    // Text position beyond the range of any typesetted line
    else if (textPosition.index >= [text_ length])
    {
        return [self lastLineIndex];
    }
    // A typesetted line contains the text position
    else
    {
        for (NKTLine *line in typesettedLines_)
        {
            if ([line.textRange containsTextPosition:textPosition])
            {
                return line.index;
            }
        }
    }
    
    KBCLogWarning(@"expected a typesetted line to contain text position %d, but none do. returning last line index",
                  textPosition.index);
    return [typesettedLines_ count] - 1;
}

// Returns the index for the closest line to a point specified in view space.
//
- (NSUInteger)indexForClosestLineToPoint:(CGPoint)point
{
    // Assuming a uniform line height, the index of the line that would contain point can be
    // computed with simple arithmetic
    NSInteger virtualLineIndex = (NSInteger)floor((point.y - margins_.top) / lineHeight_);
    
    if (virtualLineIndex < 0)
    {
        return 0;
    }
    else if ((NSUInteger)virtualLineIndex > [self lastLineIndex])
    {
        return [self lastLineIndex];
    }
    else
    {
        return (NSUInteger)virtualLineIndex;
    }
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

- (void)configureLoupe:(NKTLoupe *)loupe toMagnifyPoint:(CGPoint)point anchorToClosestLine:(BOOL)anchorToLine
{
    if (anchorToLine)
    {
        // Set the zoom center of the loupe to the baseline with the same offset as the original point
        NSUInteger lineIndex = [self indexForClosestLineToPoint:point];
        CGPoint lineOrigin = [self originForLineAtIndex:lineIndex];
        CGPoint zoomCenter = CGPointMake(point.x, lineOrigin.y);
        loupe.zoomCenter = [self convertPoint:zoomCenter toView:loupe.zoomedView];
        // Anchor loupe to a point just on top of the line with the same offset as the original point
        CGPoint anchor = CGPointMake(point.x, lineOrigin.y - (lineHeight_ * 0.8));
        anchor = KBCClampPointToRect(anchor, self.bounds);
        loupe.anchor = [self convertPoint:anchor toView:loupe.superview];
    }
    else
    {
        // No adjusting of point, just use it as both the zoom center and anchor
        loupe.zoomCenter = [self convertPoint:point toView:loupe.zoomedView];;
        CGPoint anchor = KBCClampPointToRect(point, self.bounds);
        loupe.anchor = [self convertPoint:anchor toView:loupe.superview];
    }
    
    [loupe setHidden:NO animated:YES];
}

- (void)configureLoupe:(NKTLoupe *)loupe toMagnifyTextPosition:(NKTTextPosition *)textPosition
{
    CGPoint sourcePoint = [self originForCharAtTextPosition:textPosition];
    loupe.zoomCenter = [self convertPoint:sourcePoint toView:loupe.zoomedView];
    // Anchor loupe to a point just on top of the text position, clamped to the bounds rect
    CGPoint anchor = CGPointMake(sourcePoint.x, sourcePoint.y - (lineHeight_ * 0.8));
    anchor = KBCClampPointToRect(anchor, self.bounds);
    loupe.anchor = [self convertPoint:anchor toView:loupe.superview];
    [loupe setHidden:NO animated:YES];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Inserting and Deleting Text

// UITextInput method
//
- (BOOL)hasText
{
    return [text_ length] > 0;
}

// UITextInput method
//
- (void)insertText:(NSString *)text
{
    if (markedTextRange_ == nil && selectedTextRange_ == nil)
    {
        KBCLogWarning(@"marked text range and selected text range are both nil, ignoring");
        return;
    }
    
    // Figure out the attributes that inserted text needs to have
    
    NSDictionary *inputTextAttributes = self.inputTextAttributes;
    NKTTextRange *replacementTextRange = (markedTextRange_ != nil) ? markedTextRange_ : selectedTextRange_;
    NSDictionary *inheritedAttributes = nil;
    
    // Get the inherited attributes
    if ([self hasText])
    {
        NSUInteger inheritedAttributesIndex = replacementTextRange.start.index;
        
        // If the replacement range is empty, inserted characters inherit the attributes of the
        // character preceding the range, if any.
        if (replacementTextRange.empty && inheritedAttributesIndex > 0)
        {
            inheritedAttributesIndex = inheritedAttributesIndex - 1;
        }
        else if (inheritedAttributesIndex > [text_ length])
        {
            inheritedAttributesIndex = [text_ length] - 1;
        }
        
        inheritedAttributes = [text_ attributesAtIndex:inheritedAttributesIndex effectiveRange:NULL];
    }
    
    // We can avoid creating a new range of attributed text if the attributes that would be
    // inherited after insertion match the insertion attributes
    if ([inheritedAttributes isEqualToDictionary:inputTextAttributes])
    {
        [text_ replaceCharactersInRange:replacementTextRange.NSRange withString:text];
    }
    else
    {
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:text
                                                                               attributes:inputTextAttributes];
        [text_ replaceCharactersInRange:replacementTextRange.NSRange withAttributedString:attributedString];
        [attributedString release];
    }
    
    [self regenerateContents];

    // Notify delegate
    if ([self.delegate respondsToSelector:@selector(textViewDidChange:)])
    {
        [self.delegate textViewDidChange:self];
    }
    
    // Update selection
    NKTTextPosition *textPosition = [replacementTextRange.start textPositionByApplyingOffset:[text length]];
    self.markedTextRange = nil;
    [self setSelectedTextRange:[textPosition textRange] notifyInputDelegate:NO];
}

// UITextInput method
//
- (void)deleteBackward
{
    if (markedTextRange_ == nil && selectedTextRange_ == nil)
    {
        KBCLogWarning(@"marked text range and selected text range are nil, ignoring");
        return;
    }
    
    NKTTextRange *deletionTextRange = nil;
    
    // TODO: why can't we just use the selected text range?
    if (markedTextRange_ != nil)
    {
        deletionTextRange = [markedTextRange_ textRangeByGrowingLeft];
    }
    else
    {
        deletionTextRange = [selectedTextRange_ textRangeByGrowingLeft];
    }
    
    [text_ deleteCharactersInRange:deletionTextRange.NSRange];
    [self regenerateContents];
    
    // Notify delegate
    if ([self.delegate respondsToSelector:@selector(textViewDidChange:)])
    {
        [self.delegate textViewDidChange:self];
    }
    
    // The marked text range no longer exists
    self.markedTextRange = nil;
    [self setSelectedTextRange:[deletionTextRange.start textRange] notifyInputDelegate:NO];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Replacing and Returning Text

// UITextInput method
//
- (NSString *)textInRange:(NKTTextRange *)textRange
{
//    KBCLogDebug(@"range: %@", NSStringFromRange(textRange.NSRange));
    
    return [[text_ string] substringWithRange:textRange.NSRange];
}

// UITextInput method
//
- (void)replaceRange:(NKTTextRange *)textRange withText:(NSString *)replacementText
{
    KBCLogDebug(@"range: %@ text: %@", NSStringFromRange(textRange.NSRange), replacementText);
    
    [text_ replaceCharactersInRange:textRange.NSRange withString:replacementText];
    [self regenerateContents];
    
    // The text range to be replaced lies fully before the selected text range
    if (textRange.end.index <= selectedTextRange_.start.index)
    {
        NSInteger changeInLength = [replacementText length] - textRange.length;
        NSUInteger newStartIndex = selectedTextRange_.start.index + changeInLength;
        NKTTextRange *newTextRange = [selectedTextRange_ textRangeByReplacingStartIndexWithIndex:newStartIndex];
        [self setSelectedTextRange:newTextRange notifyInputDelegate:NO];
    }
    // The text range overlaps the selected text range
    else if ((textRange.start.index >= selectedTextRange_.start.index) &&
             (textRange.start.index < selectedTextRange_.end.index))
    {
        NSUInteger newLength = textRange.start.index - selectedTextRange_.start.index;
        NKTTextRange *newTextRange = [NKTTextRange textRangeWithTextPosition:selectedTextRange_.start length:newLength];
        [self setSelectedTextRange:newTextRange notifyInputDelegate:NO];
    }
}

//--------------------------------------------------------------------------------------------------

#pragma mark Working with Marked and Selected Text

// UITextInput method
//
- (NKTTextRange *)selectedTextRange
{
    return selectedTextRange_;
}

// UITextInput method
//
- (void)setSelectedTextRange:(NKTTextRange *)selectedTextRange
{
//    if (selectedTextRange != nil)
//    {
//        KBCLogDebug(@"range: %@", NSStringFromRange(selectedTextRange.NSRange));
//    }
//    else
//    {
//        KBCLogDebug(@"range: nil");
//    }
    
    [self setSelectedTextRange:selectedTextRange notifyInputDelegate:NO];
}

- (void)setSelectedTextRange:(NKTTextRange *)selectedTextRange notifyInputDelegate:(BOOL)notifyInputDelegate
{
    if ([selectedTextRange_ isEqualToTextRange:selectedTextRange])
    {
        return;
    }
    
    // Notify input delegate of selection change if the selection is changing external from it
    // (required by the UITextInput system)
    
    if (notifyInputDelegate)
    {
        [inputDelegate_ selectionWillChange:self];
    }
    
    [selectedTextRange_ release];
    selectedTextRange_ = [selectedTextRange copy];
    
    // The input text attributes are cleared each time the selected text range changes
    self.inputTextAttributes = nil;
    
    if (notifyInputDelegate)
    {
        [inputDelegate_ selectionDidChange:self];
    }
    
    [selectionDisplayController_ updateSelectionElements];
    
    if ([self.delegate respondsToSelector:@selector(textViewDidChangeSelection:)])
    {
        [self.delegate textViewDidChangeSelection:self];
    }
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
    [selectionDisplayController_ updateSelectionElements];
}

- (void)confirmProvisionalTextRange
{
    [self setSelectedTextRange:provisionalTextRange_ notifyInputDelegate:YES];
    self.provisionalTextRange = nil;
}

// UITextInput method
//
- (UITextRange *)markedTextRange
{
//    KBCLogTrace();
    
    return markedTextRange_;
}

// UITextInput method
//
- (NSDictionary *)markedTextStyle
{
//    KBCLogTrace();
    
    return markedTextStyle_;
}

// UITextInput method
//
- (void)setMarkedTextStyle:(NSDictionary *)markedTextStyle
{
    KBCLogTrace();
    
    if (markedTextStyle_ == markedTextStyle)
    {
        return;
    }
    
    [markedTextStyle_ release];
    markedTextStyle_ = [markedTextStyle copy];
}

- (void)setMarkedTextRange:(NKTTextRange *)markedTextRange
{
    if (markedTextRange_ == markedTextRange)
    {
        return;
    }
    
    [markedTextRange_ release];
    markedTextRange_ = [markedTextRange copy];
    [selectionDisplayController_ updateSelectionElements];
}

// UITextInput method
//
- (void)setMarkedText:(NSString *)markedText selectedRange:(NSRange)relativeSelectedRange
{
    [markedText_ autorelease];
    markedText_ = [markedText copy];
    
    if (markedText_ == nil)
    {
        markedText_ = @"";
    }
    
    // Figure out the attributes that inserted text needs to have
    
    NSDictionary *inputTextAttributes = self.inputTextAttributes;
    NKTTextRange *replacementTextRange = (markedTextRange_ != nil) ? markedTextRange_ : selectedTextRange_;
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:markedText_
                                                                           attributes:inputTextAttributes];
    [text_ replaceCharactersInRange:replacementTextRange.NSRange withAttributedString:attributedString];
    [attributedString release];
    
    [self regenerateContents];
    
    NKTTextRange *textRange = [NKTTextRange textRangeWithTextPosition:replacementTextRange.start
                                                               length:[markedText_ length]];
    self.markedTextRange = textRange;
    
    // Update the selected text range within the marked text
    NSUInteger newIndex = markedTextRange_.start.index + relativeSelectedRange.location;
    NKTTextRange *newTextRange = [NKTTextRange textRangeWithIndex:newIndex length:relativeSelectedRange.length];
    [self setSelectedTextRange:newTextRange notifyInputDelegate:NO];
    
    // Input text attributes are reset when marked text is set
    self.inputTextAttributes = nil;
}

// UITextInput method
//
- (void)unmarkText
{
    self.markedTextRange = nil;
    [markedText_ release];
    markedText_ = nil;
}

// UITextInput method
//
- (UITextStorageDirection)selectionAffinity
{
    KBCLogTrace();
    
    return UITextStorageDirectionForward;
}

// UITextInput method
//
- (void)setSelectionAffinity:(UITextStorageDirection)direction
{
    KBCLogDebug(@"direction: %d", direction);
}

//--------------------------------------------------------------------------------------------------

#pragma mark Computing Text Ranges and Text Positions

// UITextInput method
//
- (UITextRange *)textRangeFromPosition:(NKTTextPosition *)fromPosition toPosition:(NKTTextPosition *)toPosition
{
//    KBCLogDebug(@"from: %d to: %d", fromPosition.index, toPosition.index);
    
    return [fromPosition textRangeWithTextPosition:toPosition];
}

// UITextInput method
//
- (UITextPosition *)positionFromPosition:(NKTTextPosition *)textPosition offset:(NSInteger)offset
{
//    KBCLogDebug(@"position: %d offset: %d", textPosition.index, offset);
    
    NSInteger index = (NSInteger)textPosition.index + offset;
    
    if (index < 0)
    {
        return [NKTTextPosition textPositionWithIndex:0];
    }
    else if (index > [text_ length])
    {
        return [NKTTextPosition textPositionWithIndex:[text_ length]];
    }
    
    return [NKTTextPosition textPositionWithIndex:index];
}

//--------------------------------------------------------------------------------------------------

// UITextInput method
//
- (UITextPosition *)positionFromPosition:(NKTTextPosition *)textPosition
                             inDirection:(UITextLayoutDirection)direction
                                  offset:(NSInteger)offset
{
    KBCLogDebug(@"position: %d direction: %d offset: %d", textPosition.index, direction, offset);
    
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
            NSUInteger sourceLineIndex = [self indexForLineContainingTextPosition:textPosition];
            
            // Return the beginning of document if offset puts the position above the first line
            if (offset > sourceLineIndex)
            {
                return [self beginningOfDocument];
            }
            
            NSUInteger targetLineIndex = sourceLineIndex - offset;
            CGPoint sourcePoint = [self originForCharAtTextPosition:textPosition];
            return [self closestTextPositionToPoint:sourcePoint onLineAtIndex:targetLineIndex];
        }
        case UITextLayoutDirectionDown:
        {
            NSUInteger sourceLineIndex = [self indexForLineContainingTextPosition:textPosition];
            NSUInteger targetLineIndex = sourceLineIndex + offset;
            CGPoint sourcePoint = [self originForCharAtTextPosition:textPosition];
            return [self closestTextPositionToPoint:sourcePoint onLineAtIndex:targetLineIndex];
        }
    }
    
    return offsetTextPosition;
}

// UITextInput method
//
- (UITextPosition *)beginningOfDocument
{
//    KBCLogTrace();
    
    return [NKTTextPosition textPositionWithIndex:0];
}

// UITextInput method
- (UITextPosition *)endOfDocument
{
//    KBCLogTrace();
    
    return [NKTTextPosition textPositionWithIndex:[text_ length]];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Evaluating Text Positions

// UITextInput method
//
- (NSComparisonResult)comparePosition:(NKTTextPosition *)textPosition toPosition:(NKTTextPosition *)otherTextPosition
{
//    KBCLogDebug(@"position: %d position: %d", textPosition.index, otherTextPosition.index);
    
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

// UITextInput method
//
- (NSInteger)offsetFromPosition:(NKTTextPosition *)fromPosition toPosition:(NKTTextPosition *)toPosition
{
//    KBCLogDebug(@"position: %d position: %d", fromPosition.index, toPosition.index);
    
    return (toPosition.index - fromPosition.index);
}

//--------------------------------------------------------------------------------------------------

#pragma mark Determining Layout and Writing Direction

// UITextInput method
//
- (UITextPosition *)positionWithinRange:(NKTTextRange *)textRange farthestInDirection:(UITextLayoutDirection)direction
{
    KBCLogDebug(@"range: %@ direction: %d", textRange.NSRange, direction);
    
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

// Returns a text range from a text position to the end of the text range of a line.
//
// If the line index corresponds to a non-typesetted line, a range from the text position to the
// end of document is returned.
//
- (UITextRange *)textRangeFromTextPosition:(NKTTextPosition *)textPosition toEndOfLineAtIndex:(NSUInteger)lineIndex
{
    if ([self indexAddressesNonTypesettedLine:lineIndex])
    {
        return [textPosition textRangeWithTextPosition:(NKTTextPosition *)[self endOfDocument]];
    }
    
    NKTLine *typesettedLine = [typesettedLines_ objectAtIndex:lineIndex];
    return [textPosition textRangeWithTextPosition:typesettedLine.textRange.end];
}

// Returns a text range from the beginning of a line to a text position.
//
// If the line index corresponds to a non-typesetted line, a range from the text position to the
// end of document is returned.
//
- (UITextRange *)textRangeToTextPosition:(NKTTextPosition *)textPosition fromStartOfLineAtIndex:(NSUInteger)lineIndex
{
    if ([self indexAddressesNonTypesettedLine:lineIndex])
    {
        return [textPosition textRangeWithTextPosition:(NKTTextPosition *)[self endOfDocument]];
    }
    
    NKTLine *typesettedLine = [typesettedLines_ objectAtIndex:lineIndex];
    return [textPosition textRangeWithTextPosition:typesettedLine.textRange.start];
}

// UITextInput method
//
- (UITextRange *)characterRangeByExtendingPosition:(NKTTextPosition *)textPosition
                                       inDirection:(UITextLayoutDirection)direction
{
    KBCLogDebug(@"position: %d direction: %d", textPosition.index, direction);
    
    switch (direction)
    {
        case UITextLayoutDirectionRight:
        {
            NSUInteger lineIndex = [self indexForLineContainingTextPosition:textPosition];
            return [self textRangeFromTextPosition:textPosition toEndOfLineAtIndex:lineIndex];
        }
        case UITextLayoutDirectionLeft:
        {
            NSUInteger lineIndex = [self indexForLineContainingTextPosition:textPosition];
            return [self textRangeToTextPosition:textPosition fromStartOfLineAtIndex:lineIndex];
        }
        case UITextLayoutDirectionUp:
        {
            return [textPosition textRangeWithTextPosition:(NKTTextPosition *)[self beginningOfDocument]];
        }
        case UITextLayoutDirectionDown:
        {
            return [textPosition textRangeWithTextPosition:(NKTTextPosition *)[self endOfDocument]];
        }
    }
    
    KBCLogWarning(@"unknown direction, returning nil");
    return nil;
}

- (UITextWritingDirection)baseWritingDirectionForPosition:(NKTTextPosition *)textPosition
                                              inDirection:(UITextStorageDirection)direction
{
    KBCLogDebug(@"position: %d direction: %d", textPosition.index, direction);

    return UITextWritingDirectionNatural;
//    UITextWritingDirection writingDirection = UITextWritingDirectionLeftToRight;
//    CTParagraphStyleRef paragraphStyle = (CTParagraphStyleRef)[text_ attribute:(id)kCTParagraphStyleAttributeName
//                                                                       atIndex:textPosition.index
//                                                                effectiveRange:NULL];
//    
//    if (paragraphStyle != NULL)
//    {        
//        CTParagraphStyleGetValueForSpecifier(paragraphStyle,
//                                             kCTParagraphStyleSpecifierBaseWritingDirection,
//                                             sizeof(CTWritingDirection), &writingDirection);
//    }
//    
//    return writingDirection;
}

- (void)setBaseWritingDirection:(UITextWritingDirection)writingDirection forRange:(NKTTextRange *)textRange
{
    KBCLogDebug(@"direction: %d range: %@", writingDirection, NSStringFromRange(textRange.NSRange));
    
//    // WTF ... this is one fucked up API
//    CTParagraphStyleSetting settings[1];
//    settings[0].spec = kCTParagraphStyleSpecifierBaseWritingDirection;
//    settings[0].valueSize = sizeof(CTWritingDirection);
//    settings[0].value = &writingDirection;
//    
//    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(settings, 1);
//    NSDictionary *attributes = [NSDictionary dictionaryWithObject:(id)paragraphStyle
//                                                           forKey:(id)kCTParagraphStyleAttributeName];
//    CFRelease(paragraphStyle);
//    // TODO: This should really be an attribute merge right?
//    [text_ addAttributes:attributes range:textRange.NSRange];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Geometry and Hit-Testing

// Returns the text position within a line's range that is closest to a point in view space.
//
// Only the character offset is used in the computation. If the index passed in corresponds to a
// non-typesetted line, the end of document is returned.
//
- (UITextPosition *)closestTextPositionToPoint:(CGPoint)point onLineAtIndex:(NSUInteger)lineIndex
{
    if ([self indexAddressesNonTypesettedLine:lineIndex])
    {
        return [self endOfDocument];
    }
    
    CGPoint lineLocalPoint = [self convertPoint:point toLineAtIndex:lineIndex];
    NKTLine *line = [typesettedLines_ objectAtIndex:lineIndex];
    return [line closestTextPositionToPoint:lineLocalPoint];
}

- (CGPoint)originForLineAtIndex:(NSUInteger)index
{
    CGFloat y = margins_.top + lineHeight_ + ((CGFloat)index * lineHeight_);
    CGPoint lineOrigin = CGPointMake(margins_.left, y);
    return lineOrigin;
}

- (CGPoint)convertPoint:(CGPoint)point toLine:(NKTLine *)line
{
    CGPoint lineOrigin = [self originForLineAtIndex:line.index];
    return CGPointMake(point.x - lineOrigin.x, point.y - lineOrigin.y);
}

- (CGPoint)convertPoint:(CGPoint)point toLineAtIndex:(NSUInteger)index
{
    CGPoint lineOrigin = [self originForLineAtIndex:index];
    return CGPointMake(point.x - lineOrigin.x, point.y - lineOrigin.y);
}

- (CGRect)rectForTypesettedLineAtIndex:(NSUInteger)lineIndex
{
    CGFloat width = self.bounds.size.width - margins_.left - margins_.right;
    CGPoint origin = [self originForLineAtIndex:lineIndex];
    const CGFloat heightPadding = 1.0;
    NKTLine *line = [typesettedLines_ objectAtIndex:lineIndex];
    origin.y -= (line.ascent + heightPadding);
    return CGRectMake(origin.x, origin.y, width, line.ascent + line.descent + (heightPadding * 2.0));
}

// TODO: documentation, move this
//
- (CGFloat)offsetForCharAtTextPosition:(NKTTextPosition *)textPosition onLineAtIndex:(NSUInteger)lineIndex
{
    // If index is for a non-typesetted line, the closest text 
    if ([self indexAddressesNonTypesettedLine:lineIndex])
    {
        return 0.0;
    }
    
    NKTLine *line = [typesettedLines_ objectAtIndex:lineIndex];
    return [line offsetForCharAtTextPosition:textPosition];
}

// Text position is valid - since we never create invalid text positions
//
// TODO: share logic with lastLineIndex?
// never need to check for whether line index is ok or not except at bottom level
- (CGPoint)originForCharAtTextPosition:(NKTTextPosition *)textPosition
{
    NSUInteger lineIndex = [self indexForLineContainingTextPosition:textPosition];
    CGPoint lineOrigin = [self originForLineAtIndex:lineIndex];
    CGFloat charOffset = [self offsetForCharAtTextPosition:textPosition onLineAtIndex:lineIndex];
    return CGPointMake(lineOrigin.x + charOffset, lineOrigin.y);
}

// If the end of the text range is the end of the text and ends in a line break, the last rect
// returned will span the end of the rect for the last line to take into account the presence
// of the subsequent non-typesetted line.
//
- (NSArray *)rectsForTextRange:(NKTTextRange *)textRange
{
    // When computing rects for text ranges, only typesetted lines are used
    
    NSUInteger firstLineIndex = [self indexForLineContainingTextPosition:textRange.start];
    
    if ([self indexAddressesNonTypesettedLine:firstLineIndex])
    {
        return nil;
    }
    
    NSUInteger lastLineIndex = [self indexForLineContainingTextPosition:textRange.end];
    
    if ([self indexAddressesNonTypesettedLine:lastLineIndex])
    {
        lastLineIndex = [self lastTypesettedLineIndex];
    }
    
    // Dealing with single rect on a line
    if (firstLineIndex == lastLineIndex)
    {
        // Get the rect for the entire line and adjust its x origin
        CGRect firstLineRect = [self rectForTypesettedLineAtIndex:firstLineIndex];
        CGFloat firstCharOffset = [self offsetForCharAtTextPosition:textRange.start onLineAtIndex:firstLineIndex];
        firstLineRect.origin.x += firstCharOffset;
        
        // Handle case where the end of the text range lies on a non-typesetted line
        if (textRange.end.index == [text_ length] && [[text_ string] hasSuffix:@"\n"])
        {
            firstLineRect.size.width -= firstCharOffset;
        }
        else
        {
            CGFloat lastCharOffset = [self offsetForCharAtTextPosition:textRange.end onLineAtIndex:firstLineIndex];
            firstLineRect.size.width = lastCharOffset - firstCharOffset;
        }
        
        return [NSArray arrayWithObject:[NSValue valueWithCGRect:firstLineRect]];
    }
    // Dealing with multiple lines
    else
    {
        NSMutableArray *rects = [[[NSMutableArray alloc] init] autorelease];
        
        // Rect for first line
        CGRect firstLineRect = [self rectForTypesettedLineAtIndex:firstLineIndex];
        CGFloat firstCharOffset = [self offsetForCharAtTextPosition:textRange.start onLineAtIndex:firstLineIndex];
        firstLineRect.origin.x += firstCharOffset;
        firstLineRect.size.width -= firstCharOffset;
        [rects addObject:[NSValue valueWithCGRect:firstLineRect]];
        
        // Rects for lines in between
        for (NSUInteger lineIndex = firstLineIndex + 1; lineIndex < lastLineIndex; ++lineIndex)
        {
            CGRect lineRect = [self rectForTypesettedLineAtIndex:lineIndex];
            [rects addObject:[NSValue valueWithCGRect:lineRect]];
        }
        
        // Rect for last line
        CGRect lastLineRect = [self rectForTypesettedLineAtIndex:lastLineIndex];
        
        // Handle case where the end of the text range DOES NOT lie on a non-typesetted line
        if (textRange.end.index != [text_ length] || ![[text_ string] hasSuffix:@"\n"])
        {
            CGFloat lastCharOffset = [self offsetForCharAtTextPosition:textRange.end onLineAtIndex:lastLineIndex];
            lastLineRect.size.width = lastCharOffset;
        }
        
        [rects addObject:[NSValue valueWithCGRect:lastLineRect]];
        return rects;
    }
}

// UITextInput method
//
- (CGRect)firstRectForRange:(NKTTextRange *)textRange
{
//    KBCLogDebug(@"range: %@", NSStringFromRange(textRange.NSRange));
    
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

- (CGRect)caretRectWithOrigin:(CGPoint)origin font:(UIFont *)font
{
    CGRect caretFrame = CGRectZero;
    const CGFloat caretWidth = 3.0;
    const CGFloat caretVerticalPadding = 1.0;
    caretFrame.origin.x = origin.x;
    caretFrame.origin.y = origin.y - font.ascender - caretVerticalPadding;
    caretFrame.size.width = caretWidth;
    caretFrame.size.height = font.ascender - font.descender + (caretVerticalPadding * 2.0);
    return caretFrame;
}

- (CGRect)inputCaretRect
{
    NKTTextPosition *caretTextPosition = selectedTextRange_.start;
    CGPoint charOrigin = [self originForCharAtTextPosition:caretTextPosition];
    KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithAttributes:self.inputTextAttributes];
    UIFont *font = [styleDescriptor uiFontForFontStyle];
    return [self caretRectWithOrigin:charOrigin font:font];
}

// UITextInput method
//
- (CGRect)caretRectForPosition:(NKTTextPosition *)textPosition
{
    KBCLogDebug(@"position: %d", textPosition.index);
    
    CGPoint charOrigin = [self originForCharAtTextPosition:textPosition];
    UIFont *font = [self fontAtTextPosition:textPosition inDirection:UITextStorageDirectionForward];
    return [self caretRectWithOrigin:charOrigin font:font];
}

// UITextInput method
//
// TODO: figure out when this is called by UITextInput, and implement accordingly
//
- (UITextPosition *)closestPositionToPoint:(CGPoint)point
{
//    KBCLogDebug(@"point: %@", NSStringFromCGPoint(point));
    
    NSUInteger lineIndex = [self indexForClosestLineToPoint:point];    
    return [self closestTextPositionToPoint:point onLineAtIndex:lineIndex];
}

// UITextInput method
//
// TODO: figure out when this is called by UITextInput, and implement accordingly
//
- (UITextPosition *)closestPositionToPoint:(CGPoint)point withinRange:(NKTTextRange *)textRange
{
    KBCLogDebug(@"point: %@ range: %@", NSStringFromCGPoint(point), NSStringFromRange(textRange.NSRange));
    
    NKTTextPosition *textPosition = (NKTTextPosition *)[self closestPositionToPoint:point];
    
    if ([textRange containsTextPosition:textPosition])
    {
        return textPosition;
    }
    
    // At this point, the closest text position lies on either the first line or the last line
    
    NSUInteger firstLineIndex = [self indexForLineContainingTextPosition:textRange.start];
    
    if ([self indexAddressesNonTypesettedLine:firstLineIndex])
    {
        return textRange.start;
    }
    
    CGPoint firstLineOrigin = [self originForLineAtIndex:firstLineIndex];
    
    if (point.y <= firstLineOrigin.y)
    {
        return [self closestTextPositionToPoint:point onLineAtIndex:firstLineIndex];
    }
    else
    {
        NSUInteger lastLineIndex = [self indexForLineContainingTextPosition:textRange.end];
        
        if ([self indexAddressesNonTypesettedLine:lastLineIndex])
        {
            lastLineIndex = [self lastTypesettedLineIndex];
        }
        
        return [self closestTextPositionToPoint:point onLineAtIndex:lastLineIndex];
    }
}

// UITextInput method
- (UITextRange *)characterRangeAtPoint:(CGPoint)point
{
    KBCLogDebug(@"point: %@", NSStringFromCGPoint(point));
    
    NKTTextPosition *textPosition = (NKTTextPosition *)[self closestPositionToPoint:point];
    return [textPosition textRange];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Text Input Delegate and Text Input Tokenizer

- (id <UITextInputTokenizer>)tokenizer
{
    if (tokenizer_ == nil)
    {
        tokenizer_ = [[NKTTextViewTokenizer alloc] initWithTextView:self];
    }
    
    return tokenizer_;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Returning Text Styling Information

// UITextInput method
//
- (NSDictionary *)textStylingAtPosition:(NKTTextPosition *)textPosition inDirection:(UITextStorageDirection)direction
{
    KBCLogDebug(@"position: %d direction: %d", textPosition.index, direction);
    
    UIFont *font = [self fontAtTextPosition:textPosition inDirection:direction];
    UIColor *color = [UIColor blackColor];
    UIColor *backgroundColor = self.backgroundColor;
    return [NSDictionary dictionaryWithObjectsAndKeys:backgroundColor, UITextInputTextBackgroundColorKey,
                                                      color, UITextInputTextColorKey,
                                                      font, UITextInputTextFontKey, nil];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Styling Text Ranges

- (void)styleTextRange:(NKTTextRange *)textRange withTarget:(id)target selector:(SEL)selector
{
    if (textRange == nil || textRange.empty)
    {
        return;
    }
    
    NSUInteger index = textRange.start.index;
    
    while (index < textRange.end.index)
    {
        NSRange longestEffectiveRange;
        NSDictionary *attributes = [text_ attributesAtIndex:index
                                      longestEffectiveRange:&longestEffectiveRange
                                                    inRange:selectedTextRange_.NSRange];
        NSDictionary *newAttributes = [target performSelector:selector withObject:attributes];
        
        if (newAttributes != attributes)
        {
            [text_ setAttributes:newAttributes range:longestEffectiveRange];
        }
        
        index = longestEffectiveRange.location + longestEffectiveRange.length;
    }
    
    [self regenerateContents];
    [selectionDisplayController_ updateSelectionElements];   
}

//--------------------------------------------------------------------------------------------------

#pragma mark Managing Text Attributes

// Input text attributes refer to the text attributes that would be applied to inserted/modified
// text. Input text attributes are context dependent and are based on the text and selected text
// range.
- (NSDictionary *)inputTextAttributes
{
    // If the inputTextAttributes_ variable has been set, just use it, else we get the appropriate
    // attributes through some context dependent logic
    
    if (inputTextAttributes_ != nil)
    {
        return inputTextAttributes_;
    }
    
    // Use default text attributes if there is no text or selected text range
    if (![self hasText] || self.selectedTextRange == nil)
    {
        if ([self.delegate respondsToSelector:@selector(defaultTextAttributes)])
        {
            return [self.delegate defaultTextAttributes];
        }
    }
    
    // Otherwise, get the typing attributes by looking at the text and selected text range
    NKTTextPosition *textPosition = selectedTextRange_.start;
    
    // The typing attributes for a non-empty text range are the attributes for the first character
    // of the selection
    if (!self.selectedTextRange.empty)
    {
        return [self.text attributesAtIndex:textPosition.index effectiveRange:NULL];
    }
    // The typing attributes at the beginning of a paragraph are the attributes for the first
    // character of the paragraph
    else if ((textPosition.index < [self.text length]) &&
             [self.tokenizer isPosition:textPosition
                             atBoundary:UITextGranularityParagraph
                            inDirection:UITextStorageDirectionForward])
    {
        return [self.text attributesAtIndex:textPosition.index effectiveRange:NULL];
    }
    // Selected text range is empty, use the typing attributes for the character preceding the
    // insertion point if possible
    else
    {
        NSUInteger index = textPosition.index;
        
        if (index > 0)
        {
            --index;
        }
        
        return [self.text attributesAtIndex:index effectiveRange:NULL];
    }
}

- (void)setInputTextAttributes:(NSDictionary *)inputTextAttributes
{
    if (inputTextAttributes_ == inputTextAttributes)
    {
        return;
    }
    
    [inputTextAttributes_ release];
    inputTextAttributes_ = [inputTextAttributes copy];
    // The caret may need to be updated, so update selection elements
    [selectionDisplayController_ updateSelectionElements];
}

- (void)setSelectedTextRangeTextAttributes:(NSDictionary *)textAttributes
{
    if (selectedTextRange_ == nil || selectedTextRange_.empty)
    {
        return;
    }
    
    // TODO: Don't need to set anything if the existing attributes at position match and the
    // effective range contains the selected range
    [text_ setAttributes:textAttributes range:selectedTextRange_.NSRange];
    [self regenerateContents];
    [selectionDisplayController_ updateSelectionElements];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Fonts at Text Positions

- (UIFont *)fontAtTextPosition:(NKTTextPosition *)textPosition inDirection:(UITextStorageDirection)direction;
{
    // NOTE: Direction is ignored
    
    UIFont *font = nil;
    
    if (text_ == nil || [text_ length] == 0)
    {
        return [UIFont systemFontOfSize:[UIFont systemFontSize]];
    }
    
    // Read the style information at the character preceding the index because that is the style that
    // would be used when text is inserted at that position
    
    NSUInteger sourceIndex = textPosition.index;
    
    if (sourceIndex > [text_ length])
    {
        sourceIndex = [text_ length] - 1;
    }
    else if (sourceIndex > 0)
    {
        --sourceIndex;
    }
    
    NSDictionary *attributes = [text_ attributesAtIndex:sourceIndex effectiveRange:NULL];
    CTFontRef ctFont = (CTFontRef)[attributes objectForKey:(id)kCTFontAttributeName];
    
    if (ctFont != NULL)
    {
        font = KBTUIFontForCTFont(ctFont);
        
        if (font == nil)
        {
            KBCLogWarning(@"could not create UIFont for CTFont");
        }
    }
    
    if (font == nil)
    {
        font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    }
    
    return font;
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
    [self insertSubview:view atIndex:[underlayViews_ count]];
    [underlayViews_ addObject:view];
}

- (void)addOverlayView:(UIView *)view
{
    [self insertSubview:view atIndex:[underlayViews_ count] + [visibleSections_ count]];
    [overlayViews addObject:view];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Tokenizing

- (BOOL)isTextPosition:(NKTTextPosition *)textPosition atLineBoundaryInDirection:(UITextDirection)direction
{
//    KBCLogDebug(@"position: %d direction: %d", textPosition.index, direction);
    
    NSUInteger lineIndex = [self indexForLineContainingTextPosition:textPosition];
    
    if ([self indexAddressesNonTypesettedLine:lineIndex])
    {
        return YES;
    }
    
    NKTLine *typesettedLine = [typesettedLines_ objectAtIndex:lineIndex];
    
    if (direction == UITextLayoutDirectionRight || direction == UITextStorageDirectionForward)
    {
        return textPosition.index == typesettedLine.textRange.end.index;
    }
    else if (direction == UITextLayoutDirectionLeft || direction == UITextStorageDirectionBackward)
    {
        return textPosition.index == typesettedLine.textRange.start.index;
    }
    
    return NO;
}

- (BOOL)isTextPosition:(NKTTextPosition *)textPosition withinLineInDirection:(UITextDirection)direction
{
//    KBCLogDebug(@"position: %d direction: %d", textPosition.index, direction); 
    
    NSUInteger lineIndex = [self indexForLineContainingTextPosition:textPosition];
    
    if ([self indexAddressesNonTypesettedLine:lineIndex])
    {
        return YES;
    }
    
    NKTLine *typesettedLine = [typesettedLines_ objectAtIndex:lineIndex];
    
    if (direction == UITextLayoutDirectionRight || direction == UITextStorageDirectionForward)
    {
        return (textPosition.index >= typesettedLine.textRange.start.index) &&
               (textPosition.index < typesettedLine.textRange.end.index);
    }
    else if (direction == UITextLayoutDirectionLeft || direction == UITextStorageDirectionBackward)
    {
        return (textPosition.index > typesettedLine.textRange.start.index) &&
               (textPosition.index <= typesettedLine.textRange.end.index);
    }
    
    return NO;
}

- (UITextPosition *)positionFromTextPosition:(NKTTextPosition *)textPosition
                   toLineBoundaryInDirection:(UITextDirection)direction
{
//    KBCLogDebug(@"position: %d direction: %d", textPosition.index, direction);
    
    NSUInteger lineIndex = [self indexForLineContainingTextPosition:textPosition];
    
    if ([self indexAddressesNonTypesettedLine:lineIndex])
    {
        return [self endOfDocument];
    }
    
    NKTLine *typesettedLine = [typesettedLines_ objectAtIndex:lineIndex];
    
    if (direction == UITextLayoutDirectionRight || direction == UITextStorageDirectionForward)
    {
        // If line has a line break, move to location before it
        if (!typesettedLine.textRange.empty)
        {
            return [typesettedLine.textRange.end previousTextPosition];
        }
        else
        {
            return typesettedLine.textRange.end;
        }
    }
    else if (direction == UITextLayoutDirectionLeft || direction == UITextStorageDirectionBackward)
    {
        return typesettedLine.textRange.start;        
    }
    
    return nil;
}

- (UITextRange *)textRangeForLineEnclosingTextPosition:(NKTTextPosition *)textPosition
                                           inDirection:(UITextDirection)direction
{
//    KBCLogDebug(@"position: %d direction: %d", textPosition.index, direction);
    
    NSUInteger lineIndex = [self indexForLineContainingTextPosition:textPosition];
    
    if (direction == UITextLayoutDirectionLeft || direction == UITextStorageDirectionBackward)
    {
        if ([self indexAddressesNonTypesettedLine:lineIndex])
        {
            --lineIndex;
        }
        else if (lineIndex > 0)
        {
            NKTLine *typesettedLine = [typesettedLines_ objectAtIndex:lineIndex];
            
            if (textPosition.index == typesettedLine.textRange.start.index)
            {
                --lineIndex;
            }
        }
        else
        {
            return nil;
        }
    }
    
    NKTLine *typesettedLine = [typesettedLines_ objectAtIndex:lineIndex];
    return typesettedLine.textRange;
}

@end
