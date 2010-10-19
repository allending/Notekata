//
// Copyright 2010 Allen Ding. All rights reserved.
//

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

@property (nonatomic, retain) NKTTextRange *initialDoubleTapTextRange;

- (void)handleTap:(UIGestureRecognizer *)gestureRecognizer;

- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer;
- (void)updateLongPressSelection;

- (void)handleDoubleTapDrag:(UIGestureRecognizer *)gestureRecognizer;
- (void)updateDoubleTapDragSelection;

- (void)handleBackwardHandleDrag:(UIGestureRecognizer *)gestureRecognizer;
- (void)updateBackwardHandleDragSelection;

- (void)handleForwardHandleDrag:(UIGestureRecognizer *)gestureRecognizer;
- (void)updateForwardHandleDragSelection;

- (NKTTextRange *)gesturedWordRangeAtTextPosition:(NKTTextPosition *)textPosition;

#pragma mark Scrolling

- (void)startEdgeScrollCheckWithGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer selector:(SEL)selector;
- (void)stopEdgeScrollCheckWithGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer selector:(SEL)selector;
- (void)edgeScrollCheckWithInfo:(NSDictionary *)info;
- (void)scrollAtEdgeWithPoint:(CGPoint)point;

#pragma mark Managing Loupes

@property (nonatomic, readonly) NKTLoupe *textRangeLoupe;
@property (nonatomic, readonly) NKTLoupe *caretLoupe;

- (void)configureLoupe:(NKTLoupe *)loupe toShowPoint:(CGPoint)point anchorToLine:(BOOL)anchorToLine;
- (void)configureLoupe:(NKTLoupe *)loupe toShowTextPosition:(NKTTextPosition *)textPosition;

#pragma mark Managing Text Ranges

@property (nonatomic, readwrite) NKTTextRange *gestureTextRange;

- (void)confirmGestureTextRange;
- (void)setSelectedTextRange:(NKTTextRange *)textRange notifyInputDelegate:(BOOL)notifyInputDelegate;
- (void)setMarkedTextRange:(NKTTextRange *)textRange notifyInputDelegate:(BOOL)notifyInputDelegate;

#pragma mark Geometry and Hit-Testing

- (CGRect)caretRectForTextPosition:(NKTTextPosition *)textPosition applyInputTextAttributes:(BOOL)applyInputTextAttributes;
- (CGRect)caretRectWithOrigin:(CGPoint)origin font:(UIFont *)font;

#pragma mark Getting Fonts at Text Positions

- (UIFont *)fontAtTextPosition:(NKTTextPosition *)textPosition;

@end

#pragma mark -

@implementation NKTTextView

@synthesize text = text_;

@synthesize backgroundView = backgroundView_;

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
@synthesize doubleTapDragGestureRecognizer = doubleTapDragGestureRecognizer_;
@synthesize initialDoubleTapTextRange = initialDoubleTapTextRange_;

#pragma mark -
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
    lineHeight_ = 30.0;
    horizontalRulesEnabled_ = YES;
    horizontalRuleColor_ = [[UIColor colorWithRed:0.72 green:0.72 blue:0.59 alpha:1.0] retain];
    horizontalRuleOffset_ = 3.0;
    verticalMarginEnabled_ = YES;
    verticalMarginColor_ = [[UIColor colorWithRed:1.0 green:0.4 blue:0.4 alpha:1.0] retain];
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
    doubleTapDragGestureRecognizer_ = [[NKTDragGestureRecognizer alloc] initWithTarget:self
                                                                                   action:@selector(handleDoubleTapDrag:)];
    doubleTapDragGestureRecognizer_.minimumNumberOfTouches = 2;
    doubleTapDragGestureRecognizer_.maximumNumberOfTouches = 2;
    doubleTapDragGestureRecognizer_.delegate = gestureRecognizerDelegate_;
    
    nonEditTapGestureRecognizer_ = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                           action:@selector(handleTap:)];
    nonEditTapGestureRecognizer_.delegate = gestureRecognizerDelegate_;
    [nonEditTapGestureRecognizer_ requireGestureRecognizerToFail:doubleTapDragGestureRecognizer_];
    tapGestureRecognizer_ = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                    action:@selector(handleTap:)];
    tapGestureRecognizer_.delegate = gestureRecognizerDelegate_;
    
    longPressGestureRecognizer_ = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                action:@selector(handleLongPress:)];
    longPressGestureRecognizer_.delegate = gestureRecognizerDelegate_;
    
    [self addGestureRecognizer:tapGestureRecognizer_];
    [self addGestureRecognizer:nonEditTapGestureRecognizer_];
    [self addGestureRecognizer:longPressGestureRecognizer_];
    [self addGestureRecognizer:doubleTapDragGestureRecognizer_];
    
    // Add drag gesture recognizers to the selection display controller managed handles
    backwardHandleGestureRecognizer_ = [[NKTDragGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(handleBackwardHandleDrag:)];
    [selectionDisplayController_.backwardHandle addGestureRecognizer:backwardHandleGestureRecognizer_];
    
    forwardHandleGestureRecognizer_ = [[NKTDragGestureRecognizer alloc] initWithTarget:self
                                                                                action:@selector(handleForwardHandleDrag:)];
    [selectionDisplayController_.forwardHandle addGestureRecognizer:forwardHandleGestureRecognizer_];
}

