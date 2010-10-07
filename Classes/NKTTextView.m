//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#define KBC_LOGGING_DISABLE_DEBUG_OUTPUT 1

#import "NKTTextView.h"
#import "KobaText.h"
#import "NKTDragGestureRecognizer.h"
#import "NKTFramesetter.h"
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
- (void)initGestureRecognizers;

#pragma mark Tiling Sections

- (void)tileSections;
- (void)untileVisibleSections;
- (BOOL)isDisplayingSectionAtIndex:(NSInteger)index;
- (NKTTextSection *)dequeueReusableSection;
- (void)configureSection:(NKTTextSection *)section atIndex:(NSInteger)index;
- (CGRect)frameForSectionAtIndex:(NSInteger)index;

#pragma mark Managing the Framesetter

@property (nonatomic, readonly) CGFloat lineWidth;
@property (nonatomic, readonly) NKTFramesetter *framesetter;

- (void)invalidateFramesetter;
- (void)regenerateTextFrame;
- (CGPoint)convertPointToFramesetter:(CGPoint)point;
- (CGPoint)convertPointFromFramesetter:(CGPoint)point;
- (CGAffineTransform)viewToFramesetterTransform;
- (CGAffineTransform)framesetterToViewTransform;

#pragma mark Responding to Gestures

@property (nonatomic, retain) NKTTextPosition *initialDoubleTapTextPosition;

- (void)handleTap:(UIGestureRecognizer *)gestureRecognizer;
- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer;
- (void)handleDoubleTapAndDrag:(UIGestureRecognizer *)gestureRecognizer;

#pragma mark Managing Loupes

@property (nonatomic, readonly) NKTLoupe *textRangeLoupe;
@property (nonatomic, readonly) NKTLoupe *caretLoupe;

- (void)configureLoupe:(NKTLoupe *)loupe toShowPoint:(CGPoint)point anchorToLine:(BOOL)anchorToLine;
- (void)configureLoupe:(NKTLoupe *)loupe toShowTextPosition:(NKTTextPosition *)textPosition;

#pragma mark Managing Text Ranges

@property (nonatomic, readwrite) NKTTextRange *gestureTextRange;

- (void)confirmGestureTextRange;
- (void)setSelectedTextRange:(NKTTextRange *)textRange notifyInputDelegate:(BOOL)notifyInputDelegate;
- (void)setMarkedTextRange:(NKTTextRange *)textRange;

#pragma mark Geometry and Hit-Testing

- (CGRect)caretRectForTextPosition:(NKTTextPosition *)textPosition applyInputTextAttributes:(BOOL)applyInputTextAttributes;
- (CGRect)caretRectWithOrigin:(CGPoint)origin font:(UIFont *)font;

#pragma mark Getting Fonts at Text Positions

- (UIFont *)fontAtTextPosition:(NKTTextPosition *)textPosition;

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

@synthesize markedTextStyle = markedTextStyle_;

@synthesize inputTextAttributes = inputTextAttributes_;

@synthesize inputDelegate = inputDelegate_;

@synthesize nonEditTapGestureRecognizer = nonEditTapGestureRecognizer_;
@synthesize tapGestureRecognizer = tapGestureRecognizer_;
@synthesize longPressGestureRecognizer = longPressGestureRecognizer_;
@synthesize doubleTapAndDragGestureRecognizer = doubleTapAndDragGestureRecognizer_;
@synthesize initialDoubleTapTextPosition = initialDoubleTapTextPosition_;

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
    
    [horizontalRuleColor_ release];
    [verticalMarginColor_ release];

    [framesetter_ release];
    
    [visibleSections_ release];
    [reusableSections_ release];
    
    [underlayViews_ release];
    [overlayViews release];
    [selectionDisplayController_ release];
    [textRangeLoupe_ release];
    [caretLoupe_ release];

    [gestureTextRange_ release];
    [selectedTextRange_ release];
    [markedTextRange_ release];
    [markedTextStyle_ release];
    [markedText_ release];
    
    [inputTextAttributes_ release];
    
    [tokenizer_ release];
    
    [gestureRecognizerDelegate_ release];
    [nonEditTapGestureRecognizer_ release];
    [tapGestureRecognizer_ release];
    [longPressGestureRecognizer_ release];
    [doubleTapAndDragGestureRecognizer_ release];
    [initialDoubleTapTextPosition_ release];
    
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
    [self regenerateTextFrame];
    [selectionDisplayController_ updateSelectionDisplay];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Laying out Views

