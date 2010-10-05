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
#import "NKTFramesetter.h"

@interface NKTTextView()

#pragma mark Initializing

- (void)NKTTextView_requiredInit;
- (void)initGestureRecognizers;

// TODO: move to a class that helps with tiling
#pragma mark Tiling Sections

- (void)tileSections;
- (void)untileVisibleSections;
- (BOOL)isDisplayingSectionAtIndex:(NSInteger)index;
- (NKTTextSection *)dequeueReusableSection;
- (void)configureSection:(NKTTextSection *)section atIndex:(NSInteger)index;
- (CGRect)frameForSectionAtIndex:(NSInteger)index;

#pragma mark Framesetting

@property (nonatomic, readonly) CGFloat lineWidth;
@property (nonatomic, readonly) NKTFramesetter *framesetter;

- (void)invalidateFramesetter;
- (void)regenerateContents;

#pragma mark Responding to Gestures

@property (nonatomic, retain) NKTTextPosition *doubleTapStartTextPosition;

- (void)handleTap:(UIGestureRecognizer *)gestureRecognizer;
- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer;
- (void)handleDoubleTapAndDrag:(UIGestureRecognizer *)gestureRecognizer;

#pragma mark Managing Loupes

@property (nonatomic, readonly) NKTLoupe *bandLoupe;
@property (nonatomic, readonly) NKTLoupe *roundLoupe;

- (void)configureLoupe:(NKTLoupe *)loupe toMagnifyPoint:(CGPoint)point anchorToClosestLine:(BOOL)anchorToLine;
- (void)configureLoupe:(NKTLoupe *)loupe toMagnifyTextPosition:(NKTTextPosition *)textPosition;

#pragma mark Managing Text Ranges

- (NKTTextRange *)interimSelectedTextRange;
- (void)setInterimSelectedTextRange:(NKTTextRange *)interimSelectedTextRange affinity:(UITextStorageDirection)affinity;
- (void)confirmInterimSelectedTextRange;
- (void)setSelectedTextRange:(NKTTextRange *)selectedTextRange
                    affinity:(UITextStorageDirection)affinity
         notifyInputDelegate:(BOOL)notifyInputDelegate;
- (void)setMarkedTextRange:(NKTTextRange *)markedTextRange;

#pragma mark Geometry and Hit-Testing

- (CGRect)caretRectForTextPosition:(NKTTextPosition *)textPosition
          applyInputTextAttributes:(BOOL)applyInputTextAttributes;
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
    horizontalRulesEnabled_ = YES;
    horizontalRuleColor_ = [[UIColor colorWithRed:0.72 green:0.72 blue:0.59 alpha:1.0] retain];
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
    [self initGestureRecognizers];
}

- (void)initGestureRecognizers
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
    [framesetter_ release];
    
    [horizontalRuleColor_ release];
    [verticalMarginColor_ release];

    [inputTextAttributes_ release];
    
    [visibleSections_ release];
    [reusableSections_ release];
    
    [underlayViews_ release];
    [overlayViews release];
    [selectionDisplayController_ release];
    [bandLoupe_ release];
    [roundLoupe_ release];

    [interimSelectedTextRange_ release];
    [selectedTextRange_ release];
    [markedTextRange_ release];
    [markedTextStyle_ release];
    [markedText_ release];

    [tokenizer_ release];

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
    size.height = self.framesetter.frameSize.height + margins_.top + margins_.bottom;
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
}

- (void)setLineHeight:(CGFloat)lineHeight 
{
    lineHeight_ = lineHeight;
    [self regenerateContents];
}

