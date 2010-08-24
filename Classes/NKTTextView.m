//--------------------------------------------------------------------------------------------------
//
// Copyright 2010 Allen Ding. All rights reserved.
//
//--------------------------------------------------------------------------------------------------

#import "NKTTextView.h"
#import <CoreText/CoreText.h>
#import "NKTCaret.h"
#import "NKTLine.h"
#import "NKTTextPosition.h"
#import "NKTTextRange.h"
#import "NKTTextSection.h"

#pragma mark -
#pragma mark NKTTextView Private API

@interface NKTTextView()

#pragma mark -
#pragma mark Generating the View Contents

- (void)regenerateContents;

#pragma mark -
#pragma mark Typesetting

- (void)typesetText;

#pragma mark -
#pragma mark Tiling Sections

- (void)tileSections;
- (void)untileVisibleSections;
- (BOOL)isDisplayingSectionAtIndex:(NSInteger)index;
- (NKTTextSection *)dequeueReusableSection;
- (void)configureSection:(NKTTextSection *)section atIndex:(NSInteger)index;
- (CGRect)frameForSectionAtIndex:(NSInteger)index;

#pragma mark -
#pragma mark Responding to Gestures

- (void)tap;

#pragma mark -
#pragma mark Hit-Testing

- (void)getClosestTextPosition:(NKTTextPosition **)textPosition sourceLineIndex:(NSUInteger *)originatingLineIndex toPoint:(CGPoint)point;

#pragma mark -
#pragma mark Getting and Converting Coordinates

- (CGPoint)originForLineAtIndex:(NSUInteger)index;
- (CGPoint)convertPoint:(CGPoint)point toLineAtIndex:(NSUInteger)index;

#pragma mark -
#pragma mark Getting Line Indices

- (NSInteger)indexForVirtualLineSpanningVerticalOffset:(CGFloat)verticalOffset;
- (NSUInteger)indexForLineContainingTextPosition:(NKTTextPosition *)textPosition;

#pragma mark -
#pragma mark Getting Font Metrics at Text Positions

- (void)getFontAscent:(CGFloat *)ascent descent:(CGFloat *)descent atTextPosition:(NKTTextPosition *)textPosition;

#pragma mark -
#pragma mark - Managing the Caret

- (CGRect)frameForCaretAtTextPosition:(NKTTextPosition *)textPosition withSourceLineAtIndex:(NSUInteger)sourceLineIndex;

#pragma mark -
#pragma mark Working with Marked and Selected Text

- (void)setSelectedTextRange:(NKTTextRange *)textRange withSourceLineAtIndex:(NSUInteger)sourceLineIndex;

@property(nonatomic, readwrite, copy) UITextRange *selectedTextRange;

@end

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

@synthesize selectedTextRange;

#if !defined(NKT_STRIP_DEBUG_SUPPORT)

@synthesize debug_alternatesSectionBackgroundColors;

#endif // #if !defined(NKT_STRIP_DEBUG_SUPPORT)

//--------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Initializing

- (void)commonInit_NKTTextView {
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
    
    // Create gesture recognizers
    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap)];
    [self addGestureRecognizer:tapGestureRecognizer];
    
    // TODO: create this lazily?
    caret = [[NKTCaret alloc] initWithFrame:CGRectMake(0.0, 0.0, 3.0, 30.0)];
    caret.hidden = YES;
    [self addSubview:caret];
    
    selectedTextRange = [[NKTTextRange alloc] initWithNSRange:NSMakeRange(0, 0)];
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
//    [tokenizer release];
    [super dealloc];
}

//--------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Updating the Content Size

- (void)updateContentSize {
    CGSize size = self.bounds.size;
    size.height = ((CGFloat)[typesettedLines count] *  lineHeight) + margins.top + margins.bottom;
    self.contentSize = size;
}

//--------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Modifying the Bounds and Frame Rectangles

- (void)setFrame:(CGRect)frame {
    if (CGRectEqualToRect(self.frame, frame)) {
        return;
    }
    
    [super setFrame:frame];
    [self regenerateContents];
}

