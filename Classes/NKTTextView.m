//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTTextView.h"
#import <CoreText/CoreText.h>
#import "NKTCaret.h"
#import "NKTLine.h"
#import "NKTTextPosition.h"
#import "NKTTextRange.h"
#import "NKTTextSection.h"

@interface NKTTextView()

#pragma mark -
#pragma mark Typesetting

- (void)typesetText;

#pragma mark -
#pragma mark Tiling Sections

- (void)tileSections;
- (void)clearVisibleSections;
- (BOOL)isDisplayingSectionForIndex:(NSInteger)index;
- (NKTTextSection *)dequeueReusableSection;
- (void)configureSection:(NKTTextSection *)section forIndex:(NSInteger)index;
- (CGRect)frameForSectionAtIndex:(NSInteger)index;

#pragma mark -
#pragma mark Responding to Gestures

- (void)tap;

#pragma mark -
#pragma mark Hit-Testing Lines

- (NSInteger)closestLineIndexToPoint:(CGPoint)point;

#pragma mark -
#pragma mark Getting Line Coordinates

- (CGPoint)originForLineAtIndex:(NSInteger)index;
- (CGPoint)convertPoint:(CGPoint)point toLineAtIndex:(NSInteger)index;

#pragma mark - UITextInput

@property(nonatomic, readwrite, copy) UITextRange *selectedTextRange;

- (UITextPosition *)closestPositionToPoint:(CGPoint)point;

@end

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

#if !defined(NKT_STRIP_DEBUG_SUPPORT)

@synthesize debug_alternatesSectionBackgroundColors;

#endif // #if !defined(NKT_STRIP_DEBUG_SUPPORT)

#pragma mark -
#pragma mark Initializing

- (void)commonInit_NKTTextView {
    self.alwaysBounceVertical = YES;
    
    //margins = UIEdgeInsetsMake(60.0, 80.0, 80.0, 60.0);
    margins = UIEdgeInsetsMake(90.0, 90.0, 120.0, 90.0);
    //lineHeight = 32.0;
    lineHeight = 30.0;
    
    horizontalRulesEnabled = YES;
    horizontalRuleColor = [[UIColor colorWithRed:0.72 green:0.72 blue:0.59 alpha:1.0] retain];
    horizontalRuleOffset = 3.0;
    
    verticalMarginEnabled = YES;
    verticalMarginColor = [[UIColor colorWithRed:0.7 green:0.3 blue:0.29 alpha:1.0] retain];
    verticalMarginInset = 60.0;

    visibleSections = [[NSMutableSet alloc] init];
    reusableSections = [[NSMutableSet alloc] init];
    
    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap)];
    [self addGestureRecognizer:tapGestureRecognizer];
    
    // TODO: create this lazily
    caret = [[NKTCaret alloc] initWithFrame:CGRectMake(0.0, 0.0, 3.0, 30.0)];
    caret.hidden = YES;
    [self addSubview:caret];
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.opaque = NO;
        self.clearsContextBeforeDrawing = YES;
        [self commonInit_NKTTextView];
    }
    
    return self;
}

- (void)awakeFromNib {
    [self commonInit_NKTTextView];
}

- (void)dealloc {
    [text release];
    [horizontalRuleColor release];
    [verticalMarginColor release];
    [typesettedLines release];
    [visibleSections release];
    [reusableSections release];
    [tapGestureRecognizer release];
    [caret release];
    [selectedTextRange release];
    //[tokenizer release];
    [super dealloc];
}

#pragma mark -
#pragma mark Updating the Content Size

- (void)updateContentSize {
    CGSize contentSize = self.bounds.size;
    contentSize.height = ((CGFloat)[typesettedLines count] *  self.lineHeight) + self.margins.top + self.margins.bottom;
    self.contentSize = contentSize;
}

- (void)setFrame:(CGRect)frame {
    CGRect previousFrame = self.frame;
    [super setFrame:frame];
    
    if (!CGRectEqualToRect(previousFrame, frame)) {
        [self typesetText];
        [self clearVisibleSections];
        [self tileSections];
        [self updateContentSize];
    }
}

#pragma mark -
#pragma mark Laying out Views

- (void)layoutSubviews 
{
    [super layoutSubviews];
    [self tileSections];
}

#pragma mark -
#pragma mark Accessing the Text