- (void)setHorizontalRulesEnabled:(BOOL)horizontalRulesEnabled
{
    if (horizontalRulesEnabled_ == horizontalRulesEnabled)
    {
        return;
    }
    
    horizontalRulesEnabled_ = horizontalRulesEnabled;
    [self regenerateContents];
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
    section.framesetter = self.framesetter;
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

#pragma mark Framesetting

- (CGFloat)lineWidth
{
    return self.bounds.size.width - margins_.left - margins_.right;
}

- (void)invalidateFramesetter
{
    [framesetter_ release];
    framesetter_ = nil;
}

- (void)regenerateContents
{
    [self invalidateFramesetter];
    [self untileVisibleSections];
    [self tileSections];
    [self updateContentSize];
    [selectionDisplayController_ updateSelectionElements];
}

- (NKTFramesetter *)framesetter
{
    if (framesetter_ == nil)
    {
        framesetter_ = [[NKTFramesetter alloc] initWithText:text_ lineWidth:[self lineWidth] lineHeight:lineHeight_];
    }
    
    return framesetter_;    
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
    
    [self setSelectedTextRange:nil affinity:UITextStorageDirectionForward notifyInputDelegate:NO];
    selectionDisplayController_.caretVisible = NO;

    if ([self.delegate respondsToSelector:@selector(textViewDidEndEditing:)])
    {
        [self.delegate textViewDidEndEditing:self];
    }
    
    return YES;
}

- (BOOL)becomeFirstResponder
{
    BOOL becameFirstResponder = [super becomeFirstResponder];
    selectionDisplayController_.caretVisible = YES;
    return becameFirstResponder;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Responding to Gestures

- (CGPoint)convertPointToFramesetter:(CGPoint)point
{
    return CGPointMake(point.x - margins_.left, point.y - margins_.top);
}

- (void)handleTap:(UIGestureRecognizer *)gestureRecognizer
{
    BOOL becameFirstResponder = NO;
    
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
    
    CGPoint touchLocation = [gestureRecognizer locationInView:self];
    CGPoint framesetterPoint = [self convertPointToFramesetter:touchLocation];
    UITextStorageDirection affinity = UITextStorageDirectionForward;
    NKTTextPosition *textPosition = [self.framesetter closestLogicalTextPositionToPoint:framesetterPoint
                                                                               affinity:&affinity];
    [self setSelectedTextRange:[textPosition textRange] affinity:affinity notifyInputDelegate:YES];
    
    // Marked text loses provisional status if selected text range moves outside it
    if (![markedTextRange_ containsTextPosition:textPosition])
    {
        self.markedTextRange = nil;
    }
    
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
        CGPoint framesetterPoint = [self convertPointToFramesetter:touchLocation];
        NKTTextPosition *textPosition = nil;
        UITextStorageDirection affinity = UITextStorageDirectionForward;
        
        // Text position computation depends on whether there is marked text or not
        if (markedTextRange_ != nil && !markedTextRange_.empty)
        {
            textPosition = [self.framesetter closestGeometricTextPositionToPoint:framesetterPoint affinity:&affinity];
            [self configureLoupe:self.bandLoupe toMagnifyTextPosition:textPosition];
            [self.bandLoupe setHidden:NO animated:YES];
        }
        else
        {
            textPosition = [self.framesetter closestLogicalTextPositionToPoint:framesetterPoint affinity:&affinity];
            [self configureLoupe:self.roundLoupe toMagnifyPoint:touchLocation anchorToClosestLine:NO];
            [self.roundLoupe setHidden:NO animated:YES];
        }
        
        [self setInterimSelectedTextRange:[textPosition textRange] affinity:affinity];
        selectionDisplayController_.caretVisible = YES;
    }
    else
    {
        [self confirmInterimSelectedTextRange];
        [self.bandLoupe setHidden:YES animated:YES];
        [self.roundLoupe setHidden:YES animated:YES];
        selectionDisplayController_.caretVisible = [self isFirstResponder];
    }
}

- (void)handleDoubleTapAndDrag:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint touchLocation = [gestureRecognizer locationInView:self];
    CGPoint framesetterPoint = [self convertPointToFramesetter:touchLocation];
    UITextStorageDirection affinity = UITextStorageDirectionForward;
    NKTTextPosition *textPosition = [self.framesetter closestLogicalTextPositionToPoint:framesetterPoint
                                                                               affinity:&affinity];
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        self.doubleTapStartTextPosition = textPosition;
        [self setInterimSelectedTextRange:[textPosition textRange] affinity:affinity];
    }
    else if (gestureRecognizer.state == UIGestureRecognizerStateChanged)
    {
        [self configureLoupe:self.bandLoupe toMagnifyPoint:touchLocation anchorToClosestLine:YES];
        [self.bandLoupe setHidden:NO animated:YES];
        NKTTextRange *textRange = [self.doubleTapStartTextPosition textRangeWithTextPosition:textPosition];
        [self setInterimSelectedTextRange:textRange affinity:affinity];
    }
    else
    {
        [self confirmInterimSelectedTextRange];
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
        NKTLine *line = [self.framesetter lineClosestToPoint:point];
        CGPoint zoomCenter = CGPointMake(point.x, line.origin.y);
        loupe.zoomCenter = [self convertPoint:zoomCenter toView:loupe.zoomedView];
        // Anchor loupe to a point just on top of the line with the same offset as the original point
        CGPoint anchor = CGPointMake(point.x, line.origin.y - (lineHeight_ * 0.8));
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
    CGPoint sourcePoint = [self.framesetter originForCharAtTextPosition:textPosition affinity:selectionAffinity_];
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
        NSUInteger inheritedAttributesIndex = replacementTextRange.start.location;
        
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
        [text_ replaceCharactersInRange:replacementTextRange.range withString:text];
    }
    else
    {
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:text
                                                                               attributes:inputTextAttributes];
        [text_ replaceCharactersInRange:replacementTextRange.range withAttributedString:attributedString];
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
    [self setSelectedTextRange:[textPosition textRange] affinity:UITextStorageDirectionForward notifyInputDelegate:NO];
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
    
    [text_ deleteCharactersInRange:deletionTextRange.range];
    [self regenerateContents];
    
    // Notify delegate
    if ([self.delegate respondsToSelector:@selector(textViewDidChange:)])
    {
        [self.delegate textViewDidChange:self];
    }
    
    // The marked text range no longer exists
    self.markedTextRange = nil;
    [self setSelectedTextRange:[deletionTextRange.start textRange]
                      affinity:UITextStorageDirectionForward
           notifyInputDelegate:NO];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Replacing and Returning Text