//--------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Laying out Views

- (void)layoutSubviews 
{
    [super layoutSubviews];
    [self tileSections];
}

//--------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Accessing the Text

// TODO: follow UITextView conventions on ownership
- (void)setText:(NSMutableAttributedString *)newText {
    [newText retain];
    [text release];
    text = newText;
    [self regenerateContents];
}

//--------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Configuring Text Layout and Style

- (void)setLineHeight:(CGFloat)newLineHeight {
    lineHeight = newLineHeight;
    // Don't need to typeset since the line width is not changing
    [self untileVisibleSections];
    [self tileSections];
    [self updateContentSize];
}

- (void)setMargins:(UIEdgeInsets)newMargins {
    margins = newMargins;
    [self regenerateContents];
}

//--------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Generating the View Contents

- (void)regenerateContents {
    [self typesetText];
    [self untileVisibleSections];
    [self tileSections];
    [self updateContentSize];
}

//--------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Typesetting

- (void)typesetText {
    [typesettedLines release];
    typesettedLines = nil;
    
    if ([text length] == 0) {
        return;
    }

    typesettedLines = [[NSMutableArray alloc] init];
    // TODO: log if this fails
    CTTypesetterRef typesetter = CTTypesetterCreateWithAttributedString((CFAttributedStringRef)text);
    CFIndex length = (CFIndex)[text length];
    CGFloat lineWidth = CGRectGetWidth(self.bounds) - (margins.left + margins.right);
    CFIndex charIndex = 0;
    
    while (charIndex < length) {
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

#pragma mark -
#pragma mark Tiling Sections

- (void)tileSections {
    CGRect bounds = self.bounds;
    NSInteger firstVisibleSectionIndex = (NSInteger)floorf(CGRectGetMinY(bounds) / CGRectGetHeight(bounds));
    NSInteger lastVisibleSectionIndex = (NSInteger)floorf((CGRectGetMaxY(bounds) - 1.0) / CGRectGetHeight(bounds));
    
    // Recycle no longer visible sections
    for (NKTTextSection *section in visibleSections) {
        if (section.index < firstVisibleSectionIndex || section.index > lastVisibleSectionIndex) {
            [reusableSections addObject:section];
            [section removeFromSuperview];
        }
    }
    
    [visibleSections minusSet:reusableSections];
    
    // Add missing sections
    for (NSInteger index = firstVisibleSectionIndex; index <= lastVisibleSectionIndex; ++index) {
        if (![self isDisplayingSectionAtIndex:index]) {
            NKTTextSection *section = [self dequeueReusableSection];
            
            if (section == nil) {
                section = [[NKTTextSection alloc] initWithFrame:self.bounds];
            }
            
            [self configureSection:section atIndex:index];
            [self insertSubview:section atIndex:0];
            [visibleSections addObject:section];
        }
    }
}

- (void)untileVisibleSections {
    for (NKTTextSection *section in visibleSections) {
        [reusableSections addObject:section];
        [section removeFromSuperview];
    }
    
    [visibleSections removeAllObjects];
}

- (BOOL)isDisplayingSectionAtIndex:(NSInteger)index {
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
        [[section retain] autorelease];
        [reusableSections removeObject:section];
        return section;
    }
    
    return nil;
}

- (void)configureSection:(NKTTextSection *)section atIndex:(NSInteger)index {
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
    
#if !defined(NKT_STRIP_DEBUG_SUPPORT)
    
    if (debug_alternatesSectionBackgroundColors) {
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
    sectionFrame.origin.y = (CGFloat)index * CGRectGetHeight(sectionFrame);
    return sectionFrame;
}

//--------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Managing the Responder Chain

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)resignFirstResponder {
    BOOL resignsFirstResponder = [super resignFirstResponder];
    
    if (!resignsFirstResponder) {
        return NO;
    }

    // TODO: Hide all ranges etc...
    caret.hidden = YES;
    return YES;
}

//--------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Responding to Gestures

- (void)tap {
    if (![self isFirstResponder] && ![self becomeFirstResponder]) {
        return;
    }
    
    CGPoint tapLocation = [tapGestureRecognizer locationInView:self];
    NKTTextPosition *textPosition = nil;
    NSUInteger sourceLineIndex = NSNotFound;
    [self getClosestTextPosition:&textPosition sourceLineIndex:&sourceLineIndex toPoint:tapLocation];
    [self setSelectedTextRange:[textPosition textRange] withSourceLineAtIndex:sourceLineIndex];
}

//--------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Inserting and Deleting Text

- (BOOL)hasText {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    return [text length] > 0;
}

- (void)insertText:(NSString *)theText {
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

- (void)deleteBackward {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NKTTextPosition *textPosition = (NKTTextPosition *)selectedTextRange.start;
    NSUInteger textIndex = textPosition.index;
    
    if (textIndex == 0) {
        return;
    } else {
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

#pragma mark -
#pragma mark Hit Testing

// The index of the text position returned will be between 0 and the last string index plus 1.
- (void)getClosestTextPosition:(NKTTextPosition **)textPosition sourceLineIndex:(NSUInteger *)sourceLineIndex toPoint:(CGPoint)point {
    NSInteger virtualLineIndex = [self indexForVirtualLineSpanningVerticalOffset:point.y];
    
    // Point lies before the first real line
    if (virtualLineIndex < 0 || [typesettedLines count] == 0) {
        if (textPosition != NULL) {
            *textPosition = [NKTTextPosition textPositionWithIndex:0];
        }
        
        if (sourceLineIndex != NULL) {
            *sourceLineIndex = NSNotFound;
        }
        
        return;
    }
    
    // Point lies beyond the last real line
    if (virtualLineIndex >= (NSInteger)[typesettedLines count]) {
        if (textPosition != NULL) {
            *textPosition = [NKTTextPosition textPositionWithIndex:[text length]];
        }
        
        if (sourceLineIndex != NULL) {
            *sourceLineIndex = NSNotFound;
        }
        
        return;
    }
    
    // By this point, the virtual line index indexes a real line, so use it
    
    if (textPosition != NULL) {
        CGPoint lineLocalPoint = [self convertPoint:point toLineAtIndex:(NSUInteger)virtualLineIndex];
        NKTLine *line = [typesettedLines objectAtIndex:(NSUInteger)virtualLineIndex];
        *textPosition = [line closestTextPositionToPoint:lineLocalPoint];
    }
    
    if (sourceLineIndex != NULL) {
        *sourceLineIndex = (NSUInteger)virtualLineIndex;
    }
}

//--------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Getting and Converting Coordinates

- (CGPoint)originForLineAtIndex:(NSUInteger)index {
    CGFloat y = margins.top + lineHeight + ((CGFloat)index * lineHeight);
    CGPoint lineOrigin = CGPointMake(margins.left, y);
    return lineOrigin;
}

- (CGPoint)convertPoint:(CGPoint)point toLineAtIndex:(NSUInteger)index {
    CGPoint lineOrigin = [self originForLineAtIndex:index];
    return CGPointMake(point.x - lineOrigin.x, point.y - lineOrigin.y);
}

//--------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Getting Line Indices

- (NSInteger)indexForVirtualLineSpanningVerticalOffset:(CGFloat)verticalOffset {
    return (NSInteger)floor((verticalOffset - margins.top) / lineHeight);
}

// Returns NSNotFound if no line contains the text position.
- (NSUInteger)indexForLineContainingTextPosition:(NKTTextPosition *)textPosition {    
    NSUInteger lineIndex = 0;
    
    for (NKTLine *line in typesettedLines) {
        NKTTextRange *textRange = [line textRange];
        
        if ([textRange containsTextPosition:textPosition]) {
            return lineIndex;
        }
        
        ++lineIndex;
    }
    
    return NSNotFound;
}

//--------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Getting Font Metrics at Text Positions

// Returns font metrics at the text position if available, otherwise returns the default system font
// metrics. The metrics at a text position are found by querying the font attributes of the
// preceding character if available, otherwise of the following character.
- (void)getFontAscent:(CGFloat *)ascent descent:(CGFloat *)descent atTextPosition:(NKTTextPosition *)textPosition {
    CTFontRef font = NULL;
    
    // Look for available font attribute at the text position
    if ([text length] > 0) {
        NSUInteger textIndex = (NSUInteger)MAX(0, (NSInteger)textPosition.index - 1);
        textIndex = (NSUInteger)MIN(textIndex, ((NSInteger)[text length] - 1));
        NSDictionary *textAttributes = [text attributesAtIndex:textIndex effectiveRange:NULL];
        font = (CTFontRef)[textAttributes objectForKey:(id)kCTFontAttributeName];
    }
    
    if (font != NULL) {
        if (ascent != NULL) {
            *ascent = CTFontGetAscent(font);
        }
        
        if (descent != NULL) {
            *descent = CTFontGetDescent(font);
        }
    } else {
        if (ascent != NULL) {
            *ascent = 12.0 * 0.77;
        }
        
        if (descent != NULL) {
            *descent = 12.0 * 0.23;
        }
    }
}

//--------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Managing the Caret

- (CGRect)frameForCaretAtTextPosition:(NKTTextPosition *)textPosition withSourceLineAtIndex:(NSUInteger)sourceLineIndex {
    const CGFloat caretWidth = 2.0;
    const CGFloat caretVerticalPadding = 1.0;

    // Get the ascent and descent at the text position
    CGFloat ascent = 0.0;
    CGFloat descent = 0.0;
    [self getFontAscent:&ascent descent:&descent atTextPosition:textPosition];
    
    // Get the line origin and offset for the text position
    CGPoint lineOrigin = CGPointZero;
    CGFloat charOffset = 0.0;
    
    if (sourceLineIndex != NSNotFound) {
        NKTLine *line = [typesettedLines objectAtIndex:sourceLineIndex];
        lineOrigin = [self originForLineAtIndex:sourceLineIndex];
        charOffset = [line offsetForCharAtTextPosition:textPosition];
    } else if (textPosition.index == 0) {
        lineOrigin = [self originForLineAtIndex:0];
    } else if (textPosition.index == [text length]) {
        NSAssert([typesettedLines count] > 0, @"there should be at least one typesetted line");
        // Text length guaranteed to be > 0 here because we accounted for index 0 above
        
        if ([[text string] characterAtIndex:((NSInteger)[text length] - 1)] == '\n') {
            // The last character is a line break, set the line origin to be the origin of where
            // the line beyond the last real line would actually be.
            lineOrigin = [self originForLineAtIndex:[typesettedLines count]];
        } else {
            // Last character is not a line break, so caret rect lies on the last real line.
            NSUInteger lastLineIndex = [typesettedLines count] - 1;
            NKTLine *line = [typesettedLines objectAtIndex:lastLineIndex];
            lineOrigin = [self originForLineAtIndex:lastLineIndex];
            charOffset = [line offsetForCharAtTextPosition:textPosition];
        }
    } else {
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

#pragma mark -
#pragma mark Working with Marked and Selected Text

- (void)setSelectedTextRange:(NKTTextRange *)textRange withSourceLineAtIndex:(NSUInteger)sourceLineIndex {
    [selectedTextRange autorelease];
    selectedTextRange = [textRange copy];
    
    if (selectedTextRange.empty) {
        caret.frame = [self frameForCaretAtTextPosition:(NKTTextPosition *)selectedTextRange.start withSourceLineAtIndex:sourceLineIndex];
        caret.hidden = NO;
        [caret startBlinking];
    }
}

- (void)setSelectedTextRange:(UITextRange *)textRange {
    [self setSelectedTextRange:(NKTTextRange *)textRange withSourceLineAtIndex:NSNotFound];
}

@end

//------------------------------------------------------------------------------

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

@synthesize inputDelegate;

- (id<UITextInputTokenizer>)tokenizer;
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if (tokenizer == nil) {
        tokenizer = [[[UITextInputStringTokenizer alloc] initWithTextInput:self] retain];
    }
    
    return tokenizer;
}

*/
