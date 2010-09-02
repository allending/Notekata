//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#define KBC_LOGGING_DEBUG_ENABLED 1
#define KBC_LOGGING_STRIP_DEBUG 0

#import "NKTTextView.h"
#import "KBCFont.h"
#import <CoreText/CoreText.h>
#import "NKTDragGestureRecognizer.h"
#import "NKTFont.h"
#import "NKTGestureRecognizerUtilites.h"
#import "NKTLine.h"
#import "NKTLoupe.h"
#import "NKTTextPosition.h"
#import "NKTTextRange.h"
#import "NKTTextSection.h"
#import "NKTTextViewGestureRecognizerDelegate.h"

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
- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer;
- (void)handleDoubleTapAndDrag:(UIGestureRecognizer *)gestureRecognizer;

#pragma mark Hit Testing

- (NKTTextPosition *)closestTextPositionToPoint:(CGPoint)point;

#pragma mark Getting and Converting Coordinates

- (CGPoint)lineOriginForLineAtIndex:(NSUInteger)index;
- (CGPoint)convertPoint:(CGPoint)point toLine:(NKTLine *)line;

#pragma mark Getting Lines

- (NSInteger)virtualIndexForLineContainingPoint:(CGPoint)point;
- (NKTLine *)closestLineContainingPoint:(CGPoint)point;
- (NKTLine *)lineContainingTextPosition:(NKTTextPosition *)textPosition;

#pragma mark Getting Fonts at Text Positions

- (UIFont *)insertionFontForTextPosition:(NKTTextPosition *)textPosition;

#pragma mark Managing Selection Views

- (void)showSelectionCaretLoupeAtTouchLocation:(CGPoint)touchLocation;
- (void)hideSelectionCaretLoupe;

- (void)showSelectionBandLoupeAtTouchLocation:(CGPoint)touchLocation;
- (void)hideSelectionBandLoupe;

- (void)setSelectedTextRange:(UITextRange *)selectedTextRange;
- (void)setMarkedTextRange:(NKTTextRange *)markedTextRange;

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
    selectionDisplayController_ = [[NKTSelectionDisplayController alloc] init];
    selectionDisplayController_.delegate = self;
}

- (void)createGestureRecognizers
{
    gestureRecognizerDelegate = [[NKTTextViewGestureRecognizerDelegate alloc] initWithTextView:self];
    
    preFirstResponderTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    preFirstResponderTapGestureRecognizer.delegate = gestureRecognizerDelegate;
    
    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapGestureRecognizer.delegate = gestureRecognizerDelegate;
    
    longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPressGestureRecognizer.delegate = gestureRecognizerDelegate;
    
    doubleTapAndDragGestureRecognizer = [[NKTDragGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapAndDrag:)];
    doubleTapAndDragGestureRecognizer.delegate = gestureRecognizerDelegate;
    
    [preFirstResponderTapGestureRecognizer requireGestureRecognizerToFail:doubleTapAndDragGestureRecognizer];
    [self addGestureRecognizer:tapGestureRecognizer];
    [self addGestureRecognizer:preFirstResponderTapGestureRecognizer];
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
    
    [selectedTextRange release];
    [markedTextRange release];
    [markedTextStyle release];
    [markedText release];
    [tokenizer release];
    
    [selectionDisplayController_ release];

    [selectionCaretLoupe release];
    [selectionBandLoupe release];

    [gestureRecognizerDelegate release];
    [preFirstResponderTapGestureRecognizer release];
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

- (BOOL)becomeFirstResponder
{
    BOOL acceptsFirstResponder = [super becomeFirstResponder];
    
    if (!acceptsFirstResponder)
    {
        return NO;
    }
    
    selectionDisplayController_.caretVisible = YES;
    return YES;
}

- (BOOL)resignFirstResponder
{
    BOOL resignsFirstResponder = [super resignFirstResponder];
    
    if (!resignsFirstResponder)
    {
        return NO;
    }
    
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
    
    // TODO: Don't move this because message should only be sent in a change external to UITextInput
    //[inputDelegate selectionWillChange:self];
    CGPoint touchLocation = [gestureRecognizer locationInView:self];
    NKTTextPosition *textPosition = [self closestTextPositionToPoint:touchLocation];
    [self setSelectedTextRange:[textPosition textRange]];
    // TODO: yeah do this, but do it well and account for marked text
    [self setMarkedTextRange:nil];
    // TODO: Don't move this because message should only be sent in a change external to UITextInput
    //[inputDelegate selectionDidChange:self];
}

- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint touchLocation = [gestureRecognizer locationInView:self];
    NKTTextPosition *textPosition = [self closestTextPositionToPoint:touchLocation];
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan || gestureRecognizer.state == UIGestureRecognizerStateChanged)
    {
        selectionDisplayController_.caretVisible = YES;
        selectionDisplayController_.caretBlinkingEnabled = NO;
        
        // TODO: Don't move this because message should only be sent in a change external to UITextInput
        //[inputDelegate selectionWillChange:self];
        [self setSelectedTextRange:[textPosition textRange]];
        [self showSelectionCaretLoupeAtTouchLocation:touchLocation];
        // TODO: Don't move this because message should only be sent in a change external to UITextInput
        //[inputDelegate selectionDidChange:self];
    }
    else
    {
        selectionDisplayController_.caretVisible = [self isFirstResponder];
        selectionDisplayController_.caretBlinkingEnabled = YES;
        [self hideSelectionCaretLoupe];
    }
}