// Called when scrolling occurs (behavior inherited from UIScrollView). We tile the sections as
// neccesary whenever scrolling occurs.
- (void)layoutSubviews 
{
    [super layoutSubviews];
    [self tileSections];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Accessing the Text

- (void)setText:(NSAttributedString *)text
{
    if (text_ == text)
    {
        return;
    }
    
    [text_ release];
    text_ = [[NSMutableAttributedString alloc] initWithAttributedString:text];
    [self regenerateTextFrame];
    self.gestureTextRange = nil;
    self.selectedTextRange = nil;
    self.markedTextRange = nil;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Configuring Text Layout and Style

- (void)setMargins:(UIEdgeInsets)margins
{
    margins_ = margins;
    [self regenerateTextFrame];
    [selectionDisplayController_ updateSelectionDisplay];
}

- (void)setLineHeight:(CGFloat)lineHeight 
{
    lineHeight_ = lineHeight;
    [self regenerateTextFrame];
    [selectionDisplayController_ updateSelectionDisplay];
}

- (void)setHorizontalRulesEnabled:(BOOL)horizontalRulesEnabled
{   
    horizontalRulesEnabled_ = horizontalRulesEnabled;
    [self untileVisibleSections];
    [self tileSections];
}

- (void)setHorizontalRuleColor:(UIColor *)horizontalRuleColor
{
    [horizontalRuleColor_ release];
    horizontalRuleColor_ = [horizontalRuleColor retain];
    [self untileVisibleSections];
    [self tileSections];
}

- (void)setHorizontalRuleOffset:(CGFloat)horizontalRuleOffset
{
    horizontalRuleOffset_ = horizontalRuleOffset;
    [self untileVisibleSections];
    [self tileSections];
}

- (void)setVerticalMarginEnabled:(BOOL)verticalMarginEnabled
{
    verticalMarginEnabled_ = verticalMarginEnabled;
    [self untileVisibleSections];
    [self tileSections];
}

- (void)setVerticalMarginColor:(UIColor *)verticalMarginColor
{
    [verticalMarginColor_ release];
    verticalMarginColor_ = [verticalMarginColor retain];
    [self untileVisibleSections];
    [self tileSections];
}

- (void)setVerticalMarginInset:(CGFloat)verticalMarginInset
{
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
                section = [[NKTTextSection alloc] initWithFrame:bounds];
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

#pragma mark Managing the Framesetter

- (CGFloat)lineWidth
{
    return self.bounds.size.width - margins_.left - margins_.right;
}

- (NKTFramesetter *)framesetter
{
    if (framesetter_ == nil)
    {
        framesetter_ = [[NKTFramesetter alloc] initWithText:text_ lineWidth:[self lineWidth] lineHeight:lineHeight_];
    }
    
    return framesetter_;    
}

- (void)invalidateFramesetter
{
    [framesetter_ release];
    framesetter_ = nil;
}

- (void)regenerateTextFrame
{
    [self invalidateFramesetter];
    [self untileVisibleSections];
    [self tileSections];
    [self updateContentSize];
}

- (CGPoint)convertPointToFramesetter:(CGPoint)point
{
    return CGPointMake(point.x - margins_.left, point.y - margins_.top);
}

- (CGPoint)convertPointFromFramesetter:(CGPoint)point
{
    return CGPointMake(point.x + margins_.left, point.y + margins_.top);
}

- (CGAffineTransform)viewToFramesetterTransform
{
    return CGAffineTransformMakeTranslation(-margins_.left, -margins_.top);    
}

- (CGAffineTransform)framesetterToViewTransform
{
    return CGAffineTransformMakeTranslation(margins_.left, margins_.top);
}

//--------------------------------------------------------------------------------------------------

#pragma mark Managing the Responder Chain

// Returning YES allows the view to receive keyboard input
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
    
    self.gestureTextRange = nil;
    [self setSelectedTextRange:nil notifyInputDelegate:NO];
    self.markedTextRange = nil;
    
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
    
    CGPoint point = [gestureRecognizer locationInView:self];
    CGPoint framesetterPoint = [self convertPointToFramesetter:point];
    NKTTextPosition *textPosition = [self.framesetter closestTextPositionForCaretToPoint:framesetterPoint];
    [self setSelectedTextRange:[textPosition textRange] notifyInputDelegate:YES];
    self.markedTextRange = nil;
    selectionDisplayController_.caretVisible = YES;
    
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
        CGPoint point = [gestureRecognizer locationInView:self];
        CGPoint framesetterPoint = [self convertPointToFramesetter:point];
        NKTTextPosition *textPosition = [self.framesetter closestTextPositionForCaretToPoint:framesetterPoint];
        self.gestureTextRange = [textPosition textRange];
        self.markedTextRange = nil;
        [self configureLoupe:self.caretLoupe toShowPoint:point anchorToLine:NO];
        [self.caretLoupe setHidden:NO animated:YES];
        selectionDisplayController_.caretVisible = YES;
    }
    else
    {
        [self confirmGestureTextRange];
        [self.caretLoupe setHidden:YES animated:YES];
        selectionDisplayController_.caretVisible = [self isFirstResponder];
    }
}

- (void)handleDoubleTapAndDrag:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint point = [gestureRecognizer locationInView:self];
    CGPoint framesetterPoint = [self convertPointToFramesetter:point];
    NKTTextPosition *textPosition = [self.framesetter closestTextPositionForCaretToPoint:framesetterPoint];
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        self.initialDoubleTapTextPosition = textPosition;
        self.gestureTextRange = [textPosition textRange];
        self.markedTextRange = nil;
    }
    else if (gestureRecognizer.state == UIGestureRecognizerStateChanged)
    {
        self.gestureTextRange = [NKTTextRange textRangeWithTextPosition:self.initialDoubleTapTextPosition
                                                           textPosition:textPosition];
        [self configureLoupe:self.textRangeLoupe toShowPoint:point anchorToLine:YES];
        [self.textRangeLoupe setHidden:NO animated:YES];
    }
    else
    {
        self.initialDoubleTapTextPosition = nil;
        [self confirmGestureTextRange];
        [self.textRangeLoupe setHidden:YES animated:YES];
    }
}

