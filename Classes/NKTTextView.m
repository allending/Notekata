//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTTextView.h"
#import <CoreText/CoreText.h>
#import "NKTCaret.h"
#import "NKTTextSection.h"
#import "NKTLine.h"

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
    
    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                   action:@selector(tapped)];
    [self addGestureRecognizer:tapGestureRecognizer];
    
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
    // TODO: edge cases
    // text is nil, lineWidth < 0, CF usage
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
        return acceptsFirstResponder;
    }
    
    [caret restartBlinking];
    caret.center = [tapGestureRecognizer locationInView:self];
    caret.hidden = NO;
    return YES;
}

- (BOOL)resignFirstResponder {
    BOOL resignsFirstResponder = [super resignFirstResponder];
    [caret stopBlinking];
    caret.hidden = resignsFirstResponder;
    return resignsFirstResponder;
}

#pragma mark -
#pragma mark Responding to Gestures

- (void)tapped {
    if (![self isFirstResponder]) {
        [self becomeFirstResponder];
        return;
    }
    
    [caret restartBlinking];
    caret.center = [tapGestureRecognizer locationInView:self];
}

#pragma mark -
#pragma mark Inserting and Deleting Text

- (BOOL)hasText {
    return [self.text length] > 0;
}

- (void)insertText:(NSString *)theText {
    NSLog(@"insertText: %@", theText);
}

- (void)deleteBackward {
    NSLog(@"deleteBackward");
}

@end
