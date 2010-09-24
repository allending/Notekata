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

#pragma mark Managing Loupes

@property (nonatomic, readonly) NKTLoupe *bandLoupe;
@property (nonatomic, readonly) NKTLoupe *roundLoupe;

- (void)showLoupe:(NKTLoupe *)loupe atPoint:(CGPoint)point anchorToLine:(BOOL)anchorToLine;
- (void)showLoupe:(NKTLoupe *)loupe atTextPosition:(NKTTextPosition *)textPosition;

#pragma mark Working with Marked and Selected Text

- (void)setProvisionalTextRange:(NKTTextRange *)provisionalTextRange;
- (void)confirmProvisionalTextRange;
- (void)setSelectedTextRange:(NKTTextRange *)selectedTextRange notifyInputDelegate:(BOOL)notifyInputDelegate;
- (void)setMarkedTextRange:(NKTTextRange *)markedTextRange;

#pragma mark Geometry and Hit-Testing

- (CGPoint)originForLineAtIndex:(NSUInteger)index;
- (CGPoint)convertPoint:(CGPoint)point toLine:(NKTLine *)line;
- (CGRect)rectForLine:(NKTLine *)line;
- (CGPoint)characterOriginForPosition:(NKTTextPosition *)textPosition;

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

@synthesize activeTextAttributes = activeTextAttributes_;

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
    
    doubleTapAndDragGestureRecognizer_ = [[NKTDragGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapAndDrag:)];
    doubleTapAndDragGestureRecognizer_.delegate = gestureRecognizerDelegate_;
    
    nonEditTapGestureRecognizer_ = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    nonEditTapGestureRecognizer_.delegate = gestureRecognizerDelegate_;
    [nonEditTapGestureRecognizer_ requireGestureRecognizerToFail:doubleTapAndDragGestureRecognizer_];
    
    tapGestureRecognizer_ = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapGestureRecognizer_.delegate = gestureRecognizerDelegate_;
    
    longPressGestureRecognizer_ = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
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
    
    [activeTextAttributes_ release];
    
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

- (void)setLineHeight:(CGFloat)lineHeight 
{
    lineHeight_ = lineHeight;
    // Don't need to typeset lines because the line width is not changing
    [self untileVisibleSections];
    [self tileSections];
    [self updateContentSize];
}