//--------------------------------------------------------------------------------------------------

#pragma mark Managing Loupes

- (NKTLoupe *)textRangeLoupe
{    
    if (textRangeLoupe_ == nil)
    {
        textRangeLoupe_ = [[NKTLoupe alloc] initWithStyle:NKTLoupeStyleBand];
        textRangeLoupe_.hidden = YES;
        textRangeLoupe_.zoomedView = self;
        
        if ([self.delegate respondsToSelector:@selector(loupeFillColor)])
        {
            textRangeLoupe_.fillColor = [self.delegate loupeFillColor];
        }
        
        if ([self.delegate respondsToSelector:@selector(addLoupeView:)])
        {
            [self.delegate addLoupe:textRangeLoupe_];
        }
        else
        {
            [self.superview addSubview:textRangeLoupe_];
        }
    }
    
    return textRangeLoupe_;
}

- (NKTLoupe *)caretLoupe
{
    if (caretLoupe_ == nil)
    {
        caretLoupe_ = [[NKTLoupe alloc] initWithStyle:NKTLoupeStyleRound];
        caretLoupe_.hidden = YES;
        caretLoupe_.zoomedView = self;

        if ([self.delegate respondsToSelector:@selector(loupeFillColor)])
        {
            caretLoupe_.fillColor = [self.delegate loupeFillColor];
        }
        
        if ([self.delegate respondsToSelector:@selector(addLoupeView:)])
        {
            [self.delegate addLoupe:caretLoupe_];
        }
        else
        {
            [self.superview addSubview:caretLoupe_];
        }
    }
    
    return caretLoupe_;
}