// UITextInput method
//
- (NSString *)textInRange:(NKTTextRange *)textRange
{
//    KBCLogDebug(@"range: %@", NSStringFromRange(textRange.NSRange));
    
    return [[text_ string] substringWithRange:textRange.range];
}

// UITextInput method
//
- (void)replaceRange:(NKTTextRange *)textRange withText:(NSString *)replacementText
{
    KBCLogDebug(@"range: %@ text: %@", NSStringFromRange(textRange.range), replacementText);
    
    [text_ replaceCharactersInRange:textRange.range withString:replacementText];
    [self regenerateContents];
    
    // The text range to be replaced lies fully before the selected text range
    if (textRange.end.location <= selectedTextRange_.start.location)
    {
        NSInteger changeInLength = [replacementText length] - textRange.length;
        NSUInteger newStartIndex = selectedTextRange_.start.location + changeInLength;
        NKTTextRange *newTextRange = [selectedTextRange_ textRangeByChangingLocation:newStartIndex];
        [self setSelectedTextRange:newTextRange affinity:UITextStorageDirectionForward notifyInputDelegate:NO];
    }
    // The text range overlaps the selected text range
    else if ((textRange.start.location >= selectedTextRange_.start.location) &&
             (textRange.start.location < selectedTextRange_.end.location))
    {
        NSUInteger newLength = textRange.start.location - selectedTextRange_.start.location;
        NKTTextRange *newTextRange = [selectedTextRange_ textRangeByChangingLength:newLength];
        [self setSelectedTextRange:newTextRange affinity:UITextStorageDirectionForward notifyInputDelegate:NO];
    }
}

//--------------------------------------------------------------------------------------------------

#pragma mark Managing Text Ranges

- (NKTTextRange *)interimSelectedTextRange
{
    return interimSelectedTextRange_;
}

- (void)setInterimSelectedTextRange:(NKTTextRange *)interimSelectedTextRange affinity:(UITextStorageDirection)affinity
{
    if (![interimSelectedTextRange_ isEqualToTextRange:interimSelectedTextRange])
    {
        [interimSelectedTextRange_ retain];
        [interimSelectedTextRange_ release];
        interimSelectedTextRange_ = interimSelectedTextRange_;
    }
    
    // The selection elements are updated because the caret might change even if the selected text
    // range did not change
    self.selectionAffinity = affinity;
    [selectionDisplayController_ updateSelectionElements];
}