- (void)handleDoubleTapAndDrag:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint touchLocation = [gestureRecognizer locationInView:self];
    NKTTextPosition *textPosition = [self closestTextPositionToPoint:touchLocation];
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        doubleTapStartTextPosition = [textPosition retain];
        [self showSelectionBandLoupeAtTouchLocation:touchLocation];
    }
    else if (gestureRecognizer.state == UIGestureRecognizerStateChanged)
    {
        NKTTextRange *textRange = [doubleTapStartTextPosition textRangeWithTextPosition:textPosition];
        // TODO: make sure selection isn't allowed to be empty
        
        // TODO: Don't move this because message should only be sent in a change external to UITextInput
        //[inputDelegate selectionWillChange:self];
        [self setSelectedTextRange:textRange];
        [self showSelectionBandLoupeAtTouchLocation:touchLocation];
        // TODO: Don't move this because message should only be sent in a change external to UITextInput
        //[inputDelegate selectionDidChange:self];
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

- (NKTTextPosition *)closestTextPositionToPoint:(CGPoint)point
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

//--------------------------------------------------------------------------------------------------

#pragma mark Getting and Converting Coordinates

- (CGPoint)lineOriginForLineAtIndex:(NSUInteger)index
{
    CGFloat y = margins.top + lineHeight + ((CGFloat)index * lineHeight);
    CGPoint lineOrigin = CGPointMake(margins.left, y);
    return lineOrigin;
}

- (CGRect)rectForLineAtIndex:(NSUInteger)index
{
    CGPoint origin = [self lineOriginForLineAtIndex:index];
    origin.y -= lineHeight;
    return CGRectMake(origin.x, origin.y, self.bounds.size.width, lineHeight);
}

- (CGPoint)convertPoint:(CGPoint)point toLine:(NKTLine *)line
{
    // TODO: is this right???
    CGPoint lineOrigin = [self lineOriginForLineAtIndex:line.index];
    return CGPointMake(point.x - lineOrigin.x, point.y - lineOrigin.y);
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
- (UIFont *)insertionFontForTextPosition:(NKTTextPosition *)textPosition
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

#pragma mark Getting Selection Views

- (UIView *)viewForTextInputSelectionDisplayControllerElements:(NKTSelectionDisplayController *)controller
{
    return [[self retain] autorelease];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Managing Selection Views

// TODO: Refactor - shares logic with showSelectedBandLoupeAtTouchLocation:
- (void)showSelectionCaretLoupeAtTouchLocation:(CGPoint)touchLocation
{
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    
    if (selectionCaretLoupe == nil)
    {
        selectionCaretLoupe = [[NKTLoupe alloc] initWithStyle:NKTLoupeStyleRound];
        selectionCaretLoupe.hidden = YES;
        // TODO: ask for background color instead and use self
        UIView *zoomedView = [self.delegate viewForMagnifyingInTextView:self];
        
        if (zoomedView == nil)
        {
            zoomedView = self.superview;
        }
        
        selectionCaretLoupe.zoomedView = zoomedView;
        [keyWindow addSubview:selectionCaretLoupe];
    }
    
    CGPoint zoomCenter = [self convertPoint:touchLocation toView:self.superview];
    selectionCaretLoupe.zoomCenter = zoomCenter;
    
    CGPoint anchor = touchLocation;
    anchor = KBCClampPointToRect(anchor, self.bounds);
    selectionCaretLoupe.anchor = [self convertPoint:anchor toView:keyWindow];
    
    [selectionCaretLoupe setHidden:NO animated:YES];
}

- (void)hideSelectionCaretLoupe
{
    [selectionCaretLoupe setHidden:YES animated:YES];
}

// TODO: Change name to present/update?
- (void)showSelectionBandLoupeAtTouchLocation:(CGPoint)touchLocation
{
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    
    if (selectionBandLoupe == nil)
    {
        selectionBandLoupe = [[NKTLoupe alloc] initWithStyle:NKTLoupeStyleBand];
        selectionBandLoupe.hidden = YES;
        UIView *zoomedView = [self.delegate viewForMagnifyingInTextView:self];
        
        if (zoomedView == nil)
        {
            zoomedView = self.superview;
        }
        
        selectionBandLoupe.zoomedView = zoomedView;
        [keyWindow addSubview:selectionBandLoupe];
    }
    
    NKTLine *line = [self closestLineContainingPoint:touchLocation];
    CGPoint lineOrigin = [self lineOriginForLineAtIndex:line.index];
    
    CGPoint zoomCenter = CGPointMake(touchLocation.x, lineOrigin.y);
    zoomCenter = [self convertPoint:zoomCenter toView:self.superview];
    selectionBandLoupe.zoomCenter = zoomCenter;
    
    CGPoint anchor = CGPointMake(touchLocation.x, lineOrigin.y - lineHeight);
    anchor = KBCClampPointToRect(anchor, self.bounds);
    selectionBandLoupe.anchor = [self convertPoint:anchor toView:keyWindow];
    
    [selectionBandLoupe setHidden:NO animated:YES];
}

- (void)hideSelectionBandLoupe
{
    [selectionBandLoupe setHidden:YES animated:YES];
}

- (CGRect)caretRectForPosition:(UITextPosition *)textPosition
{
    // Ask the controller since it is the one doing the actual caret display
    return [selectionDisplayController_ caretRectForPosition:textPosition];
}

- (CGPoint)characterOriginForPosition:(UITextPosition *)uiTextPosition
{
    NKTTextPosition *textPosition = (NKTTextPosition *)uiTextPosition;
    NSUInteger textLength = [text length];
    NSUInteger lineCount = [typesettedLines count];
    
    CGPoint lineOrigin = CGPointZero;
    CGFloat charOffset = 0.0;
    
    if (lineCount == 0 || textPosition.index == 0)
    {
        lineOrigin = [self lineOriginForLineAtIndex:0];
    }
    else if (textPosition.index >= textLength)
    {
        // Last character is a line break, caret is on the line following the last typesetted one
        if ([[text string] characterAtIndex:(textLength - 1)] == '\n')
        {
            lineOrigin = [self lineOriginForLineAtIndex:lineCount];
        }
        // Last character is not a line break, caret is on the last typesetted line
        else
        {
            NKTLine *lastLine = [typesettedLines objectAtIndex:(lineCount - 1)];
            lineOrigin = [self lineOriginForLineAtIndex:lastLine.index];
            charOffset = [lastLine offsetForCharAtTextPosition:textPosition];
        }
    }
    else
    {
        NKTLine *line = [self lineContainingTextPosition:textPosition];
        lineOrigin = [self lineOriginForLineAtIndex:line.index];
        charOffset = [line offsetForCharAtTextPosition:textPosition];
    }
    
    return CGPointMake(lineOrigin.x + charOffset, lineOrigin.y);
}

//--------------------------------------------------------------------------------------------------

#pragma mark Inserting and Deleting Text

- (BOOL)hasText
{
    //KBCLogTrace();
    return [text length] > 0;
}

- (void)insertText:(NSString *)theText
{
    //KBCLogDebug(@"%@", theText);
    
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
    //KBCLogTrace();

    if (markedTextRange == nil && selectedTextRange == nil)
    {
        KBCLogWarning(@"marked text range and selected text range are nil, ignoring");
        return;
    }
    
    NKTTextRange *deletionTextRange = nil;
    
    // TODO: why can't just use selected text range?
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

- (NSString *)textInRange:(UITextRange *)uiTextRange
{
    //KBCLogTrace();
    
    NKTTextRange *textRange = (NKTTextRange *)uiTextRange;
    return [[text string] substringWithRange:textRange.nsRange];
}

- (void)replaceRange:(UITextRange *)uiTextRange withText:(NSString *)replacementText
{
    //KBCLogTrace();
    
    NKTTextRange *textRange = (NKTTextRange *)uiTextRange;
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
    //KBCLogTrace();
    
    return selectedTextRange;
}

- (void)setSelectedTextRange:(UITextRange *)newSelectedTextRange
{
    //KBCLogTrace();
    
    [selectedTextRange autorelease];
    selectedTextRange = [newSelectedTextRange copy];
    [selectionDisplayController_ selectedTextRangeDidChange];
}

- (NKTTextRange *)markedTextRange
{
    //KBCLogTrace();
    
    return markedTextRange;
}

- (NSDictionary *)markedTextStyle
{
    KBCLogTrace();
    
    return markedTextStyle;
}

- (void)setMarkedTextStyle:(NSDictionary *)newMarkedTextStyle
{
    //KBCLogTrace();
    
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
}

- (void)setMarkedText:(NSString *)newMarkedText selectedRange:(NSRange)relativeSelectedRange
{
    //KBCLogDebug(@"%@, [%d, %d]", newMarkedText, relativeSelectedRange.location, relativeSelectedRange.location + relativeSelectedRange.length);
    
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
    //KBCLogDebug(@"*********");

    [self setMarkedTextRange:nil];
    [markedText release];
    markedText = nil;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Computing Text Ranges and Text Positions

- (NKTTextRange *)textRangeFromPosition:(NKTTextPosition *)fromPosition toPosition:(NKTTextPosition *)toPosition
{
    //KBCLogTrace();
    
    return [fromPosition textRangeWithTextPosition:toPosition];
}

- (NKTTextPosition *)positionFromPosition:(NKTTextPosition *)textPosition offset:(NSInteger)offset
{
    //KBCLogTrace();
    
    NSInteger index = (NSInteger)textPosition.index + offset;
    
    if (index < 0 || index > [text length])
    {
        return nil;
    }
    
    return [NKTTextPosition textPositionWithIndex:index];
}

- (UITextPosition *)positionFromPosition:(NKTTextPosition *)textPosition inDirection:(UITextLayoutDirection)direction offset:(NSInteger)offset
{
    //KBCLogTrace();
    
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
            offsetTextPosition = [self closestTextPositionToPoint:pointAboveCaret];
            break;
        }
        case UITextLayoutDirectionDown:
        {
            CGRect caretFrame = [self caretRectForPosition:textPosition];
            CGPoint pointAboveCaret = caretFrame.origin;
            pointAboveCaret.y += (0.5 * lineHeight);
            pointAboveCaret.y += ((CGFloat)offset * lineHeight);
            offsetTextPosition = [self closestTextPositionToPoint:pointAboveCaret];
            break;
        }
    }
    
    return offsetTextPosition;
}

- (UITextPosition *)beginningOfDocument
{
    //KBCLogTrace();
    return [NKTTextPosition textPositionWithIndex:0];
}

- (UITextPosition *)endOfDocument
{
    //KBCLogTrace();
    return [NKTTextPosition textPositionWithIndex:[text length]];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Evaluating Text Positions

- (NSComparisonResult)comparePosition:(NKTTextPosition *)textPosition toPosition:(NKTTextPosition *)otherTextPosition
{
    //KBCLogTrace();
    
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
    //KBCLogTrace();
    
    return (toPosition.index - fromPosition.index);
}

//--------------------------------------------------------------------------------------------------

#pragma mark Determining Layout and Writing Direction

- (UITextPosition *)positionWithinRange:(UITextRange *)uiTextRange farthestInDirection:(UITextLayoutDirection)direction
{
    //KBCLogTrace();
    
    NKTTextRange *textRange = (NKTTextRange *)uiTextRange;
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

- (UITextRange *)characterRangeByExtendingPosition:(UITextPosition *)uiTextPosition inDirection:(UITextLayoutDirection)direction
{
    //KBCLogTrace();
    
    NKTTextPosition *textPosition = (NKTTextPosition *)uiTextPosition;
    UITextRange *textRange = nil;
    
    switch (direction)
    {
        case UITextLayoutDirectionRight:
        {
            NKTLine *line = [self lineContainingTextPosition:textPosition];
            textRange = [textPosition textRangeWithTextPosition:line.textRange.end];
            break;
        }
        case UITextLayoutDirectionLeft:
        {
            NKTLine *line = [self lineContainingTextPosition:textPosition];
            textRange = [textPosition textRangeWithTextPosition:line.textRange.start];
            break;
        }
        case UITextLayoutDirectionUp:
        {
            textRange = [textPosition textRangeWithTextPosition:(NKTTextPosition *)[self beginningOfDocument]];
            break;
        }
        case UITextLayoutDirectionDown:
        {
            textRange = [textPosition textRangeWithTextPosition:(NKTTextPosition *)[self endOfDocument]];
            break;
        }
    }
    
    return textRange;
}

- (UITextWritingDirection)baseWritingDirectionForPosition:(UITextPosition *)uiTextPosition inDirection:(UITextStorageDirection)direction
{
    //KBCLogTrace();
    
    NKTTextPosition *textPosition = (NKTTextPosition *)uiTextPosition;
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

- (void)setBaseWritingDirection:(UITextWritingDirection)writingDirection forRange:(UITextRange *)uiTextRange
{
    //KBCLogTrace();
    
    NKTTextRange *textRange = (NKTTextRange *)uiTextRange;
    
    // WTF ... this is one fucked up API
    CTParagraphStyleSetting settings[1];
    settings[0].spec = kCTParagraphStyleSpecifierBaseWritingDirection;
    settings[0].valueSize = sizeof(CTWritingDirection);
    settings[0].value = &writingDirection;
    
    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(settings, 1);
    NSDictionary *attributes = [NSDictionary dictionaryWithObject:(id)paragraphStyle forKey:(id)kCTParagraphStyleAttributeName];
    CFRelease(paragraphStyle);
    // TODO: This should really be an attribute merge?
    [text addAttributes:attributes range:textRange.nsRange];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Geometry and Hit-Testing Methods

- (NSArray *)orderedRectsForTextRange:(UITextRange *)uiTextRange
{
    NKTTextRange *textRange = (NKTTextRange *)uiTextRange;
    NKTLine *firstLine = [self lineContainingTextPosition:textRange.start];
    NKTLine *lastLine = [self lineContainingTextPosition:textRange.end];
    
    if (firstLine == lastLine)
    {
        CGRect firstRect = [self caretRectForPosition:textRange.start];
        CGRect lastRect = [self caretRectForPosition:textRange.end];
        CGRect lineRect = CGRectMake(firstRect.origin.x,
                                     firstRect.origin.y,
                                     lastRect.origin.x - firstRect.origin.x,
                                     firstRect.size.height);
        return [NSArray arrayWithObject:[NSValue valueWithCGRect:lineRect]];
    }
    else
    {
        NSMutableArray *rects = [[[NSMutableArray alloc] init] autorelease];
        
        // Get first rect
        CGRect firstRect = [self caretRectForPosition:textRange.start];
        firstRect.size.width = self.bounds.size.width - margins.right - firstRect.origin.x;
        [rects addObject:[NSValue valueWithCGRect:firstRect]];
        
        // Iterate over lines in the middle
        for (NSUInteger lineIndex = firstLine.index + 1; lineIndex < lastLine.index; ++lineIndex)
        {
            CGRect rect = [self rectForLineAtIndex:lineIndex];
            [rects addObject:[NSValue valueWithCGRect:rect]];
        }
        
        // Get last rect
        CGRect lastRect = [self caretRectForPosition:textRange.end];
        lastRect.size.width = lastRect.origin.x - margins.left;
        lastRect.origin.x = margins.left;
        [rects addObject:[NSValue valueWithCGRect:lastRect]];
        
        return rects;
    }
}

- (CGRect)firstRectForRange:(UITextRange *)uiTextRange
{
    NSArray *rects = [self orderedRectsForTextRange:uiTextRange];
    return [[rects objectAtIndex:0] CGRectValue];
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point
{
    //KBCLogTrace();
    
    return [self closestTextPositionToPoint:point];
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point withinRange:(UITextRange *)uiTextRange
{
    //KBCLogTrace();
    
    NKTTextRange *textRange = (NKTTextRange *)uiTextRange;
    NKTTextPosition *textPosition = [self closestTextPositionToPoint:point];

    if (textPosition.index < textRange.start.index)
    {
        return textRange.start;
    }
    else if (textPosition.index > textRange.end.index)
    {
        return textRange.end;
    }
    else
    {
        return textPosition;
    }
}

- (UITextRange *)characterRangeAtPoint:(CGPoint)point
{
    //KBCLogTrace();
    
    NKTTextPosition *textPosition = [self closestTextPositionToPoint:point];
    return [textPosition textRange];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Text Input Delegate and Text Input Tokenizer

- (id <UITextInputDelegate>)inputDelegate
{
    return inputDelegate;
}

- (void)setInputDelegate:(id <UITextInputDelegate>)newInputDelegate
{
    inputDelegate = newInputDelegate;
}

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

- (NSDictionary *)textStylingAtPosition:(UITextPosition *)uiTextPosition inDirection:(UITextStorageDirection)direction
{
    NKTTextPosition *textPosition = (NKTTextPosition *)uiTextPosition;
    UIFont *font = [self insertionFontForTextPosition:textPosition];
    return [NSDictionary dictionaryWithObject:font forKey:UITextInputTextFontKey];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Returning the Text Input View

- (UIView *)textInputView
{
    //KBCLogTrace();
    
    return self;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Returning the View For Selection Elements

- (UIView *)selectionElementsView
{
    return self;
}

@end