- (void)dealloc
{
    [text_ release];
    
    [backgroundView_ release];
    
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
    [doubleTapDragGestureRecognizer_ release];
    [initialDoubleTapTextRange_ release];
    [backwardHandleGestureRecognizer_ release];
    [forwardHandleGestureRecognizer_ release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark Configuring the Background

- (void)setBackgroundView:(UIView *)backgroundView
{
    if (backgroundView_ == backgroundView)
    {
        return;
    }

    if (backgroundView_ != nil)
    {
        [backgroundView_ removeFromSuperview];
        [underlayViews_ removeObject:backgroundView_];
        [backgroundView_ release];
    }
    
    backgroundView_ = [backgroundView retain];
    
    if (backgroundView_ != nil)
    {
        [self insertSubview:backgroundView_ atIndex:0];
        backgroundView_.frame = self.bounds;
        [underlayViews_ addObject:backgroundView_];
    }
}

#pragma mark -
#pragma mark Updating the Content Size

- (void)updateContentSize
{
    CGSize size = self.bounds.size;
    size.height = self.framesetter.frameSize.height + margins_.top + margins_.bottom;
    self.contentSize = size;
}

#pragma mark -
#pragma mark Modifying the Bounds and Frame Rectangles

- (void)setFrame:(CGRect)frame
{
    if (CGRectEqualToRect(self.frame, frame))
    {
        return;
    }
    
    [super setFrame:frame];
    
    backgroundView_.frame = self.bounds;
    
    // HACK: when the nib loads, -setFrame: gets called, but it happens before awakeFromNib! We just check the text
    // property instead before doing any further processing.
    if (text_ != nil)
    {
        [self regenerateTextFrame];
        [selectionDisplayController_ updateSelectionDisplay];
    }
}

#pragma mark -
#pragma mark Laying Out Subviews

// Called when scrolling occurs (behavior inherited from UIScrollView). We tile the sections as
// neccesary whenever scrolling occurs.
- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect frame = backgroundView_.frame;
    frame.origin = self.contentOffset;
    backgroundView_.frame = frame;
    [self tileSections];
}

#pragma mark -
#pragma mark Accessing the Text

- (void)setText:(NSAttributedString *)text
{
    if (text_ == text)
    {
        return;
    }
    
    self.gestureTextRange = nil;
    [self setSelectedTextRange:nil notifyInputDelegate:YES];
    [self setMarkedTextRange:nil notifyInputDelegate:YES];
    
    [inputDelegate_ textWillChange:self];
    [text_ release];
    text_ = [[NSMutableAttributedString alloc] initWithAttributedString:text];
    [self regenerateTextFrame];
    [inputDelegate_ textDidChange:self];
    
    self.contentOffset = CGPointZero;
    self.inputTextAttributes = nil;
    [selectionDisplayController_ updateSelectionDisplay];
}

#pragma mark -
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
    if (![self hasText] || selectedTextRange_ == nil)
    {
        if ([self.delegate respondsToSelector:@selector(defaultCoreTextAttributes)])
        {
            return [(id <NKTTextViewDelegate>)self.delegate defaultCoreTextAttributes];
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
    else if ([textPosition compareIgnoringAffinity:(NKTTextPosition *)[self endOfDocument]] == NSOrderedAscending &&
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
                                                    inRange:selectedTextRange_.nsRange];
        NSDictionary *newAttributes = [target performSelector:selector withObject:attributes];
        
        if (newAttributes != attributes)
        {
            [text_ setAttributes:newAttributes range:longestEffectiveRange];
        }
        
        currentLocation = longestEffectiveRange.location + longestEffectiveRange.length;
    }
    
    [self regenerateTextFrame];
}

#pragma mark -
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

#pragma mark -
#pragma mark Tiling Sections

- (void)tileSections
{
    KBCLogDebug(@"tiling within %@", NSStringFromCGRect(self.bounds));
    CGRect bounds = self.bounds;
    NSInteger firstVisibleSectionIndex = (NSInteger)floorf(CGRectGetMinY(bounds) / CGRectGetHeight(bounds));
    NSInteger lastVisibleSectionIndex = (NSInteger)floorf((CGRectGetMaxY(bounds) - 1.0) / CGRectGetHeight(bounds));
    
    // Recycle no longer visible sections
    for (NKTTextSection *section in visibleSections_)
    {
        if (section.index < firstVisibleSectionIndex || section.index > lastVisibleSectionIndex)
        {
            KBCLogDebug(@"untiling section %d", section.index);
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
            KBCLogDebug(@"tiling section %d", section.index);
            [self insertSubview:section atIndex:insertionIndex];
            [visibleSections_ addObject:section];
        }
    }
}

- (void)untileVisibleSections
{
    for (NKTTextSection *section in visibleSections_)
    {
        KBCLogDebug(@"untiling section %d", section.index);
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

#pragma mark -
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

#pragma mark -
#pragma mark Managing the Responder Chain

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)becomeFirstResponder
{
    BOOL becameFirstResponder = [super becomeFirstResponder];
    
    if (becameFirstResponder)
    {
        // While editing, there should always be a selected text range
        if (selectedTextRange_ == nil)
        {
            NKTTextRange *textRange = [(NKTTextPosition *)[self beginningOfDocument] textRange];
            [self setSelectedTextRange:textRange notifyInputDelegate:YES];
            [selectionDisplayController_ updateSelectionDisplay];
        }
        
        if ([self.delegate respondsToSelector:@selector(textViewDidBeginEditing:)])
        {
            [(id <NKTTextViewDelegate>)self.delegate textViewDidBeginEditing:self];
        }
    }
    
    return becameFirstResponder;
}

- (BOOL)resignFirstResponder
{
    BOOL resignedFirstResponder = [super resignFirstResponder];
    
    if (!resignedFirstResponder)
    {
        return NO;
    }
    
    self.gestureTextRange = nil;
    [self setSelectedTextRange:nil notifyInputDelegate:NO];
    [self setMarkedTextRange:nil notifyInputDelegate:NO];
    [selectionDisplayController_ updateSelectionDisplay];
    
    if ([self.delegate respondsToSelector:@selector(textViewDidEndEditing:)])
    {
        [(id <NKTTextViewDelegate>)self.delegate textViewDidEndEditing:self];
    }
    
    return YES;
}

#pragma mark -
#pragma mark Responding to Gestures

- (void)handleTap:(UIGestureRecognizer *)gestureRecognizer
{
    if (![self isFirstResponder] && ![self becomeFirstResponder])
    {
        return;
    }
    
    CGPoint point = [gestureRecognizer locationInView:self];
    CGPoint framesetterPoint = [self convertPointToFramesetter:point];
    NKTTextPosition *textPosition = [self.framesetter closestTextPositionForCaretToPoint:framesetterPoint];
    [self setMarkedTextRange:nil notifyInputDelegate:YES];
    [self setSelectedTextRange:[textPosition textRange] notifyInputDelegate:YES];
    selectionDisplayController_.caretVisible = YES;
    [selectionDisplayController_ updateSelectionDisplay];
}

- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        [self updateLongPressSelection];
        [self startEdgeScrollCheckWithGestureRecognizer:gestureRecognizer selector:@selector(updateLongPressSelection)];
    }
    else if (gestureRecognizer.state == UIGestureRecognizerStateChanged)
    {
        [self updateLongPressSelection];
    }
    else
    {
        [self stopEdgeScrollCheckWithGestureRecognizer:gestureRecognizer selector:@selector(updateLongPressSelection)];
        [self confirmGestureTextRange];
        [self.caretLoupe setHidden:YES animated:YES];
        selectionDisplayController_.caretVisible = [self isFirstResponder];
    }
}

