//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTTextView.h"
#import <CoreText/CoreText.h>
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

@synthesize horizontalLinesEnabled;
@synthesize horizontalLineColor;
@synthesize horizontalLineOffset;

@synthesize verticalMarginEnabled;
@synthesize verticalMarginColor;
@synthesize verticalMarginInset;

#pragma mark -
#pragma mark Initializing

- (void)initInternal_NKTTextView {
    self.alwaysBounceVertical = YES;

    margins = UIEdgeInsetsMake(60.0, 40.0, 80.0, 60.0);
    lineHeight = 32.0;
    
    horizontalLinesEnabled = YES;
    horizontalLineColor = [[UIColor colorWithRed:0.72 green:0.72 blue:0.59 alpha:1.0] retain];
    horizontalLineOffset = 3.0;
    
    verticalMarginEnabled = NO;
    verticalMarginInset = 60.0;

    visibleSections = [[NSMutableSet alloc] init];
    reusableSections = [[NSMutableSet alloc] init];
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self initInternal_NKTTextView];
    }
    
    return self;
}

- (void)awakeFromNib {
    [self initInternal_NKTTextView];
}

- (void)dealloc {
    [text release];
    [horizontalLineColor release];
    [verticalMarginColor release];
    [typesettedLines release];
    [visibleSections release];
    [reusableSections release];
    [super dealloc];
}

#pragma mark -
#pragma mark Updating the Content Size

- (void)updateContentSize {
    CGSize contentSize = self.bounds.size;
    contentSize.height = ((CGFloat)[typesettedLines count] *  self.lineHeight) + self.margins.top + self.margins.bottom;
    self.contentSize = contentSize;
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
    firstVisibleSectionIndex = MAX(firstVisibleSectionIndex, 0);
    
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
    
    section.horizontalLinesEnabled = self.horizontalLinesEnabled;
    section.horizontalLineColor = self.horizontalLineColor;
    section.horizontalLineOffset = self.horizontalLineOffset;
    
    // Debug coloring
    //section.backgroundColor = [UIColor colorWithRed:0.0 green:index%2 blue:1.0 - index%2 alpha:0.1];
    [section setNeedsDisplay];
}

- (CGRect)frameForSectionAtIndex:(NSInteger)index {
    CGRect sectionFrame = self.bounds;
    sectionFrame.origin.x = 0.0;
    sectionFrame.origin.y = index * CGRectGetHeight(sectionFrame);
    return sectionFrame;
}

#pragma mark -
#pragma mark Drawing

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    // Set up a graphics state suitable for drawing lines
    CGContextSaveGState(context);
    CGContextSetShouldAntialias(context, NO);
    CGContextSetLineWidth(context, 1.0);
    
    // Draw vertical margin
    if (self.verticalMarginEnabled && self.verticalMarginColor != nil) {
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, self.verticalMarginInset, 0.0);
        CGContextAddLineToPoint(context, self.verticalMarginInset, CGRectGetHeight(self.bounds));
        CGContextSetStrokeColorWithColor(context, self.verticalMarginColor.CGColor);
        CGContextStrokePath(context);
    }
    
    CGContextRestoreGState(context);
}

@end
