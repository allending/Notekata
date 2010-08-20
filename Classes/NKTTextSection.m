//===================================================================================================
//
// Copyright 2010 Allen Ding. All rights reserved.
//
//===================================================================================================

#import "NKTTextSection.h"
#import "NKTLine.h"

@interface NKTTextSection()

#pragma mark -
#pragma mark Getting Indices

- (NSUInteger)indexForFirstVisibleHorizontalRule;

#pragma mark -
#pragma mark Getting Offsets

- (CGFloat)verticalOffset;
- (CGFloat)verticalOffsetForLineAtIndex:(NSUInteger)anIndex;
- (CGFloat)verticalOffsetForHorizontalRuleAtIndex:(NSUInteger)anIndex;

#pragma mark -
#pragma mark Drawing

- (void)drawHorizontalRulesInContext:(CGContextRef)context;
- (void)drawVerticalMarginInContext:(CGContextRef)context;
- (void)drawTypesettedLinesInContext:(CGContextRef)context;
- (NSRange)typesettedLineRangeForDrawing;

@end

//===================================================================================================

@implementation NKTTextSection

@synthesize index;

@synthesize typesettedLines;

@synthesize margins;
@synthesize lineHeight;
@synthesize numberOfSkirtLines;

@synthesize horizontalRulesEnabled;
@synthesize horizontalRuleColor;
@synthesize horizontalRuleOffset;

@synthesize verticalMarginEnabled;
@synthesize verticalMarginColor;
@synthesize verticalMarginInset;

#pragma mark -
#pragma mark Initializing

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = YES;
        self.clearsContextBeforeDrawing = NO;
        numberOfSkirtLines = 1;
    }
    
    return self;
}

- (void)dealloc {
    [typesettedLines release];
    [horizontalRuleColor release];
    [verticalMarginColor release];
    [super dealloc];
}

#pragma mark -
#pragma mark Getting Indices

- (NSUInteger)indexForFirstVisibleHorizontalRule {
    CGFloat topRuleOffset = [self verticalOffsetForHorizontalRuleAtIndex:0];
    CGFloat sectionOffset = [self verticalOffset];
    NSInteger firstVisibleRuleIndex = (NSInteger)ceil((sectionOffset - topRuleOffset) / lineHeight);
    firstVisibleRuleIndex = MAX(firstVisibleRuleIndex, 0);
    return (NSUInteger)firstVisibleRuleIndex;
}

#pragma mark -
#pragma mark Getting Offsets

- (CGFloat)verticalOffset {
    return (CGFloat)index * CGRectGetHeight(self.bounds);
}

- (CGFloat)verticalOffsetForLineAtIndex:(NSUInteger)anIndex {
    return margins.top + ((CGFloat)(anIndex + 1) * lineHeight);
}

- (CGFloat)verticalOffsetForHorizontalRuleAtIndex:(NSUInteger)anIndex {
    return [self verticalOffsetForLineAtIndex:anIndex] + horizontalRuleOffset;
}

#pragma mark -
#pragma mark Drawing

- (void)drawRect:(CGRect)rect {    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self drawHorizontalRulesInContext:context];
    [self drawVerticalMarginInContext:context];
    [self drawTypesettedLinesInContext:context];
}

- (void)drawHorizontalRulesInContext:(CGContextRef)context {
    // Horizontal rules are not drawn above the first typesetted line
    if (index < 0 || !horizontalRulesEnabled || horizontalRuleColor == nil) {
        return;
    }
    
    CGContextSaveGState(context);
    CGContextSetShouldAntialias(context, NO);
    CGContextSetLineWidth(context, 1.0);
    CGContextBeginPath(context);
    
    NSUInteger firstVisibleRuleIndex = [self indexForFirstVisibleHorizontalRule];
    CGFloat ruleOffset = [self verticalOffsetForHorizontalRuleAtIndex:firstVisibleRuleIndex];
    CGFloat sectionOffset = [self verticalOffset];
    // Draw in local space
    CGFloat localOffset = ruleOffset - sectionOffset;
    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat height = CGRectGetHeight(self.bounds);
    
    for (CGFloat y = localOffset; y < height; y += lineHeight) {
        CGContextMoveToPoint(context, 0.0, y);
        CGContextAddLineToPoint(context, width, y);
    }
    
    CGContextSetStrokeColorWithColor(context, horizontalRuleColor.CGColor);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
}

- (void)drawVerticalMarginInContext:(CGContextRef)context {
    if (!verticalMarginEnabled || verticalMarginColor == nil) {
        return;
    }
    
    CGContextSaveGState(context);
    CGContextSetShouldAntialias(context, NO);
    CGContextSetLineWidth(context, 1.0);
    CGContextBeginPath(context);
    
    CGContextMoveToPoint(context, verticalMarginInset, 0.0);
    CGContextAddLineToPoint(context, verticalMarginInset, CGRectGetHeight(self.bounds));
    
    CGContextSetStrokeColorWithColor(context, verticalMarginColor.CGColor);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
}

- (void)drawTypesettedLinesInContext:(CGContextRef)context {
    NSRange lineRange = [self typesettedLineRangeForDrawing];
    
    if (lineRange.location == NSNotFound) {
        return;
    }
    
    // Typesetted lines expect y axis to grow upwards when drawing
    CGContextSaveGState(context);
    CGContextScaleCTM(context, 1.0, -1.0);
    // Set up transform to be the virtual text space
    CGContextTranslateCTM(context, margins.left, [self verticalOffset]);
    
    NSUInteger lastLineIndex = lineRange.location + lineRange.length;
    CGFloat baselineOffset = -[self verticalOffsetForLineAtIndex:lineRange.location];
    
    for (NSUInteger lineIndex = lineRange.location; lineIndex < lastLineIndex; ++lineIndex) {
        CGContextSetTextPosition(context, 0.0, baselineOffset);
        NKTLine *line = [typesettedLines objectAtIndex:lineIndex];
        [line drawInContext:context];
        baselineOffset -= lineHeight;
    }
    
    CGContextRestoreGState(context);
}

- (NSRange)typesettedLineRangeForDrawing {
    // Text sections with negative indices don't have any typesetted lines
    if (index < 0) {
        return NSMakeRange(NSNotFound, 0);
    }
    
    CGFloat sectionOffset = [self verticalOffset];
    // Note that lines draw from the upper-left corner
    NSInteger firstLineIndex = (NSInteger)floorf(sectionOffset - margins.top) / lineHeight;
    firstLineIndex -= numberOfSkirtLines;
    firstLineIndex = MAX(firstLineIndex, 0);
    
    if (firstLineIndex > [typesettedLines count] - 1) {
        return NSMakeRange(NSNotFound, 0);
    }
    
    CGFloat firstLineOffset = [self verticalOffsetForLineAtIndex:firstLineIndex];
    CGFloat nextSectionOffset = sectionOffset + CGRectGetHeight(self.bounds);
    NSUInteger numberOfLines = (NSUInteger)ceilf((nextSectionOffset - firstLineOffset) / lineHeight);
    // Account for skirt lines before and after section
    numberOfLines += (2 * numberOfSkirtLines);
    numberOfLines = MIN(numberOfLines, [typesettedLines count] - firstLineIndex);
    return NSMakeRange(firstLineIndex, numberOfLines);
}

@end