- (void)setText:(NSAttributedString *)newText {
    if (text != newText) {
        [text release];
        text = [newText copy];
        [self typesetText];
        [self clearVisibleSections];
        [self tileSections];
        [self updateContentSize];
    }
}

#pragma mark -
#pragma mark Configuring Text Layout

- (void)setLineHeight:(CGFloat)newLineHeight {
    lineHeight = newLineHeight;
    [self clearVisibleSections];
    [self tileSections];
    [self updateContentSize];
}

- (void)setMargins:(UIEdgeInsets)newMargins {
    margins = newMargins;
    [self typesetText];
    [self clearVisibleSections];
    [self tileSections];
    [self updateContentSize];
}

#pragma mark -
#pragma mark Typesetting

- (void)typesetText {
    [typesettedLines release];
    typesettedLines = [[NSMutableArray alloc] init];
    
    if ([self.text length] == 0) {
        return;
    }
    
    CTTypesetterRef typesetter = CTTypesetterCreateWithAttributedString((CFAttributedStringRef)self.text);
    CFIndex length = (CFIndex)[self.text length];
    CGFloat lineWidth = CGRectGetWidth(self.bounds) - (self.margins.left + self.margins.right);
    CFIndex charIndex = 0;
    
    while (charIndex < length) {
        CFIndex charCount = CTTypesetterSuggestLineBreak(typesetter, charIndex, lineWidth);
        CFRange range = CFRangeMake(charIndex, charCount);
        CTLineRef ctLine = CTTypesetterCreateLine(typesetter, range);
        NKTLine *line = [[NKTLine alloc] initWithCTLine:ctLine];
        CFRelease(ctLine);
        [typesettedLines addObject:line];
        [line release];
        charIndex += charCount;
    }
    
    CFRelease(typesetter);
}

#pragma mark -
#pragma mark Tiling Sections

- (void)tileSections {
    // Calculate visible sections
    CGRect visibleBounds = self.bounds;
    NSInteger firstVisibleSectionIndex = floorf(CGRectGetMinY(visibleBounds) / CGRectGetHeight(visibleBounds));
    NSInteger lastVisibleSectionIndex = floorf((CGRectGetMaxY(visibleBounds) - 1.0) / CGRectGetHeight(visibleBounds));
    
    // Remove no longer visible sections
    for (NKTTextSection *section in visibleSections) {
        if (section.index < firstVisibleSectionIndex || section.index > lastVisibleSectionIndex) {
            [reusableSections addObject:section];
            [section removeFromSuperview];
        }
    }
    
    [visibleSections minusSet:reusableSections];
    
    // Add missing sections
    for (NSInteger index = firstVisibleSectionIndex; index <= lastVisibleSectionIndex; ++index) {
        if (![self isDisplayingSectionForIndex:index]) {
            NKTTextSection *section = [self dequeueReusableSection];
            
            if (section == nil) {
                section = [[NKTTextSection alloc] initWithFrame:self.bounds];
            }
            
            [self configureSection:section forIndex:index];
            [visibleSections addObject:section];
            [self insertSubview:section atIndex:0];
        }
    }
}

- (void)clearVisibleSections {
    for (NKTTextSection *section in visibleSections) {
        [reusableSections addObject:section];
        [section removeFromSuperview];
    }
    
    [visibleSections removeAllObjects];
}

- (BOOL)isDisplayingSectionForIndex:(NSInteger)index {
    for (NKTTextSection *section in visibleSections) {
        if (section.index == index) {
            return YES;
        }
    }
    
    return NO;
}

- (NKTTextSection *)dequeueReusableSection {
    NKTTextSection *section = [reusableSections anyObject];
    
    if (section != nil) {
        [section retain];
        [reusableSections removeObject:section];
        return [section autorelease];
    }
    
    return nil;
}

- (void)configureSection:(NKTTextSection *)section forIndex:(NSInteger)index {
    section.index = index;
    section.frame = [self frameForSectionAtIndex:index];
    section.typesettedLines = typesettedLines;
    section.margins = self.margins;
    section.lineHeight = self.lineHeight;
    
    section.horizontalRulesEnabled = self.horizontalRulesEnabled;
    section.horizontalRuleColor = self.horizontalRuleColor;
    section.horizontalRuleOffset = self.horizontalRuleOffset;
    
    section.verticalMarginEnabled = self.verticalMarginEnabled;
    section.verticalMarginColor = self.verticalMarginColor;
    section.verticalMarginInset = self.verticalMarginInset;
    
#if !defined(NKT_STRIP_DEBUG_SUPPORT)
    
    if (self.debug_alternatesSectionBackgroundColors) {
        CGFloat green = (CGFloat)(index%2);
        CGFloat blue = 1.0 - (CGFloat)(index%2);
        section.backgroundColor = [UIColor colorWithRed:0.0 green:green blue:blue alpha:0.1];
    }
    
#endif // #if !defined(NKT_STRIP_DEBUG_SUPPORT)
    
    [section setNeedsDisplay];
}