- (void)updateLongPressSelection
{
    CGPoint point = [longPressGestureRecognizer_ locationInView:self];
    CGPoint framesetterPoint = [self convertPointToFramesetter:point];
    NKTTextPosition *textPosition = [self.framesetter closestTextPositionForCaretToPoint:framesetterPoint];
    self.gestureTextRange = [textPosition textRange];
    [self setMarkedTextRange:nil notifyInputDelegate:YES];
    [self configureLoupe:self.caretLoupe toShowPoint:point anchorToLine:NO];
    [self.caretLoupe setHidden:NO animated:YES];
    selectionDisplayController_.caretVisible = YES;
    [selectionDisplayController_ updateSelectionDisplay];
}

- (void)handleDoubleTapDrag:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint point = [doubleTapDragGestureRecognizer_ locationInView:self];
    CGPoint framesetterPoint = [self convertPointToFramesetter:point];
    NKTTextPosition *textPosition = [self.framesetter closestTextPositionForCaretToPoint:framesetterPoint];
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        NKTTextRange *gesturedWordRange = [self gesturedWordRangeAtTextPosition:textPosition];
        
        if (gesturedWordRange == nil)
        {
            return;
        }
        
        self.initialDoubleTapTextRange = gesturedWordRange;
        self.gestureTextRange = gesturedWordRange;
        [self setMarkedTextRange:nil notifyInputDelegate:YES];
        [self configureLoupe:self.textRangeLoupe toShowPoint:point anchorToLine:YES];
        [self.textRangeLoupe setHidden:NO animated:YES];
        [selectionDisplayController_ updateSelectionDisplay];
        [self startEdgeScrollCheckWithGestureRecognizer:gestureRecognizer
                                               selector:@selector(updateDoubleTapDragSelection)];
    }
    else if (gestureRecognizer.state == UIGestureRecognizerStateChanged)
    {
        if (initialDoubleTapTextRange_ == nil)
        {
            return;
        }
        
        [self updateDoubleTapDragSelection];
    }
    else
    {
        if (initialDoubleTapTextRange_ == nil)
        {
            return;
        }
        
        [self stopEdgeScrollCheckWithGestureRecognizer:gestureRecognizer
                                              selector:@selector(updateDoubleTapDragSelection)];
        self.initialDoubleTapTextRange = nil;
        [self confirmGestureTextRange];
        [self.textRangeLoupe setHidden:YES animated:YES];
    }
}

- (void)updateDoubleTapDragSelection
{
    CGPoint point = [doubleTapDragGestureRecognizer_ locationInView:self];
    CGPoint framesetterPoint = [self convertPointToFramesetter:point];
    NKTTextPosition *textPosition = [self.framesetter closestTextPositionForCaretToPoint:framesetterPoint];
    
    if ([textPosition compare:initialDoubleTapTextRange_.start] == NSOrderedAscending)
    {
        self.gestureTextRange = [NKTTextRange textRangeWithTextPosition:textPosition
                                                           textPosition:initialDoubleTapTextRange_.end];
    }
    else if ([textPosition compare:initialDoubleTapTextRange_.end] == NSOrderedDescending)
    {
        self.gestureTextRange = [NKTTextRange textRangeWithTextPosition:initialDoubleTapTextRange_.start
                                                           textPosition:textPosition];
    }
    else
    {
        self.gestureTextRange = initialDoubleTapTextRange_;
    }
    
    [self configureLoupe:self.textRangeLoupe toShowPoint:point anchorToLine:YES];
    [self.textRangeLoupe setHidden:NO animated:YES];
    [selectionDisplayController_ updateSelectionDisplay];
}