- (void)confirmInterimSelectedTextRange
{
    [self setSelectedTextRange:interimSelectedTextRange_ affinity:selectionAffinity_ notifyInputDelegate:YES];
    [self setInterimSelectedTextRange:nil affinity:UITextStorageDirectionForward];
}

- (void)setSelectedTextRange:(NKTTextRange *)selectedTextRange
                    affinity:(UITextStorageDirection)affinity
         notifyInputDelegate:(BOOL)notifyInputDelegate
{
    if (![selectedTextRange_ isEqualToTextRange:selectedTextRange])
    {
        if (notifyInputDelegate)
        {
            [inputDelegate_ selectionWillChange:self];
        }
        
        [selectedTextRange_ release];
        selectedTextRange_ = [selectedTextRange copy];
        
        // The input text attributes are cleared when the selected text range changes
        self.inputTextAttributes = nil;
        
        if (notifyInputDelegate)
        {
            [inputDelegate_ selectionDidChange:self];
        }
        
        if ([self.delegate respondsToSelector:@selector(textViewDidChangeSelection:)])
        {
            [self.delegate textViewDidChangeSelection:self];
        }
    }
    
    // The selection elements are updated because the caret might change even if the selected text
    // range did not change
    self.selectionAffinity = affinity;
    [selectionDisplayController_ updateSelectionElements];
}

// UITextInput method
//
- (UITextRange *)selectedTextRange
{
    return selectedTextRange_;
}

// UITextInput method
//
- (void)setSelectedTextRange:(NKTTextRange *)selectedTextRange
{
    [self setSelectedTextRange:selectedTextRange affinity:UITextStorageDirectionForward notifyInputDelegate:NO];
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
    [text_ replaceCharactersInRange:replacementTextRange.range withAttributedString:attributedString];
    [attributedString release];
    
    [self regenerateContents];
    
    NKTTextRange *textRange = [replacementTextRange textRangeByChangingLength:[markedText_ length]];
    self.markedTextRange = textRange;
    
    // Update the selected text range within the marked text
    NSUInteger newIndex = markedTextRange_.start.location + relativeSelectedRange.location;
    NKTTextRange *newTextRange = [NKTTextRange textRangeWithRange:NSMakeRange(newIndex, relativeSelectedRange.length)];
    [self setSelectedTextRange:newTextRange affinity:UITextStorageDirectionForward notifyInputDelegate:NO];
    
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
    return selectionAffinity_;
}