- (CGRect)frameForSectionAtIndex:(NSInteger)index {
    CGRect sectionFrame = self.bounds;
    sectionFrame.origin.x = 0.0;
    sectionFrame.origin.y = index * CGRectGetHeight(sectionFrame);
    return sectionFrame;
}

#pragma mark -
#pragma mark Managing the Responder Chain

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)becomeFirstResponder {
    BOOL acceptsFirstResponder = [super becomeFirstResponder];
    
    if (!acceptsFirstResponder) {
        return NO;
    }
    
    caret.hidden = NO;
    return YES;
}

- (BOOL)resignFirstResponder {
    BOOL resignsFirstResponder = [super resignFirstResponder];
    
    if (!resignsFirstResponder) {
        return NO;
    }

    caret.hidden = YES;
    return YES;
}

#pragma mark -
#pragma mark Responding to Gestures

- (void)tap {
    // Make sure view is the first responder
    if (![self isFirstResponder] && ![self becomeFirstResponder]) {
        return;
    }
    
    CGPoint tapLocation = [tapGestureRecognizer locationInView:self];
    NKTTextPosition *textPosition = (NKTTextPosition *)[self closestPositionToPoint:tapLocation];
    NKTTextRange *textRange = [textPosition emptyTextRange];
    [self setSelectedTextRange:textRange];
}

#pragma mark -
#pragma mark Inserting and Deleting Text

- (BOOL)hasText {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    return [self.text length] > 0;
}