- (void)handleBackwardHandleDrag:(UIGestureRecognizer *)gestureRecognizer
{    
    CGPoint point = [gestureRecognizer locationInView:self];
    CGPoint framesetterPoint = [self convertPointToFramesetter:point];
    NKTTextPosition *textPosition = [self.framesetter closestTextPositionForCaretToPoint:framesetterPoint];
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        [self configureLoupe:self.textRangeLoupe toShowTextPosition:textPosition];
        [self.textRangeLoupe setHidden:NO animated:YES];
        [self startEdgeScrollCheckWithGestureRecognizer:gestureRecognizer
                                               selector:@selector(updateBackwardHandleDragSelection)];
    }
    else if (gestureRecognizer.state == UIGestureRecognizerStateChanged)
    {
        [self updateBackwardHandleDragSelection];
    }
    else
    {
        [self stopEdgeScrollCheckWithGestureRecognizer:gestureRecognizer
                                              selector:@selector(updateBackwardHandleDragSelection)];
        [self confirmGestureTextRange];
        [self.textRangeLoupe setHidden:YES animated:YES];
    }
}

- (void)updateBackwardHandleDragSelection
{
    CGPoint point = [backwardHandleGestureRecognizer_ locationInView:self];
    CGPoint framesetterPoint = [self convertPointToFramesetter:point];
    NKTTextPosition *textPosition = [self.framesetter closestTextPositionForCaretToPoint:framesetterPoint];
    
    if ([textPosition compare:selectedTextRange_.end] == NSOrderedAscending)
    {
        self.gestureTextRange = [NKTTextRange textRangeWithTextPosition:textPosition
                                                           textPosition:selectedTextRange_.end];
        [self setMarkedTextRange:nil notifyInputDelegate:YES];
        [selectionDisplayController_ updateSelectionDisplay];
    }
    
    [self configureLoupe:self.textRangeLoupe toShowPoint:point anchorToLine:YES];
    [self.textRangeLoupe setHidden:NO animated:YES];
}

- (void)handleForwardHandleDrag:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint point = [gestureRecognizer locationInView:self];
    CGPoint framesetterPoint = [self convertPointToFramesetter:point];
    NKTTextPosition *textPosition = [self.framesetter closestTextPositionForCaretToPoint:framesetterPoint];
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        [self configureLoupe:self.textRangeLoupe toShowTextPosition:textPosition];
        [self.textRangeLoupe setHidden:NO animated:YES];
        [self startEdgeScrollCheckWithGestureRecognizer:gestureRecognizer
                                               selector:@selector(updateForwardHandleDragSelection)];
    }
    else if (gestureRecognizer.state == UIGestureRecognizerStateChanged)
    {
        [self updateForwardHandleDragSelection];
    }
    else
    {
        [self stopEdgeScrollCheckWithGestureRecognizer:gestureRecognizer
                                              selector:@selector(updateForwardHandleDragSelection)];
        [self confirmGestureTextRange];
        [self.textRangeLoupe setHidden:YES animated:YES];
    }
}

- (void)updateForwardHandleDragSelection
{
    CGPoint point = [forwardHandleGestureRecognizer_ locationInView:self];
    CGPoint framesetterPoint = [self convertPointToFramesetter:point];
    NKTTextPosition *textPosition = [self.framesetter closestTextPositionForCaretToPoint:framesetterPoint];
    
    if ([textPosition compare:selectedTextRange_.start] == NSOrderedDescending)
    {
        self.gestureTextRange = [NKTTextRange textRangeWithTextPosition:selectedTextRange_.start
                                                           textPosition:textPosition];
        [self setMarkedTextRange:nil notifyInputDelegate:YES];
        [selectionDisplayController_ updateSelectionDisplay];
    }
    
    [self configureLoupe:self.textRangeLoupe toShowPoint:point anchorToLine:YES];
    [self.textRangeLoupe setHidden:NO animated:YES];
}

// Searches for the likely word being indicated at the given text position when the user performs
// a selection gesture. The search considers words in the following order:
// at the text position, at a word boundary before the text position, and at a word boundary after
// the text position.
- (NKTTextRange *)gesturedWordRangeAtTextPosition:(NKTTextPosition *)textPosition
{
    // The text position might already be at within a word (in either text direction)
    if ([self.tokenizer isPosition:textPosition
                    withinTextUnit:UITextGranularityWord
                       inDirection:UITextStorageDirectionForward])
    {
        return (NKTTextRange *)[self.tokenizer rangeEnclosingPosition:textPosition
                                                      withGranularity:UITextGranularityWord
                                                          inDirection:UITextStorageDirectionForward];
    }
    else if ([self.tokenizer isPosition:textPosition
                             atBoundary:UITextGranularityWord
                            inDirection:UITextStorageDirectionForward])
    {
        return (NKTTextRange *)[self.tokenizer rangeEnclosingPosition:textPosition
                                                      withGranularity:UITextGranularityWord
                                                          inDirection:UITextStorageDirectionBackward];
    }
    
    // Search for target word at other boundaries
    NKTTextPosition *previousBoundary = (NKTTextPosition *)[self.tokenizer positionFromPosition:textPosition
                                                                                     toBoundary:UITextGranularityWord
                                                                                    inDirection:UITextStorageDirectionBackward];
    NKTTextRange *textRange = (NKTTextRange *)[self.tokenizer rangeEnclosingPosition:previousBoundary
                                                                     withGranularity:UITextGranularityWord
                                                                         inDirection:UITextStorageDirectionBackward];
    
    // The text range can still be nil if the previous boundary is the start of the document
    if (textRange != nil)
    {
        return textRange;
    }
    
    NKTTextPosition *nextBoundary = (NKTTextPosition *)[self.tokenizer positionFromPosition:textPosition
                                                                                 toBoundary:UITextGranularityWord
                                                                                inDirection:UITextStorageDirectionForward];
    return (NKTTextRange *)[self.tokenizer rangeEnclosingPosition:nextBoundary
                                                  withGranularity:UITextGranularityWord
                                                      inDirection:UITextStorageDirectionForward];
}