// UITextInput method
//
- (void)setSelectionAffinity:(UITextStorageDirection)selectionAffinity
{
    selectionAffinity_ = selectionAffinity;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Computing Text Ranges and Text Positions

// UITextInput method
//
- (UITextRange *)textRangeFromPosition:(NKTTextPosition *)fromPosition toPosition:(NKTTextPosition *)toPosition
{
//    KBCLogDebug(@"%d : %d", fromPosition.index, toPosition.index);
    
    return [fromPosition textRangeWithTextPosition:toPosition];
}

// UITextInput method
//
- (UITextPosition *)positionFromPosition:(NKTTextPosition *)textPosition offset:(NSInteger)offset
{
//    KBCLogDebug(@"%d : %d", textPosition.index, offset);
    
    NSInteger index = (NSInteger)textPosition.location + offset;
    
    if (index < 0)
    {
        return [NKTTextPosition textPositionWithLocation:0];
    }
    else if (index > [text_ length])
    {
        return [NKTTextPosition textPositionWithLocation:[text_ length]];
    }
    
    return [NKTTextPosition textPositionWithLocation:index];
}

//--------------------------------------------------------------------------------------------------

// UITextInput method
//
- (UITextPosition *)positionFromPosition:(NKTTextPosition *)textPosition
                             inDirection:(UITextLayoutDirection)direction
                                  offset:(NSInteger)offset
{
//    KBCLogDebug(@"%d : %@ : %d", textPosition.index, KBTStringFromUITextDirection(direction), offset);
    
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
            // TODO: affinity affects this! Things change if we are at end of line or start of line ...
            
            NKTLine *initialLine = [self.framesetter lineContainingTextPosition:textPosition];
            
            // Return the beginning of document if offset puts the position above the first line
            if (offset > initialLine.index)
            {
                return [self beginningOfDocument];
            }
            
            NSUInteger targetLineIndex = initialLine.index - offset;
            NKTLine *targetLine = [self.framesetter lineAtIndex:targetLineIndex];
            CGPoint point = [self.framesetter originForCharAtTextPosition:textPosition affinity:selectionAffinity_];            
            CGPoint targetLinePoint = [self.framesetter convertPoint:point toLine:targetLine];
            return [targetLine closestTextPositionToPoint:targetLinePoint];
        }
        case UITextLayoutDirectionDown:
        {
            NKTLine *initialLine = [self.framesetter lineContainingTextPosition:textPosition];
            NSUInteger targetLineIndex = initialLine.index + offset;
            
            if (targetLineIndex >= self.framesetter.numberOfLines)
            {
                return [self endOfDocument];
            }
            
            NKTLine *targetLine = [self.framesetter lineAtIndex:targetLineIndex];
            CGPoint point = [self.framesetter originForCharAtTextPosition:textPosition affinity:selectionAffinity_];
            CGPoint targetLinePoint = [self.framesetter convertPoint:point toLine:targetLine];
            return [targetLine closestTextPositionToPoint:targetLinePoint];
        }
    }
    
    return offsetTextPosition;
}

// UITextInput method
//
- (UITextPosition *)beginningOfDocument
{
//    KBCLogTrace();
    
    return [NKTTextPosition textPositionWithLocation:0];
}