- (void)insertText:(NSString *)theText {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)deleteBackward {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

#pragma mark -
#pragma mark Searching for Lines

- (NSUInteger)lineIndexContainingTextPosition:(NKTTextPosition *)textPosition {
    NSUInteger index = 0;
    
    for (NKTLine *line in typesettedLines) {
        NKTTextRange *textRange = [line textRange];
        
        if ([textRange containsTextPosition:textPosition]) {
            return index;
        }
        
        ++index;
    }
    
    return NSNotFound;
}

#pragma mark -
#pragma mark Working with Marked and Selected Text

@synthesize selectedTextRange;

- (void)setSelectedTextRange:(UITextRange *)newSelectedTextRange {
    if (selectedTextRange == newSelectedTextRange) {
        return;
    }
    
    [selectedTextRange release];
    selectedTextRange = [newSelectedTextRange copy];

    // TODO: Only handle empty range for now
    
    NSUInteger lineIndex = [self lineIndexContainingTextPosition:(NKTTextPosition *)selectedTextRange.start];
    NKTLine *line = [typesettedLines objectAtIndex:lineIndex];
    
    CGFloat offset = [line offsetForTextAtIndex:selectedTextRange.startIndex];
    CGPoint lineOrigin = [self originForLineAtIndex:lineIndex];
    CGPoint caretOrigin = lineOrigin;
    caretOrigin.x += (offset - 1.0);
    caretOrigin.y -= ([line ascent] + 1.0);
    CGRect caretRect;
    caretRect.origin = caretOrigin;
    caretRect.size.height = [line ascent] + [line descent] + 2.0;
    caretRect.size.width = 3.0;
    caret.frame = caretRect;
    [caret startBlinking];
}

#pragma mark -
#pragma mark Hit-Testing Lines

- (NSInteger)closestLineIndexToPoint:(CGPoint)point {
    NSInteger lineIndex = (NSInteger)floor((point.y - self.margins.top) / self.lineHeight);
    return lineIndex;
}

#pragma mark -
#pragma mark Getting Line Coordinates

- (CGPoint)originForLineAtIndex:(NSInteger)index {
    // First baseline = top margin + line height
    CGFloat y = margins.top + (((CGFloat)index + 1.0) * self.lineHeight);
    CGPoint lineOrigin = CGPointMake(self.margins.left, y);
    return lineOrigin;
}

- (CGPoint)convertPoint:(CGPoint)point toLineAtIndex:(NSInteger)index {
    CGPoint lineOrigin = [self originForLineAtIndex:index];
    CGPoint localPoint = CGPointMake(point.x - lineOrigin.x, point.y - lineOrigin.y);
    return localPoint;
}

#pragma mark -
#pragma mark Geometry and Hit-Testing Methods

- (UITextPosition *)closestPositionToPoint:(CGPoint)point {    
    NSInteger lineIndex = [self closestLineIndexToPoint:point];
    
    // Handle points outside of typesetted lines specially
    if (lineIndex < 0) {
        return [NKTTextPosition textPositionWithIndex:0];
    } else if (lineIndex > [typesettedLines count] - 1) {
        return [NKTTextPosition textPositionWithIndex:[typesettedLines count] - 1];
    }
    
    NKTLine *line = [typesettedLines objectAtIndex:lineIndex];
    CGPoint localPoint = [self convertPoint:point toLineAtIndex:lineIndex];
    return [line closestTextPositionToPoint:localPoint];
}

@end

/*
#pragma mark -
#pragma mark UITextInput

#pragma mark -
#pragma mark Replacing and Returning Text

- (NSString *)textInRange:(UITextRange *)textRange {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    return [[self.text string] substringWithRange:((NKTTextRange *)textRange).nsRange];
}

- (void)replaceRange:(UITextRange *)range withText:(NSString *)text {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

#pragma mark -
#pragma mark Working with Marked and Selected Text

@synthesize selectedTextRange;

- (void)setSelectedTextRange:(UITextRange *)newSelectedTextRange {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if (selectedTextRange != newSelectedTextRange) {
        [selectedTextRange release];
        selectedTextRange = [newSelectedTextRange copy];
        
        NSInteger lineIndex = 0;
        
        // Find line position is in
        for (NKTLine *line in typesettedLines) {
            NKTTextRange *lineTextRange = [line textRange];
            
            // If new selected text range begins on line, use line
            if ([selectedTextRange startsInTextRange:lineTextRange]) {
                CGFloat offset = [line offsetForTextAtIndex:selectedTextRange.startIndex];
                CGFloat y = self.margins.top + ((CGFloat)(lineIndex) + 0.7) * self.lineHeight;
                CGPoint caretLocation = CGPointMake(self.margins.left + offset, y);
                caret.center = caretLocation;
                [caret startBlinking];
            }
            
            ++lineIndex;
        }
    }
}

//@synthesize markedTextRange;
//@synthesize markedTextStyle;

- (void)setMarkedText:(NSString *)markedText selectedRange:(NSRange)selectedRange {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)unmarkText {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

#pragma mark -
#pragma mark Computing Text Ranges and Text Positions

- (UITextRange *)textRangeFromPosition:(UITextPosition *)fromPosition toPosition:(UITextPosition *)toPosition {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSUInteger location = ((NKTTextPosition *)fromPosition).index;
    NSUInteger length = ((NKTTextPosition *)toPosition).index - location;
    return [NKTTextRange textRangeWithNSRange:NSMakeRange(location, length)];
}

- (UITextPosition *)positionFromPosition:(UITextPosition *)position offset:(NSInteger)offset {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSInteger index = ((NKTTextPosition *)position).index + offset;
    return [NKTTextPosition textPositionWithIndex:index];
}

- (UITextPosition *)positionFromPosition:(UITextPosition *)position inDirection:(UITextLayoutDirection)direction offset:(NSInteger)offset {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    // TODO: implement this correctly
    return position;
}

- (UITextPosition *)beginningOfDocument {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    return [NKTTextPosition textPositionWithIndex:0];
}

- (UITextPosition *)endOfDocument {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    return [NKTTextPosition textPositionWithIndex:[self.text length] - 1];
}

#pragma mark -
#pragma mark Evaluating Text Positions

- (NSComparisonResult)comparePosition:(UITextPosition *)position toPosition:(UITextPosition *)otherPosition {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSInteger index = ((NKTTextPosition *)position).index;
    NSInteger otherIndex = ((NKTTextPosition *)otherPosition).index;
    
    if (index < otherIndex) {
        return NSOrderedAscending;
    } else if (index > otherIndex) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

- (NSInteger)offsetFromPosition:(UITextPosition *)fromPosition toPosition:(UITextPosition *)toPosition {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSInteger fromIndex = ((NKTTextPosition *)fromPosition).index;
    NSInteger toIndex = ((NKTTextPosition *)toPosition).index;
    return toIndex - fromIndex;
}

#pragma mark -
#pragma mark Determining Layout and Writing Direction

- (UITextPosition *)positionWithinRange:(UITextRange *)range farthestInDirection:(UITextLayoutDirection)direction {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    // TODO: implement this correctly
    NSInteger index = ((NKTTextRange *)range).nsRange.location;
    return [NKTTextPosition textPositionWithIndex:index];
}

- (UITextRange *)characterRangeByExtendingPosition:(UITextPosition *)position inDirection:(UITextLayoutDirection)direction {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    // TODO: implement this correctly
    NSInteger index = ((NKTTextPosition *)position).index;
    return [NKTTextRange textRangeWithNSRange:NSMakeRange(index, 0)];
}

- (UITextWritingDirection)baseWritingDirectionForPosition:(UITextPosition *)position inDirection:(UITextStorageDirection)direction {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    // TODO: implement this correctly
    return UITextWritingDirectionNatural;
}

- (void)setBaseWritingDirection:(UITextWritingDirection)writingDirection forRange:(UITextRange *)range {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    // TODO: implement this correctly
}

#pragma mark -
#pragma mark Geometry and Hit-Testing Methods

- (CGRect)firstRectForRange:(UITextRange *)range {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    // TODO: implement this correctly
    int index = ((NKTTextRange *)range).nsRange.location;
    NSInteger location = ((NKTTextRange *)range).nsRange.location;
    NSInteger length = ((NKTTextRange *)range).nsRange.length;
    
    // Iterate over all lines
    for (NSUInteger i = 0; i < [typesettedLines count]; ++i) {
        NKTLine *line = [typesettedLines objectAtIndex:i];
        CTLineRef ctLine = line.ctLine;
        CFRange lineRange = CTLineGetStringRange(ctLine);
        // Local index is index of input range relative to line
        int localIndex = index - lineRange.location;
        
        if (localIndex >= 0 && localIndex < lineRange.length) {
            int finalIndex = MIN(lineRange.location + lineRange.length,
                                 location + length);
            
            CGFloat xStart = CTLineGetOffsetForStringIndex(ctLine, index, NULL);
            CGFloat xEnd = CTLineGetOffsetForStringIndex(ctLine, finalIndex, NULL);

            CGFloat lineY = self.margins.top + (CGFloat)i * self.lineHeight;
            CGPoint origin = CGPointMake(self.margins.left, lineY);
            
            CGFloat ascent, descent;
            CTLineGetTypographicBounds(ctLine, &ascent, &descent, NULL);
            
            return CGRectMake(xStart, origin.y - descent, xEnd - xStart, ascent + descent);
        }
    }
    
    return CGRectNull;
}

- (CGRect)caretRectForPosition:(UITextPosition *)position {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    // TODO: implement this correctly
    return CGRectMake(0.0, 0.0, 3.0, 30.0);
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    NSInteger lineIndex = (NSInteger)floor((point.y - margins.top) / lineHeight);
    
    if (lineIndex < 0) {
        return [NKTTextPosition textPositionWithIndex:0];
    } else if (lineIndex > [typesettedLines count] - 1) {
        return [NKTTextPosition textPositionWithIndex:[typesettedLines count] - 1];
    }
    
    // Convert point to line space
    CGFloat lineY = margins.top + (CGFloat)lineIndex * lineHeight;
    CGPoint lineOrigin = CGPointMake(margins.left, lineY);
    CGPoint localPoint = CGPointMake(point.x - lineOrigin.x, point.y - lineOrigin.y);
    NKTLine *line = [typesettedLines objectAtIndex:(NSUInteger)lineIndex];
    return [line closestTextPositionToPoint:localPoint];
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point withinRange:(UITextRange *)range {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    return [NKTTextPosition textPositionWithIndex:0];
}

- (UITextRange *)characterRangeAtPoint:(CGPoint)point {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    return [NKTTextRange textRangeWithNSRange:NSMakeRange(0, 0)];
}

#pragma mark -
#pragma mark Text Input Delegate and Text Input Tokenizer

//@synthesize inputDelegate;

//- (id<UITextInputTokenizer>)tokenizer;
//{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
//    if (tokenizer == nil) {
//        tokenizer = [[[UITextInputStringTokenizer alloc] initWithTextInput:self] retain];
//    }
//    
//    return tokenizer;
//}
*/