- (void)setMargins:(UIEdgeInsets)newMargins
{
    margins_ = newMargins;
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
        NKTLine *line = [[NKTLine alloc] initWithIndex:lineIndex text:text_ CTLine:ctLine];
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
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan || gestureRecognizer.state == UIGestureRecognizerStateChanged)
    {
        CGPoint touchLocation = [gestureRecognizer locationInView:self];
        NKTTextPosition *textPosition = nil;
        
        // Computed text position depends on whether there is marked text or not
        if (markedTextRange_ != nil && !markedTextRange_.empty)
        {
            textPosition = (NKTTextPosition *)[self closestPositionToPoint:touchLocation withinRange:markedTextRange_];
            [self showLoupe:self.bandLoupe atTextPosition:textPosition];
        }
        else
        {
            textPosition = (NKTTextPosition *)[self closestPositionToPoint:touchLocation];
            [self showLoupe:self.roundLoupe atPoint:touchLocation anchorToLine:NO];
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
        [self showLoupe:self.bandLoupe atPoint:touchLocation anchorToLine:YES];
        NKTTextRange *textRange = [self.doubleTapStartTextPosition textRangeUntilTextPosition:textPosition];
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

- (NSInteger)virtualIndexForLineContainingPoint:(CGPoint)point
{
    return (NSInteger)floor((point.y - margins_.top) / lineHeight_);
}

- (NKTLine *)closestLineContainingPoint:(CGPoint)point
{
    NSUInteger lineCount = [typesettedLines_ count];
    
    if (lineCount == 0)
    {
        return nil;
    }
    
    NSInteger virtualLineIndex = [self virtualIndexForLineContainingPoint:point];
    NSUInteger lineIndex = (NSUInteger)MAX(virtualLineIndex, 0);
    lineIndex = MIN(lineIndex, lineCount - 1);
    return [typesettedLines_ objectAtIndex:lineIndex];
}

- (NKTLine *)lineContainingTextPosition:(NKTTextPosition *)textPosition
{ 
    for (NKTLine *line in typesettedLines_)
    {
        if ([line.textRange containsTextPosition:textPosition])
        {
            return line;
        }
    }
    
    return nil;
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
        
        CGPoint anchor = CGPointMake(point.x, lineOrigin.y - (lineHeight_ * 0.8));
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
    
    CGPoint zoomCenter = CGPointMake(margins_.left + charOffset, lineOrigin.y);
    loupe.zoomCenter = [self convertPoint:zoomCenter toView:loupe.zoomedView];
    
    CGPoint anchor = CGPointMake(margins_.left + charOffset, lineOrigin.y - (lineHeight_ * 0.8));
    anchor = KBCClampPointToRect(anchor, self.bounds);
    loupe.anchor = [self convertPoint:anchor toView:loupe.superview];

    [loupe setHidden:NO animated:YES];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Inserting and Deleting Text

- (BOOL)hasText
{
    return [text_ length] > 0;
}

- (void)insertText:(NSString *)text
{
    if (markedTextRange_ == nil && selectedTextRange_ == nil)
    {
        KBCLogWarning(@"marked text range and selected text range are both nil, ignoring");
        return;
    }
    
    // Figure out the attributes that inserted text needs to have
    
    NSDictionary *insertionAttributes = [self typingAttributes];
    NKTTextRange *replacementTextRange = (markedTextRange_ != nil) ? markedTextRange_ : selectedTextRange_;
    NSDictionary *inheritedAttributes = nil;
    
    // Get the inherited attributes
    if ([self hasText])
    {
        NSUInteger inheritedAttributesIndex = replacementTextRange.start.index;
        
        // If the replacement range is empty, inserted characters inherit the attributes of the
        // character preceding the range, if any.
        if (replacementTextRange.isEmpty && inheritedAttributesIndex > 0)
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
    if ([inheritedAttributes isEqualToDictionary:insertionAttributes])
    {
        [text_ replaceCharactersInRange:replacementTextRange.NSRange withString:text];
    }
    else
    {
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:text attributes:insertionAttributes];
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

- (NSString *)textInRange:(NKTTextRange *)textRange
{
    return [[text_ string] substringWithRange:textRange.NSRange];
}

- (void)replaceRange:(NKTTextRange *)textRange withText:(NSString *)replacementText
{
    [text_ replaceCharactersInRange:textRange.NSRange withString:replacementText];
    [self regenerateContents];
    
    // The text range to be replaced lies fully before the selected text range
    if (textRange.end.index <= selectedTextRange_.start.index)
    {
        NSInteger charChangeCount = [replacementText length] - textRange.length;
        NSUInteger newStartIndex = selectedTextRange_.start.index + charChangeCount;
        NKTTextRange *newTextRange = [selectedTextRange_ textRangeByReplacingStartIndexWithIndex:newStartIndex];
        [self setSelectedTextRange:newTextRange notifyInputDelegate:NO];
    }
    // The text range overlaps the selected text range
    else if (textRange.start.index >= selectedTextRange_.start.index && textRange.start.index < selectedTextRange_.end.index)
    {
        NSUInteger newLength = textRange.start.index - selectedTextRange_.start.index;
        NKTTextRange *newTextRange = [NKTTextRange textRangeWithTextPosition:selectedTextRange_.start length:newLength];
        [self setSelectedTextRange:newTextRange notifyInputDelegate:NO];
    }
}

//--------------------------------------------------------------------------------------------------

#pragma mark Working with Marked and Selected Text

- (NKTTextRange *)selectedTextRange
{
    return selectedTextRange_;
}

- (void)setSelectedTextRange:(NKTTextRange *)selectedTextRange
{
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
    
    // The active text attributes are cleared whenever the selected text range changes
    self.activeTextAttributes = nil;
    
    if (notifyInputDelegate)
    {
        [inputDelegate_ selectionDidChange:self];
    }
    
    [selectionDisplayController_ selectedTextRangeDidChange];
    
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
    [selectionDisplayController_ provisionalTextRangeDidChange];
}

- (void)confirmProvisionalTextRange
{
    [self setSelectedTextRange:provisionalTextRange_ notifyInputDelegate:YES];
    self.provisionalTextRange = nil;
}

- (UITextRange *)markedTextRange
{
    return markedTextRange_;
}

- (NSDictionary *)markedTextStyle
{
    KBCLogTrace();
    return markedTextStyle_;
}

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
    [selectionDisplayController_ markedTextRangeDidChange];
}

- (void)setMarkedText:(NSString *)markedText selectedRange:(NSRange)relativeSelectedRange
{
    [markedText_ autorelease];
    markedText_ = [markedText copy];
    
    if (markedText_ == nil)
    {
        markedText_ = @"";
    }
    
    // Figure out the attributes that inserted text needs to have
    
    NSDictionary *insertionAttributes = [self typingAttributes];
    NKTTextRange *replacementTextRange = (markedTextRange_ != nil) ? markedTextRange_ : selectedTextRange_;
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:markedText_ attributes:insertionAttributes];
    [text_ replaceCharactersInRange:replacementTextRange.NSRange withAttributedString:attributedString];
    [attributedString release];
    
    [self regenerateContents];
    
    NKTTextRange *textRange = [NKTTextRange textRangeWithTextPosition:replacementTextRange.start length:[markedText_ length]];
    self.markedTextRange = textRange;
    
    // Update the selected text range within the marked text
    NSUInteger newIndex = markedTextRange_.start.index + relativeSelectedRange.location;
    NKTTextRange *newTextRange = [NKTTextRange textRangeWithIndex:newIndex length:relativeSelectedRange.length];
    [self setSelectedTextRange:newTextRange notifyInputDelegate:NO];
    
    // TODO: reset as needed
    self.activeTextAttributes = nil;
}

- (void)unmarkText
{
    self.markedTextRange = nil;
    [markedText_ release];
    markedText_ = nil;
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
    
    if (index < 0 || index > [text_ length])
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
            pointAboveCaret.y += (0.5 * lineHeight_);
            pointAboveCaret.y -= ((CGFloat)offset * lineHeight_);
            offsetTextPosition = (NKTTextPosition *)[self closestPositionToPoint:pointAboveCaret];
            break;
        }
        case UITextLayoutDirectionDown:
        {
            CGRect caretFrame = [self caretRectForPosition:textPosition];
            CGPoint pointAboveCaret = caretFrame.origin;
            pointAboveCaret.y += (0.5 * lineHeight_);
            pointAboveCaret.y += ((CGFloat)offset * lineHeight_);
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
    return [NKTTextPosition textPositionWithIndex:[text_ length]];
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
    CTParagraphStyleRef paragraphStyle = (CTParagraphStyleRef)[text_ attribute:(id)kCTParagraphStyleAttributeName atIndex:textPosition.index effectiveRange:NULL];
    
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
    [text_ addAttributes:attributes range:textRange.NSRange];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Geometry and Hit-Testing

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

- (CGRect)rectForLine:(NKTLine *)line
{
    CGFloat width = self.bounds.size.width - margins_.left - margins_.right;
    CGPoint origin = [self originForLineAtIndex:line.index];
    const CGFloat heightPadding = 1.0;
    origin.y -= (line.ascent + heightPadding);
    return CGRectMake(origin.x, origin.y, width, line.ascent + line.descent + (heightPadding * 2.0));
}

- (CGPoint)originForTextPosition:(NKTTextPosition *)textPosition
{
    NKTLine *line = [self lineContainingTextPosition:textPosition];
    CGPoint lineOrigin = [self originForLineAtIndex:line.index];
    CGFloat offset = [line offsetForCharAtTextPosition:textPosition];
    return CGPointMake(margins_.left + offset, lineOrigin.y);
}

- (CGPoint)characterOriginForPosition:(NKTTextPosition *)textPosition
{
    CGPoint lineOrigin = CGPointZero;
    CGFloat charOffset = 0.0;
    
    // Use fake first line if no typesetted lines exist
    if ([typesettedLines_ count] == 0 || textPosition.index == 0)
    {
        lineOrigin = [self originForLineAtIndex:0];
    }
    // Text position beyond the end of the document, special handling required
    else if (textPosition.index >= [text_ length])
    {
        // Line break at end, so use origin of the line beyond the last typesetted one
        if ([[text_ string] hasSuffix:@"\n"])
        {
            lineOrigin = [self originForLineAtIndex:[typesettedLines_ count]];
        }
        // Last character is not a line break, use the last typesetted line
        else
        {
            NKTLine *lastLine = [typesettedLines_ objectAtIndex:[typesettedLines_ count] - 1];
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
        lastLine = [typesettedLines_ objectAtIndex:[typesettedLines_ count] - 1];
    }
    
    // Dealing with a single rect
    if (firstLine == lastLine)
    {
        CGRect rect = [self rectForLine:firstLine];
        CGFloat charOffset = [firstLine offsetForCharAtTextPosition:textRange.start];
        rect.origin.x += charOffset;
        
        // Use entire line if end of the text range is a line break at the end of document
        if (textRange.end.index == [text_ length] && [[text_ string] hasSuffix:@"\n"])
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
        NKTLine *line = [typesettedLines_ objectAtIndex:lineIndex];
        CGRect rect = [self rectForLine:line];
        [rects addObject:[NSValue valueWithCGRect:rect]];
    }
    
    // Rect for last line
    CGRect lastRect = [self rectForLine:lastLine];
    
    // Use entire line if end of the text range is a line break at the end of document
    if (textRange.end.index != [text_ length] || ![[text_ string] hasSuffix:@"\n"])
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

- (CGRect)caretRectForPosition:(NKTTextPosition *)textPosition
{
    CGPoint charOrigin = [self characterOriginForPosition:textPosition];
    UIFont *font = [self fontAtTextPosition:textPosition inDirection:UITextStorageDirectionForward];
    CGRect caretFrame = CGRectZero;
    const CGFloat caretWidth = 3.0;
    const CGFloat caretVerticalPadding = 1.0;
    caretFrame.origin.x = charOrigin.x;
    caretFrame.origin.y = charOrigin.y - font.ascender - caretVerticalPadding;
    caretFrame.size.width = caretWidth;
    caretFrame.size.height = font.ascender - font.descender + (caretVerticalPadding * 2.0);
    return caretFrame;
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point
{
    NSInteger virtualLineIndex = [self virtualIndexForLineContainingPoint:point];
    
    if (virtualLineIndex < 0 || [typesettedLines_ count] == 0)
    {
        return [NKTTextPosition textPositionWithIndex:0];
    }
    else if ((NSUInteger)virtualLineIndex >= [typesettedLines_ count])
    {
        return [NKTTextPosition textPositionWithIndex:[text_ length]];
    }
    else
    {
        NKTLine *line = [typesettedLines_ objectAtIndex:(NSUInteger)virtualLineIndex];
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
    CGPoint localPoint = CGPointMake(point.x - margins_.left, 0.0);
    
    if (point.y <= firstLineOrigin.y)
    {
        return [firstLine closestTextPositionToPoint:localPoint withinRange:textRange];
    }
    else
    {
        NKTLine *lastLine = [self lineContainingTextPosition:textRange.end];
        
        if (lastLine == nil)
        {
            lastLine = [typesettedLines_ objectAtIndex:[typesettedLines_ count] - 1];
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
    if (tokenizer_ == nil)
    {
        tokenizer_ = [[UITextInputStringTokenizer alloc] initWithTextInput:self];
    }
    
    return tokenizer_;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Returning Text Styling Information

- (NSDictionary *)textStylingAtPosition:(NKTTextPosition *)textPosition inDirection:(UITextStorageDirection)direction
{
    UIFont *font = [self fontAtTextPosition:textPosition inDirection:direction];
    UIColor *color = [UIColor blackColor];
    UIColor *backgroundColor = self.backgroundColor;
    return [NSDictionary dictionaryWithObjectsAndKeys:backgroundColor, UITextInputTextBackgroundColorKey,
                                                      color, UITextInputTextColorKey,
                                                      font, UITextInputTextFontKey, nil];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Managing Text Attributes

// Typing attributes refer to the text attributes that would be applied to inserted text. Typing
// attributes are context dependent and are based on the text and selected text range.
- (NSDictionary *)typingAttributes
{
    // Active text attributes always take precedence
    if (activeTextAttributes_ != nil)
    {
        return activeTextAttributes_;
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
    NKTTextPosition *textPosition = self.selectedTextRange.start;
    
    // The typing attributes for a non-empty text range are the attributes for the first character
    // of the selection
    if (!self.selectedTextRange.isEmpty)
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

- (NSDictionary *)textAttributesAtTextPosition:(NKTTextPosition *)textPosition
{
    if ([self.text length] == 0)
    {
        return nil;
    }
    
    NSUInteger sourceIndex = textPosition.index;
    
    if (sourceIndex > [text_ length])
    {
        sourceIndex = [text_ length] - 1;
    }
    else if (sourceIndex > 0)
    {
        --sourceIndex;
    }
    
    return [text_ attributesAtIndex:sourceIndex effectiveRange:NULL];
}

- (void)setSelectedTextRangeTextAttributes:(NSDictionary *)textAttributes
{
    if (selectedTextRange_ == nil || selectedTextRange_.isEmpty)
    {
        return;
    }
    
    // TODO: Don't need to set anything if the existing attributes at position match and the
    // effective range contains the selected range
    [text_ setAttributes:textAttributes range:selectedTextRange_.NSRange];
    [self regenerateContents];
    [selectionDisplayController_ textLayoutDidChange];
}

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

@end