#pragma mark -
#pragma mark Scrolling

static NSString * const GestureRecognizerKey = @"GestureRecognizer";
static NSString * const SelectorKey = @"Selector";
static const CGFloat EdgeScrollCheckPeriodSeconds = 0.3;
static const CGFloat EdgeScrollThreshold = 40.0;

- (void)startEdgeScrollCheckWithGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer selector:(SEL)selector
{
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:gestureRecognizer, GestureRecognizerKey,
                          [NSValue valueWithPointer:selector], SelectorKey,
                          nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(edgeScrollCheckWithInfo:) object:info];
    [self performSelector:@selector(edgeScrollCheckWithInfo:) withObject:info afterDelay:EdgeScrollCheckPeriodSeconds];
}

- (void)stopEdgeScrollCheckWithGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer selector:(SEL)selector
{
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:gestureRecognizer, GestureRecognizerKey,
                          [NSValue valueWithPointer:selector], SelectorKey,
                          nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(edgeScrollCheckWithInfo:) object:info];
}

- (void)edgeScrollCheckWithInfo:(NSDictionary *)info
{
    UIGestureRecognizer *gestureRecognizer = [info objectForKey:GestureRecognizerKey];
    SEL selector = [[info objectForKey:SelectorKey] pointerValue];
    
    if (gestureRecognizer == nil)
    {
        KBCLogWarning(@"gesture recognizer is nil, ignoring");
        return;
    }
    
    if (selector == NULL)
    {
        KBCLogWarning(@"selector is NULL, ignoring");
        return;
    }
    
    CGPoint point = [gestureRecognizer locationInView:self];
    [self scrollAtEdgeWithPoint:point];
    [self performSelector:selector];
    
    // Reschedule this method with same arguments
    [self performSelector:@selector(edgeScrollCheckWithInfo:) withObject:info afterDelay:EdgeScrollCheckPeriodSeconds];
}

- (void)scrollAtEdgeWithPoint:(CGPoint)point
{
    CGPoint framesetterPoint = [self convertPointToFramesetter:point];
    CGPoint boundsPoint = CGPointMake(point.x - self.contentOffset.x, point.y - self.contentOffset.y);
    NKTLine *line = [self.framesetter lineClosestToPoint:framesetterPoint];
    
    if (boundsPoint.y < EdgeScrollThreshold)
    {
        if (line.index > 0)
        {
            NKTLine *previousLine = [self.framesetter lineAtIndex:line.index - 1];
            [self scrollTextRangeToVisible:previousLine.textRange animated:YES];
        }
    }
    else if (boundsPoint.y > (self.bounds.size.height - EdgeScrollThreshold))
    {
        if (line.index + 1 < [self.framesetter numberOfLines])
        {
            NKTLine *nextLine = [self.framesetter lineAtIndex:line.index + 1];
            [self scrollTextRangeToVisible:nextLine.textRange animated:YES];
        }
    }
}

- (void)scrollTextRangeToVisible:(NKTTextRange *)textRange animated:(BOOL)animated
{
    if (textRange == nil)
    {
        return;
    }
    
    CGRect firstCaretRect = [self caretRectForTextPosition:textRange.start applyInputTextAttributes:YES];
    CGRect lastCaretRect = [self caretRectForTextPosition:textRange.end applyInputTextAttributes:YES];
    CGRect combinedRect = CGRectUnion(firstCaretRect, lastCaretRect);
    combinedRect.origin.y -= 40.0;
    combinedRect.size.height += 80.0;
    [self scrollRectToVisible:combinedRect animated:animated];
}

#pragma mark -
#pragma mark Managing Loupes