// UITextInput method
- (UITextPosition *)endOfDocument
{
//    KBCLogTrace();
    
    return [NKTTextPosition textPositionWithLocation:[text_ length]];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Evaluating Text Positions

// UITextInput method
//
- (NSComparisonResult)comparePosition:(NKTTextPosition *)textPosition toPosition:(NKTTextPosition *)otherTextPosition
{
//    KBCLogDebug(@"position: %d position: %d", textPosition.index, otherTextPosition.index);
    
    if (textPosition.location < otherTextPosition.location)
    {
        return NSOrderedAscending;
    }
    else if (textPosition.location > otherTextPosition.location)
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
    
    return (toPosition.location - fromPosition.location);
}

//--------------------------------------------------------------------------------------------------

#pragma mark Determining Layout and Writing Direction

// UITextInput method
//
- (UITextPosition *)positionWithinRange:(NKTTextRange *)textRange farthestInDirection:(UITextLayoutDirection)direction
{
    KBCLogDebug(@"range: %@ direction: %d", textRange.range, direction);
    
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

// UITextInput method
//
- (UITextRange *)characterRangeByExtendingPosition:(NKTTextPosition *)textPosition
                                       inDirection:(UITextLayoutDirection)direction
{
    KBCLogDebug(@"position: %d direction: %d", textPosition.location, direction);
    
    switch (direction)
    {
        case UITextLayoutDirectionRight:
        {
            NKTLine *line = [self.framesetter lineContainingTextPosition:textPosition];
            return [line.textRange textRangeByClippingUntilTextPosition:textPosition];
        }
        case UITextLayoutDirectionLeft:
        {
            NKTLine *line = [self.framesetter lineContainingTextPosition:textPosition];
            return [line.textRange textRangeByClippingFromTextPosition:textPosition];
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
    KBCLogDebug(@"position: %d direction: %d", textPosition.location, direction);

    return UITextWritingDirectionNatural;
}

- (void)setBaseWritingDirection:(UITextWritingDirection)writingDirection forRange:(NKTTextRange *)textRange
{
    KBCLogDebug(@"direction: %d range: %@", writingDirection, NSStringFromRange(textRange.range));
}

//--------------------------------------------------------------------------------------------------

#pragma mark Geometry and Hit-Testing

// If the end of the text range is the end of the text and ends in a line break, the last rect
// returned will span the end of the rect for the last line to take into account the presence
// of the subsequent non-typesetted line.
//
- (NSArray *)rectsForTextRange:(NKTTextRange *)textRange
{
    return [self.framesetter rectsForTextRange:textRange];
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

- (CGRect)caretRectForTextPosition:(NKTTextPosition *)textPosition
          applyInputTextAttributes:(BOOL)applyInputTextAttributes
{
    CGPoint charOrigin = [self.framesetter originForCharAtTextPosition:textPosition affinity:selectionAffinity_];
    UIFont *font = nil;
    
    if (applyInputTextAttributes)
    {
        KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithAttributes:self.inputTextAttributes];
        font = [styleDescriptor uiFontForFontStyle];
    }
    else
    {
        font = [self fontAtTextPosition:textPosition inDirection:UITextStorageDirectionForward];
    }
    
    return [self caretRectWithOrigin:charOrigin font:font];
}

// UITextInput method
//
- (CGRect)caretRectForPosition:(NKTTextPosition *)textPosition
{
    return [self caretRectForTextPosition:textPosition applyInputTextAttributes:NO];
}

// UITextInput method
//
// TODO: figure out when this is called by UITextInput, and implement accordingly
//
- (UITextPosition *)closestPositionToPoint:(CGPoint)point
{
//    KBCLogDebug(@"point: %@", NSStringFromCGPoint(point));
    return [self.framesetter closestLogicalTextPositionToPoint:point affinity:NULL];
}

// UITextInput method
//
// TODO: figure out when this is called by UITextInput, and implement accordingly .. returns nil for now
//
- (UITextPosition *)closestPositionToPoint:(CGPoint)point withinRange:(NKTTextRange *)textRange
{
    KBCLogDebug(@"******* point: %@ range: %@ *******", NSStringFromCGPoint(point), NSStringFromRange(textRange.range));
    return nil;
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
    KBCLogDebug(@"position: %d direction: %d", textPosition.location, direction);
    
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
    
    NSUInteger index = textRange.start.location;
    
    while (index < textRange.end.location)
    {
        NSRange longestEffectiveRange;
        NSDictionary *attributes = [text_ attributesAtIndex:index
                                      longestEffectiveRange:&longestEffectiveRange
                                                    inRange:selectedTextRange_.range];
        NSDictionary *newAttributes = [target performSelector:selector withObject:attributes];
        
        if (newAttributes != attributes)
        {
            [text_ setAttributes:newAttributes range:longestEffectiveRange];
        }
        
        index = longestEffectiveRange.location + longestEffectiveRange.length;
    }
    
    [self regenerateContents];
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
        return [self.text attributesAtIndex:textPosition.location effectiveRange:NULL];
    }
    // The typing attributes at the beginning of a paragraph are the attributes for the first
    // character of the paragraph
    else if ((textPosition.location < [self.text length]) &&
             [self.tokenizer isPosition:textPosition
                             atBoundary:UITextGranularityParagraph
                            inDirection:UITextStorageDirectionForward])
    {
        return [self.text attributesAtIndex:textPosition.location effectiveRange:NULL];
    }
    // Selected text range is empty, use the typing attributes for the character preceding the
    // insertion point if possible
    else
    {
        NSUInteger index = textPosition.location;
        
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
    [selectionDisplayController_ updateSelectionElements];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Fonts at Text Positions

// Note that the direction is ignored in this implementation.
//
- (UIFont *)fontAtTextPosition:(NKTTextPosition *)textPosition inDirection:(UITextStorageDirection)direction;
{
    UIFont *font = nil;
    
    if (text_ == nil || [text_ length] == 0)
    {
        return [UIFont systemFontOfSize:[UIFont systemFontSize]];
    }
    
    // Read the style information at the character preceding the index because that is the style that
    // would be used when text is inserted at that position
    
    NSUInteger sourceIndex = textPosition.location;
    
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

- (NKTTextRange *)textRangeForLineContainingTextPosition:(NKTTextPosition *)textPosition
{
    NKTLine *line = [self.framesetter lineContainingTextPosition:textPosition];
    return line.textRange;
}

@end