- (void)configureLoupe:(NKTLoupe *)loupe toShowPoint:(CGPoint)point anchorToLine:(BOOL)anchorToLine
{
    if (anchorToLine)
    {
        // Set the zoom center of the loupe to the baseline with the same offset as the original point
        CGPoint framesetterPoint = [self convertPointToFramesetter:point];
        NKTLine *line = [self.framesetter lineClosestToPoint:framesetterPoint];
        CGPoint baselineOrigin = [self convertPointFromFramesetter:line.baselineOrigin];
        CGPoint zoomCenter = CGPointMake(point.x, baselineOrigin.y);
        loupe.zoomCenter = [self convertPoint:zoomCenter toView:loupe.zoomedView];
        // Anchor loupe to a point just on top of the line
        CGPoint anchor = CGPointMake(point.x, baselineOrigin.y - (lineHeight_ * 0.75));
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
}

- (void)configureLoupe:(NKTLoupe *)loupe toShowTextPosition:(NKTTextPosition *)textPosition
{
    CGPoint framesetterPoint = [self.framesetter baselineOriginForCharAtTextPosition:textPosition];
    CGPoint point = [self convertPointFromFramesetter:framesetterPoint];
    loupe.zoomCenter = [self convertPoint:point toView:loupe.zoomedView];
    // Anchor loupe to a point just on top of the text position
    CGPoint anchor = CGPointMake(point.x, point.y - (lineHeight_ * 0.75));
    anchor = KBCClampPointToRect(anchor, self.bounds);
    loupe.anchor = [self convertPoint:anchor toView:loupe.superview];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Inserting and Deleting Text

// UITextInput method
- (BOOL)hasText
{
    KBCLogDebug(@"");
    return [text_ length] > 0;
}

// UITextInput method
- (void)insertText:(NSString *)text
{
    KBCLogDebug(text);
    
    if (markedTextRange_ == nil && selectedTextRange_ == nil)
    {
        KBCLogWarning(@"marked text range and selected text range are both nil, ignoring");
        return;
    }
    
    // Figure out the attributes that inserted text needs to have
    NSDictionary *inputTextAttributes = self.inputTextAttributes;
    NKTTextRange *insertionTextRange = (markedTextRange_ != nil) ? markedTextRange_ : selectedTextRange_;
    NSDictionary *inheritedAttributes = nil;
    
    if ([self hasText])
    {
        NSUInteger inheritedAttributesIndex = insertionTextRange.start.location;
        
        // If the replacement range is empty, inserted characters inherit the attributes of the
        // character preceding the range, if any.
        if (insertionTextRange.empty && inheritedAttributesIndex > 0)
        {
            inheritedAttributesIndex = inheritedAttributesIndex - 1;
        }
        else if (inheritedAttributesIndex > [text_ length])
        {
            inheritedAttributesIndex = [text_ length] - 1;
        }
        
        inheritedAttributes = [text_ attributesAtIndex:inheritedAttributesIndex effectiveRange:NULL];
    }
    
    // It is possible to avoid creating a new range of attributed text if the attributes that
    // would be inherited from the string following insertion match the insertion attributes
    if ([inheritedAttributes isEqualToDictionary:inputTextAttributes])
    {
        [text_ replaceCharactersInRange:insertionTextRange.range withString:text];
    }
    else
    {
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:text
                                                                               attributes:inputTextAttributes];
        [text_ replaceCharactersInRange:insertionTextRange.range withAttributedString:attributedString];
        [attributedString release];
    }
    
    // TODO: extract a method for this block
    [self.framesetter textChangedFromTextPosition:insertionTextRange.start];
    [self untileVisibleSections];
    [self tileSections];
    [self updateContentSize];
    
    if ([self.delegate respondsToSelector:@selector(textViewDidChange:)])
    {
        [self.delegate textViewDidChange:self];
    }
    
    NKTTextPosition *textPosition = [insertionTextRange.start textPositionByApplyingOffset:[text length]];
    [self setSelectedTextRange:[textPosition textRange] notifyInputDelegate:NO];
    self.markedTextRange = nil;
}

// UITextInput method
- (void)deleteBackward
{
    KBCLogDebug(@"");
    
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
    // TODO: frameset intelligently
    [self regenerateTextFrame];
    
    if ([self.delegate respondsToSelector:@selector(textViewDidChange:)])
    {
        [self.delegate textViewDidChange:self];
    }
    
    [self setSelectedTextRange:[deletionTextRange.start textRange] notifyInputDelegate:NO];
    self.markedTextRange = nil;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Replacing and Returning Text

// UITextInput method
- (NSString *)textInRange:(NKTTextRange *)textRange
{
    KBCLogDebug(@"%@", textRange);
    // TODO: optimization, return text_ if entire range requested
    return [[text_ string] substringWithRange:textRange.range];
}

// UITextInput method
- (void)replaceRange:(NKTTextRange *)textRange withText:(NSString *)replacementText
{
    KBCLogDebug(@"%@ : %@", textRange, replacementText);
    [text_ replaceCharactersInRange:textRange.range withString:replacementText];
    // TODO: frameset intelligently
    [self regenerateTextFrame];
    
    // The text range to be replaced lies fully before the selected text range
    if (textRange.end.location <= selectedTextRange_.start.location)
    {
        NSInteger changeInLength = [replacementText length] - textRange.length;
        NSUInteger newStartIndex = selectedTextRange_.start.location + changeInLength;
        NKTTextRange *newTextRange = [selectedTextRange_ textRangeByChangingLocation:newStartIndex];
        [self setSelectedTextRange:newTextRange notifyInputDelegate:NO];
    }
    // The text range overlaps the selected text range
    else if ((textRange.start.location >= selectedTextRange_.start.location) &&
             (textRange.start.location < selectedTextRange_.end.location))
    {
        NSUInteger newLength = textRange.start.location - selectedTextRange_.start.location;
        NKTTextRange *newTextRange = [selectedTextRange_ textRangeByChangingLength:newLength];
        [self setSelectedTextRange:newTextRange notifyInputDelegate:NO];
    }
}

//--------------------------------------------------------------------------------------------------

#pragma mark Managing Text Ranges

- (NKTTextRange *)gestureTextRange
{
    return gestureTextRange_;
}

- (void)setGestureTextRange:(NKTTextRange *)textRange
{
    if (![gestureTextRange_ isEqualToTextRange:textRange])
    {
        [gestureTextRange_ release];
        gestureTextRange_ = [textRange copy];
    }
    
    [selectionDisplayController_ updateSelectionDisplay];
}

- (void)confirmGestureTextRange
{
    [self setSelectedTextRange:gestureTextRange_ notifyInputDelegate:YES];
    self.gestureTextRange = nil;
}

// UITextInput method
- (UITextRange *)selectedTextRange
{
    return selectedTextRange_;
}

// UITextInput method
- (void)setSelectedTextRange:(NKTTextRange *)textRange
{
    // TODO/HACK/NOTE:
    // Always notify the input delegate when this method is called. The UITextInput system seem
    // to expect this method to notify the system when the selected text range is set. For
    // example, the UITextInput autocorrection prompts do not dismiss when the keyboard navigates
    // away from the text position (through this method) unless we notify the input delegate that
    // the selected text range has changed.
    [self setSelectedTextRange:textRange notifyInputDelegate:YES];
}

- (void)setSelectedTextRange:(NKTTextRange *)textRange notifyInputDelegate:(BOOL)notifyInputDelegate
{
    if (![selectedTextRange_ isEqualToTextRange:textRange])
    {
        if (notifyInputDelegate)
        {
            [inputDelegate_ selectionWillChange:self];
        }
        
        [selectedTextRange_ release];
        selectedTextRange_ = [textRange copy];
        
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
    
    [selectionDisplayController_ updateSelectionDisplay];
}

// UITextInput method
- (UITextRange *)markedTextRange
{
    return markedTextRange_;
}

- (void)setMarkedTextRange:(NKTTextRange *)textRange
{
    if (![markedTextRange_  isEqualToTextRange:textRange])
    {
        [markedTextRange_ release];
        markedTextRange_ = [textRange copy];
    }
    
    [selectionDisplayController_ updateSelectionDisplay];
}

// UITextInput method
- (void)setMarkedText:(NSString *)markedText selectedRange:(NSRange)relativeSelectedRange
{
    KBCLogDebug(@"%@ : %@", markedText, NSStringFromRange(relativeSelectedRange));
    // TODO: accessor for marked text property
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
    
    // TODO: frameset intelligently
    [self regenerateTextFrame];
    
    NKTTextRange *textRange = [replacementTextRange textRangeByChangingLength:[markedText_ length]];
    self.markedTextRange = textRange;
    
    // Update the selected text range within the marked text
    NSRange range = NSMakeRange(markedTextRange_.start.location + relativeSelectedRange.location,
                                relativeSelectedRange.length);
    NKTTextRange *newTextRange = [NKTTextRange textRangeWithRange:range affinity:UITextStorageDirectionForward];
    [self setSelectedTextRange:newTextRange notifyInputDelegate:NO];
    
    // Input text attributes are reset when marked text is set
    self.inputTextAttributes = nil;
}

// UITextInput method
- (void)unmarkText
{
    self.markedTextRange = nil;
    [markedText_ release];
    markedText_ = nil;
}

// UITextInput method
- (UITextStorageDirection)selectionAffinity
{
    return (selectedTextRange_ != nil) ? selectedTextRange_.affinity : UITextStorageDirectionForward;
}

// UITextInput method
- (void)setSelectionAffinity:(UITextStorageDirection)direction
{
    KBCLogWarning(@"unexpected method call");
}

//--------------------------------------------------------------------------------------------------

#pragma mark Computing Text Ranges and Text Positions

// UITextInput method
- (UITextRange *)textRangeFromPosition:(NKTTextPosition *)fromPosition toPosition:(NKTTextPosition *)toPosition
{
    KBCLogDebug(@"%@ : %@", fromPosition, toPosition);    
    return [NKTTextRange textRangeWithTextPosition:fromPosition textPosition:toPosition];
}

// UITextInput method
- (UITextPosition *)positionFromPosition:(NKTTextPosition *)textPosition offset:(NSInteger)offset
{
    KBCLogDebug(@"%@ : %d", textPosition, offset);    
    NSInteger location = (NSInteger)textPosition.location + offset;
    
    if (location < 0)
    {
        return [NKTTextPosition textPositionWithLocation:0 affinity:UITextStorageDirectionForward];
    }
    else if (location > [text_ length])
    {
        return [NKTTextPosition textPositionWithLocation:[text_ length] affinity:UITextStorageDirectionForward];
    }
    else
    {
        return [NKTTextPosition textPositionWithLocation:(NSUInteger)location affinity:UITextStorageDirectionForward];
    }
}

// UITextInput method
- (UITextPosition *)positionFromPosition:(NKTTextPosition *)textPosition
                             inDirection:(UITextLayoutDirection)direction
                                  offset:(NSInteger)offset
{
    KBCLogDebug(@"%@ : %@ : %d", textPosition, KBTStringFromUITextDirection(direction), offset);    
    
    switch (direction)
    {
        case UITextLayoutDirectionRight:
        {
            return [self positionFromPosition:textPosition offset:offset];
        }
        case UITextLayoutDirectionLeft:
        {
            return [self positionFromPosition:textPosition offset:-offset];
        }
        case UITextLayoutDirectionUp:
        {
            NKTLine *initialLine = [self.framesetter lineForCaretAtTextPosition:textPosition];
            
            if (offset > initialLine.index)
            {
                return [self beginningOfDocument];
            }
            
            NSUInteger targetLineIndex = initialLine.index - offset;
            NKTLine *targetLine = [self.framesetter lineAtIndex:targetLineIndex];
            CGPoint framesetterPoint = [self.framesetter baselineOriginForCharAtTextPosition:textPosition];
            return [targetLine closestTextPositionForCaretToPoint:framesetterPoint];
        }
        case UITextLayoutDirectionDown:
        {
            NKTLine *initialLine = [self.framesetter lineForCaretAtTextPosition:textPosition];
            NSUInteger targetLineIndex = initialLine.index + offset;
            
            if (targetLineIndex >= self.framesetter.numberOfLines)
            {
                return [self endOfDocument];
            }
            
            NKTLine *targetLine = [self.framesetter lineAtIndex:targetLineIndex];
            CGPoint framesetterPoint = [self.framesetter baselineOriginForCharAtTextPosition:textPosition];
            return [targetLine closestTextPositionForCaretToPoint:framesetterPoint];
        }
    }
    
    KBCLogWarning(@"unknown direction, returning nil");
    return nil;
}

// UITextInput method
- (UITextPosition *)beginningOfDocument
{
    return [NKTTextPosition textPositionWithLocation:0 affinity:UITextStorageDirectionForward];
}

// UITextInput method
- (UITextPosition *)endOfDocument
{
    return [NKTTextPosition textPositionWithLocation:[text_ length] affinity:UITextStorageDirectionForward];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Evaluating Text Positions

// UITextInput method
- (NSComparisonResult)comparePosition:(NKTTextPosition *)firstTextPosition
                           toPosition:(NKTTextPosition *)secondTextPosition
{
    KBCLogDebug(@"%@ : %@", firstTextPosition, secondTextPosition);
    
    // TODO: extract to NKTTextPosition
    
    if (firstTextPosition.location < secondTextPosition.location)
    {
        return NSOrderedAscending;
    }
    else if (firstTextPosition.location > secondTextPosition.location)
    {
        return NSOrderedDescending;
    }
    else
    {        
        return NSOrderedSame;
    }
}

// UITextInput method
- (NSInteger)offsetFromPosition:(NKTTextPosition *)fromPosition toPosition:(NKTTextPosition *)toPosition
{
    KBCLogDebug(@"%@ : %@", fromPosition, toPosition);
    // TODO: extract to NKTTextPosition
    return (toPosition.location - fromPosition.location);
}

//--------------------------------------------------------------------------------------------------

#pragma mark Determining Layout and Writing Direction

// UITextInput method
- (UITextPosition *)positionWithinRange:(NKTTextRange *)textRange farthestInDirection:(UITextLayoutDirection)direction
{
    KBCLogDebug(@"%@ : %@", textRange, KBTStringFromUITextDirection(direction));
    
    switch (direction)
    {
        case UITextLayoutDirectionRight:
        {
            return textRange.end;
        }
        case UITextLayoutDirectionLeft:
        {
            return textRange.start;
        }
        case UITextLayoutDirectionUp:
        {
            return textRange.start;
        }
        case UITextLayoutDirectionDown:
        {
            return textRange.end;
        }
    }
    
    KBCLogWarning(@"unknown direction, returning nil");
    return nil;
}

// UITextInput method
- (UITextRange *)characterRangeByExtendingPosition:(NKTTextPosition *)textPosition
                                       inDirection:(UITextLayoutDirection)direction
{
    KBCLogDebug(@"%@ : %@", textPosition, KBTStringFromUITextDirection(direction));
    
    switch (direction)
    {
        case UITextLayoutDirectionRight:
        {
            NKTLine *line = [self.framesetter lineForCaretAtTextPosition:textPosition];
            return [line.textRange textRangeByClippingUntilTextPosition:textPosition];
        }
        case UITextLayoutDirectionLeft:
        {
            NKTLine *line = [self.framesetter lineForCaretAtTextPosition:textPosition];
            return [line.textRange textRangeByClippingFromTextPosition:textPosition];
        }
        case UITextLayoutDirectionUp:
        {
            // TODO: redeclare beginningOfDocument? property only?
            return [NKTTextRange textRangeWithTextPosition:textPosition
                                              textPosition:(NKTTextPosition *)[self beginningOfDocument]];
        }
        case UITextLayoutDirectionDown:
        {
            return [NKTTextRange textRangeWithTextPosition:textPosition
                                              textPosition:(NKTTextPosition *)[self endOfDocument]];
        }
    }
    
    KBCLogWarning(@"unknown direction, returning nil");
    return nil;
}

// UITextInput method
- (UITextWritingDirection)baseWritingDirectionForPosition:(NKTTextPosition *)textPosition
                                              inDirection:(UITextStorageDirection)direction
{
    KBCLogDebug(@"%@ : %@", textPosition, KBTStringFromUITextDirection(direction));
    return UITextWritingDirectionNatural;
}

// UITextInput method
- (void)setBaseWritingDirection:(UITextWritingDirection)direction forRange:(NKTTextRange *)textRange
{
    KBCLogDebug(@"%@ : %@", KBTStringFromUITextDirection(direction), textRange);
}

//--------------------------------------------------------------------------------------------------

#pragma mark Geometry and Hit-Testing

// UITextInput method
- (CGRect)firstRectForRange:(NKTTextRange *)textRange
{
    KBCLogDebug(@"%@", textRange);
    NSArray *rects = [self rectsForTextRange:textRange];
    
    if (rects != nil)
    {
        return [[rects objectAtIndex:0] CGRectValue];
    }
    else
    {
        return CGRectNull;
    }
}

- (NSArray *)rectsForTextRange:(NKTTextRange *)textRange
{
    return [self.framesetter rectsForTextRange:textRange transform:[self framesetterToViewTransform]];
}

// UITextInput method
- (CGRect)caretRectForPosition:(NKTTextPosition *)textPosition
{
    return [self caretRectForTextPosition:textPosition applyInputTextAttributes:NO];
}

- (CGRect)caretRectForTextPosition:(NKTTextPosition *)textPosition applyInputTextAttributes:(BOOL)applyInputTextAttributes
{
    CGPoint framesetterPoint = [self.framesetter baselineOriginForCharAtTextPosition:textPosition];
    CGPoint charOrigin = [self convertPointFromFramesetter:framesetterPoint];
    UIFont *font = nil;
    
    if (applyInputTextAttributes)
    {
        KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithAttributes:self.inputTextAttributes];
        font = [styleDescriptor uiFontForFontStyle];
    }
    else
    {
        font = [self fontAtTextPosition:textPosition];
    }
    
    return [self caretRectWithOrigin:charOrigin font:font];
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

// UITextInput method
- (UITextPosition *)closestPositionToPoint:(CGPoint)point
{
    KBCLogDebug(@"%@", NSStringFromCGPoint(point));
    // TODO: figure out when this is called by UITextInput, and implement accordingly
    return [self.framesetter closestTextPositionForCaretToPoint:point];
}

// UITextInput method
- (UITextPosition *)closestPositionToPoint:(CGPoint)point withinRange:(NKTTextRange *)textRange
{
    KBCLogDebug(@"%@ : %@", NSStringFromCGPoint(point), textRange);
    // TODO: figure out when this is called by UITextInput, and implement accordingly
    return nil;
}

// UITextInput method
- (UITextRange *)characterRangeAtPoint:(CGPoint)point
{
    KBCLogDebug(@"%@", NSStringFromCGPoint(point));    
    // TODO: figure out when this is called by UITextInput, and implement accordingly
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
- (NSDictionary *)textStylingAtPosition:(NKTTextPosition *)textPosition inDirection:(UITextStorageDirection)direction
{
    // NOTE: it seems like UITextInput does not actually use the color and background color
    UIFont *font = [self fontAtTextPosition:textPosition];
    UIColor *color = [UIColor blackColor];
    UIColor *backgroundColor = self.backgroundColor;
    return [NSDictionary dictionaryWithObjectsAndKeys:font, UITextInputTextFontKey,
                                                      color, UITextInputTextColorKey,
                                                      backgroundColor, UITextInputTextBackgroundColorKey,
                                                      nil];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Styling Text

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
                            inDirection:UITextStorageDirectionBackward])
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
    [selectionDisplayController_ updateSelectionDisplay];
}

- (void)styleTextRange:(NKTTextRange *)textRange withTarget:(id)target selector:(SEL)selector
{
    if (textRange == nil || textRange.empty)
    {
        return;
    }
    
    NSUInteger currentLocation = textRange.start.location;
    
    while (currentLocation < textRange.end.location)
    {
        NSRange longestEffectiveRange;
        NSDictionary *attributes = [text_ attributesAtIndex:currentLocation
                                      longestEffectiveRange:&longestEffectiveRange
                                                    inRange:selectedTextRange_.range];
        NSDictionary *newAttributes = [target performSelector:selector withObject:attributes];
        
        if (newAttributes != attributes)
        {
            [text_ setAttributes:newAttributes range:longestEffectiveRange];
        }
        
        currentLocation = longestEffectiveRange.location + longestEffectiveRange.length;
    }
    
    [self regenerateTextFrame];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Fonts at Text Positions

- (UIFont *)fontAtTextPosition:(NKTTextPosition *)textPosition
{    
    if (![self hasText])
    {
        return [UIFont systemFontOfSize:[UIFont systemFontSize]];
    }
     
    // Read the style information at the character preceding the index because that is the style that
    // would be used when text is inserted at that position
    UIFont *font = nil;   
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

// TODO: look through these

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

// TODO: look through these

- (NKTTextRange *)textRangeForLineContainingTextPosition:(NKTTextPosition *)textPosition
{
    NKTLine *line = [self.framesetter lineForCaretAtTextPosition:textPosition];
    return line.textRange;
}

@end