- (NKTLoupe *)textRangeLoupe
{    
    if (textRangeLoupe_ == nil)
    {
        textRangeLoupe_ = [[NKTLoupe alloc] initWithStyle:NKTLoupeStyleBand];
        textRangeLoupe_.hidden = YES;
        textRangeLoupe_.zoomedView = self;
        
        if ([self.delegate respondsToSelector:@selector(addLoupeView:)])
        {
            [(id <NKTTextViewDelegate>)self.delegate addLoupe:textRangeLoupe_];
        }
        else
        {
            [self.superview addSubview:textRangeLoupe_];
        }
        
        // HACK: visual inconsistencies may appear the first time the text range loupe is shown.
        // I haven't fully dived into unraveling the specific issue, but it probably has to do 
        // with a loupes somewhat esoteric drawing of another view within itself. For now, the
        // line below forces one redisplay of the loupe when it is created the first time and
        // seems to fix the problem.
        [textRangeLoupe_ performSelector:@selector(setNeedsDisplay) withObject:nil afterDelay:0];
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
        
        if ([self.delegate respondsToSelector:@selector(addLoupeView:)])
        {
            [(id <NKTTextViewDelegate>)self.delegate addLoupe:caretLoupe_];
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
    if ([self.delegate respondsToSelector:@selector(loupeFillColor)])
    {
        loupe.fillColor = [(id <NKTTextViewDelegate>)self.delegate loupeFillColor];
    }
    
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
        // PENDING: clamping wrong
        //anchor = KBCClampPointToRect(anchor, self.bounds);
        loupe.anchor = [self convertPoint:anchor toView:loupe.superview];
    }
    else
    {
        // No adjusting of point, just use it as both the zoom center and anchor
        loupe.zoomCenter = [self convertPoint:point toView:loupe.zoomedView];
        // PENDING: clamping wrong
        //CGPoint anchor = KBCClampPointToRect(point, self.bounds);
        loupe.anchor = [self convertPoint:point toView:loupe.superview];
    }
}

- (void)configureLoupe:(NKTLoupe *)loupe toShowTextPosition:(NKTTextPosition *)textPosition
{
    if ([self.delegate respondsToSelector:@selector(loupeFillColor)])
    {
        loupe.fillColor = [(id <NKTTextViewDelegate>)self.delegate loupeFillColor];
    }
    
    CGPoint framesetterPoint = [self.framesetter baselineOriginForCharAtTextPosition:textPosition];
    CGPoint point = [self convertPointFromFramesetter:framesetterPoint];
    loupe.zoomCenter = [self convertPoint:point toView:loupe.zoomedView];
    // Anchor loupe to a point just on top of the text position
    CGPoint anchor = CGPointMake(point.x, point.y - (lineHeight_ * 0.75));
    // PENDING: clamping wrong
    //anchor = KBCClampPointToRect(anchor, self.bounds);
    loupe.anchor = [self convertPoint:anchor toView:loupe.superview];
}

#pragma mark -
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
        [text_ replaceCharactersInRange:insertionTextRange.nsRange withString:text];
    }
    else
    {
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:text
                                                                               attributes:inputTextAttributes];
        [text_ replaceCharactersInRange:insertionTextRange.nsRange withAttributedString:attributedString];
        [attributedString release];
    }
    
    // PENDING: extract a method for this block
    [self.framesetter textChangedFromTextPosition:insertionTextRange.start];
    [self untileVisibleSections];
    [self tileSections];
    [self updateContentSize];
    
    if ([self.delegate respondsToSelector:@selector(textViewDidChange:)])
    {
        [(id <NKTTextViewDelegate>)self.delegate textViewDidChange:self];
    }
    
    NKTTextPosition *textPosition = [NKTTextPosition textPositionWithLocation:insertionTextRange.start.location + [text length]
                                                                     affinity:UITextStorageDirectionForward];
    [self setSelectedTextRange:[textPosition textRange] notifyInputDelegate:NO];
    [self setMarkedTextRange:nil notifyInputDelegate:NO];
    [selectionDisplayController_ updateSelectionDisplay];
    
    // Make caret visible if it is not
    [self scrollTextRangeToVisible:self.selectedTextRange animated:YES];
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
    
    // PENDING: figure out a clearer refactor for this block
    if (markedTextRange_ != nil)
    {
        if (markedTextRange_.start.location != 0)
        {
            deletionTextRange = [markedTextRange_ textRangeByApplyingStartOffset:-1];
        }
        else
        {
            deletionTextRange = markedTextRange_;
        }
    }
    else
    {
        if (selectedTextRange_.start.location != 0)
        {
            deletionTextRange = [selectedTextRange_ textRangeByApplyingStartOffset:-1];
        }
        else
        {
            deletionTextRange = selectedTextRange_;
        }
    }
    
    [text_ deleteCharactersInRange:deletionTextRange.nsRange];
    // PENDING: frameset intelligently
    [self regenerateTextFrame];
    
    if ([self.delegate respondsToSelector:@selector(textViewDidChange:)])
    {
        [(id <NKTTextViewDelegate>)self.delegate textViewDidChange:self];
    }
    
    NKTTextPosition *textPosition = [NKTTextPosition textPositionWithLocation:deletionTextRange.start.location
                                                                     affinity:UITextStorageDirectionForward];
    [self setSelectedTextRange:[textPosition textRange] notifyInputDelegate:NO];
    [self setMarkedTextRange:nil notifyInputDelegate:NO];
    [selectionDisplayController_ updateSelectionDisplay];
    
    // Make caret visible if it is not
    [self scrollTextRangeToVisible:self.selectedTextRange animated:YES];
}

#pragma mark -
#pragma mark Replacing and Returning Text

// UITextInput method
- (NSString *)textInRange:(NKTTextRange *)textRange
{
    KBCLogDebug(@"%@", textRange);
    NSString *string = [text_ string];
    
    if (textRange.start.location == 0 && textRange.end.location == [text_ length])
    {
        return string;
    }
    
    return [string substringWithRange:textRange.nsRange];
}

// UITextInput method
- (void)replaceRange:(NKTTextRange *)textRange withText:(NSString *)replacementText
{
    KBCLogDebug(@"%@ : %@", textRange, replacementText);
    [text_ replaceCharactersInRange:textRange.nsRange withString:replacementText];
    // PENDING: frameset intelligently
    [self regenerateTextFrame];
    
    // The text range to be replaced lies fully before the selected text range
    if ([textRange.end compareIgnoringAffinity:selectedTextRange_.start] != NSOrderedDescending)
    {
        NSInteger changeInLength = [replacementText length] - textRange.length;
        NKTTextPosition *newTextRangeStart = [selectedTextRange_.start textPositionByApplyingOffset:changeInLength];
        NKTTextPosition *newTextRangeEnd = [selectedTextRange_.end textPositionByApplyingOffset:changeInLength];
        NKTTextRange *newTextRange = [NKTTextRange textRangeWithTextPosition:newTextRangeStart
                                                                textPosition:newTextRangeEnd];
        [self setSelectedTextRange:newTextRange notifyInputDelegate:NO];
        [selectionDisplayController_ updateSelectionDisplay];
    }
    // The text range overlaps the selected text range
    else if ([selectedTextRange_ containsTextPositionIgnoringAffinity:textRange.start])
    {
        NKTTextPosition *newEndTextPosition = [NKTTextPosition textPositionWithLocation:textRange.start.location
                                                                               affinity:selectedTextRange_.end.affinity];
        NKTTextRange *newTextRange = [NKTTextRange textRangeWithTextPosition:selectedTextRange_.start
                                                                textPosition:newEndTextPosition];
        [self setSelectedTextRange:newTextRange notifyInputDelegate:NO];
        [selectionDisplayController_ updateSelectionDisplay];
    }
}

#pragma mark -
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
}

- (void)confirmGestureTextRange
{
    [self setSelectedTextRange:gestureTextRange_ notifyInputDelegate:YES];
    self.gestureTextRange = nil;
    [selectionDisplayController_ updateSelectionDisplay];
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
    [selectionDisplayController_ updateSelectionDisplay];
    [self scrollTextRangeToVisible:self.selectedTextRange animated:YES];
}

- (void)setSelectedTextRange:(NKTTextRange *)textRange notifyInputDelegate:(BOOL)notifyInputDelegate
{
    if (selectedTextRange_ == textRange || [selectedTextRange_ isEqualToTextRange:textRange])
    {
        return;
    }
    
    if (notifyInputDelegate)
    {
        KBCLogDebug(@"calling input delegate -selectionWillChange:");
        [inputDelegate_ selectionWillChange:self];
    }
    
    [selectedTextRange_ release];
    selectedTextRange_ = [textRange copy];
    
    // The input text attributes are cleared when the selected text range changes
    self.inputTextAttributes = nil;
    
    if (notifyInputDelegate)
    {
        KBCLogDebug(@"calling input delegate -selectionDidChange:");
        [inputDelegate_ selectionDidChange:self];
    }
    
    if ([self.delegate respondsToSelector:@selector(textViewDidChangeSelection:)])
    {
        [(id <NKTTextViewDelegate>)self.delegate textViewDidChangeSelection:self];
    }
}

// UITextInput method
- (UITextRange *)markedTextRange
{
    return markedTextRange_;
}

- (void)setMarkedTextRange:(NKTTextRange *)textRange notifyInputDelegate:(BOOL)notifyInputDelegate
{
    if (markedTextRange_  == textRange || [markedTextRange_ isEqualToTextRange:textRange])
    {
        return;
    }
    
    if (notifyInputDelegate)
    {
        KBCLogDebug(@"calling input delegate -selectionWillChange:");
        [inputDelegate_ selectionWillChange:self];
    }
    
    [markedTextRange_ release];
    markedTextRange_ = [textRange copy];
    
    if (notifyInputDelegate)
    {
        KBCLogDebug(@"calling input delegate -selectionDidChange:");
        [inputDelegate_ selectionDidChange:self];
    }
}

// UITextInput method
- (void)setMarkedText:(NSString *)markedText selectedRange:(NSRange)relativeSelectedRange
{
    KBCLogDebug(@"%@ : %@", markedText, NSStringFromRange(relativeSelectedRange));
    // PENDING: accessor for marked text property
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
    [text_ replaceCharactersInRange:replacementTextRange.nsRange withAttributedString:attributedString];
    [attributedString release];
    
    // PENDING: frameset intelligently
    [self regenerateTextFrame];
    
    // Update the marked and selected text ranges
    NKTTextPosition *newMarkedTextRangeEnd = [NKTTextPosition textPositionWithLocation:replacementTextRange.start.location + [markedText_ length]
                                                                              affinity:UITextStorageDirectionForward];
    NKTTextRange *newMarkedTextRange = [NKTTextRange textRangeWithTextPosition:replacementTextRange.start
                                                                  textPosition:newMarkedTextRangeEnd];
    
    // Since the selected text range is always within the marked text range, update the selected text range first
    NKTTextPosition *newSelectedTextRangeStart = [NKTTextPosition textPositionWithLocation:newMarkedTextRange.start.location + relativeSelectedRange.location
                                                                                  affinity:UITextStorageDirectionForward];
    NKTTextPosition *newSelectedTextRangeEnd = [NKTTextPosition textPositionWithLocation:newSelectedTextRangeStart.location + relativeSelectedRange.length
                                                                                affinity:UITextStorageDirectionForward];
    NKTTextRange *newSelectedTextRange = [NKTTextRange textRangeWithTextPosition:newSelectedTextRangeStart
                                                                    textPosition:newSelectedTextRangeEnd];
    [self setSelectedTextRange:newSelectedTextRange notifyInputDelegate:NO];
    [self setMarkedTextRange:newMarkedTextRange notifyInputDelegate:NO];
    
    // Input text attributes are reset when marked text is set
    self.inputTextAttributes = nil;
    
    [selectionDisplayController_ updateSelectionDisplay];
    
    [self scrollTextRangeToVisible:self.selectedTextRange animated:YES];
}

// UITextInput method
- (void)unmarkText
{
    [self setMarkedTextRange:nil notifyInputDelegate:NO];
    [markedText_ release];
    markedText_ = nil;
}

// UITextInput method
- (UITextStorageDirection)selectionAffinity
{
    // PENDING: this is a bogus computation right now, replace with something that makes sense
    return (selectedTextRange_ != nil) ? selectedTextRange_.start.affinity : UITextStorageDirectionForward;
}

// UITextInput method
- (void)setSelectionAffinity:(UITextStorageDirection)direction
{
    KBCLogWarning(@"unexpected method call");
}

#pragma mark -
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

#pragma mark -
#pragma mark Evaluating Text Positions

// UITextInput method
- (NSComparisonResult)comparePosition:(NKTTextPosition *)firstTextPosition
                           toPosition:(NKTTextPosition *)secondTextPosition
{
    KBCLogDebug(@"%@ : %@", firstTextPosition, secondTextPosition);
    return [firstTextPosition compareIgnoringAffinity:secondTextPosition];
}

// UITextInput method
- (NSInteger)offsetFromPosition:(NKTTextPosition *)fromPosition toPosition:(NKTTextPosition *)toPosition
{
    KBCLogDebug(@"%@ : %@", fromPosition, toPosition);
    return (NSInteger)toPosition.location - (NSInteger)fromPosition.location;
}

#pragma mark -
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
            return [NKTTextRange textRangeWithTextPosition:textPosition textPosition:line.textRange.end];
        }
        case UITextLayoutDirectionLeft:
        {
            NKTLine *line = [self.framesetter lineForCaretAtTextPosition:textPosition];
            return [NKTTextRange textRangeWithTextPosition:line.textRange.start textPosition:textPosition];
        }
        case UITextLayoutDirectionUp:
        {
            return [NKTTextRange textRangeWithTextPosition:(NKTTextPosition *)[self beginningOfDocument]
                                              textPosition:textPosition];
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

#pragma mark -
#pragma mark Geometry and Hit-Testing

// UITextInput method
- (CGRect)firstRectForRange:(NKTTextRange *)textRange
{
    KBCLogDebug(@"%@", textRange);
    return [self firstRectForTextRange:textRange];
}

- (CGRect)firstRectForTextRange:(UITextRange *)textRange
{
    CGRect rect = [self.framesetter firstRectForTextRange:(NKTTextRange *)textRange];
    CGAffineTransform transform = [self framesetterToViewTransform];
    return CGRectApplyAffineTransform(rect, transform);
}

- (CGRect)lastRectForTextRange:(UITextRange *)textRange
{
    CGRect rect = [self.framesetter lastRectForTextRange:(NKTTextRange *)textRange];
    CGAffineTransform transform = [self framesetterToViewTransform];
    return CGRectApplyAffineTransform(rect, transform);
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
        KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithCoreTextAttributes:self.inputTextAttributes];
        font = [styleDescriptor uiFontForFont];
    }
    else
    {
        font = [self fontAtTextPosition:textPosition];
    }
    
    return [self caretRectWithOrigin:charOrigin font:font];
}

static const CGFloat CaretWidth = 2.0;
static const CGFloat CaretTopPadding = 1.0;
static const CGFloat CaretBottomPadding = 1.0;

// PENDING: move to selection display controller?
- (CGRect)caretRectWithOrigin:(CGPoint)origin font:(UIFont *)font
{
    CGRect caretFrame = CGRectZero;
    caretFrame.origin.x = origin.x;
    caretFrame.origin.y = origin.y - font.ascender - CaretTopPadding;
    caretFrame.size.width = CaretWidth;
    caretFrame.size.height = font.ascender - font.descender + CaretTopPadding + CaretBottomPadding;
    return caretFrame;
}

// UITextInput method
- (UITextPosition *)closestPositionToPoint:(CGPoint)point
{
    KBCLogDebug(@"%@", NSStringFromCGPoint(point));
    // PENDING: figure out when this is called by UITextInput, and implement accordingly
    return [self.framesetter closestTextPositionForCaretToPoint:point];
}

// UITextInput method
- (UITextPosition *)closestPositionToPoint:(CGPoint)point withinRange:(NKTTextRange *)textRange
{
    KBCLogDebug(@"%@ : %@", NSStringFromCGPoint(point), textRange);
    // PENDING: figure out when this is called by UITextInput, and implement accordingly
    return nil;
}

// UITextInput method
- (UITextRange *)characterRangeAtPoint:(CGPoint)point
{
    KBCLogDebug(@"%@", NSStringFromCGPoint(point));    
    // PENDING: figure out when this is called by UITextInput, and implement accordingly
    NKTTextPosition *textPosition = (NKTTextPosition *)[self closestPositionToPoint:point];
    return [textPosition textRange];
}

#pragma mark -
#pragma mark Text Input Delegate and Text Input Tokenizer

- (id <UITextInputTokenizer>)tokenizer
{
    if (tokenizer_ == nil)
    {
        tokenizer_ = [[NKTTextViewTokenizer alloc] initWithTextView:self];
    }
    
    return tokenizer_;
}

#pragma mark -
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

#pragma mark -
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

#pragma mark -
#pragma mark Returning the Text Input View

- (UIView *)textInputView
{
    return self;
}

#pragma mark -
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

#pragma mark -
#pragma mark Tokenizing

- (NKTTextRange *)textRangeForLineContainingTextPosition:(NKTTextPosition *)textPosition
{
    NKTLine *line = [self.framesetter lineForCaretAtTextPosition:textPosition];
    return line.textRange;
}

@end
