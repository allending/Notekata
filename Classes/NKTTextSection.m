//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTTextSection.h"
#import "NKTLine.h"

@interface NKTTextSection()

#pragma mark Getting Indices

- (NSUInteger)indexForFirstVisibleHorizontalRule;

#pragma mark Getting Offsets

- (CGFloat)verticalOffset;
- (CGFloat)verticalOffsetForLineAtIndex:(NSUInteger)anIndex;
- (CGFloat)verticalOffsetForHorizontalRuleAtIndex:(NSUInteger)anIndex;

#pragma mark Drawing

- (void)drawHorizontalRulesInContext:(CGContextRef)context;
- (void)drawVerticalMarginInContext:(CGContextRef)context;
- (void)drawTypesettedLinesInContext:(CGContextRef)context;
- (NSRange)typesettedLineRangeForDrawing;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------

@implementation NKTTextSection

@synthesize index = index_;

@synthesize typesettedLines = typesettedLines_;

@synthesize margins = margins_;
@synthesize lineHeight = lineHeight_;
@synthesize numberOfSkirtLines = numberOfSkirtLines_;

@synthesize horizontalRulesEnabled = horizontalRulesEnabled_;
@synthesize horizontalRuleColor = horizontalRuleColor_;
@synthesize horizontalRuleOffset = horizontalRuleOffset_;
@synthesize verticalMarginEnabled = verticalMarginEnabled_;
@synthesize verticalMarginColor = verticalMarginColor_;
@synthesize verticalMarginInset = verticalMarginInset_;

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = YES;
        self.clearsContextBeforeDrawing = NO;
        self.userInteractionEnabled = NO;
        numberOfSkirtLines_ = 1;
    }
    
    return self;
}

- (void)dealloc
{
    [typesettedLines_ release];
    [horizontalRuleColor_ release];
    [verticalMarginColor_ release];
    [super dealloc];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Indices

- (NSUInteger)indexForFirstVisibleHorizontalRule
{
    CGFloat topRuleOffset = [self verticalOffsetForHorizontalRuleAtIndex:0];
    CGFloat sectionOffset = [self verticalOffset];
    NSInteger firstVisibleRuleIndex = (NSInteger)ceil((sectionOffset - topRuleOffset) / lineHeight_);
    firstVisibleRuleIndex = MAX(firstVisibleRuleIndex, 0);
    return (NSUInteger)firstVisibleRuleIndex;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Offsets

- (CGFloat)verticalOffset
{
    return (CGFloat)index_ * CGRectGetHeight(self.bounds);
}

- (CGFloat)verticalOffsetForLineAtIndex:(NSUInteger)index
{
    return margins_.top + ((CGFloat)(index + 1) * lineHeight_);
}

- (CGFloat)verticalOffsetForHorizontalRuleAtIndex:(NSUInteger)index
{
    return [self verticalOffsetForLineAtIndex:index] + horizontalRuleOffset_;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Drawing

- (void)drawRect:(CGRect)rect
{    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self drawHorizontalRulesInContext:context];
    [self drawVerticalMarginInContext:context];
    [self drawTypesettedLinesInContext:context];
}

- (void)drawHorizontalRulesInContext:(CGContextRef)context
{
    // Horizontal rules are not drawn above the first typesetted line
    if (index_ < 0 || !horizontalRulesEnabled_ || horizontalRuleColor_ == nil)
    {
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
    
    for (CGFloat y = localOffset; y < height; y += lineHeight_)
    {
        CGContextMoveToPoint(context, 0.0, y);
        CGContextAddLineToPoint(context, width, y);
    }
    
    CGContextSetStrokeColorWithColor(context, horizontalRuleColor_.CGColor);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
}

- (void)drawVerticalMarginInContext:(CGContextRef)context
{
    if (!verticalMarginEnabled_ || verticalMarginColor_ == nil)
    {
        return;
    }
    
    CGContextSaveGState(context);
    CGContextSetShouldAntialias(context, NO);
    CGContextSetLineWidth(context, 1.0);
    CGContextBeginPath(context);
    
    CGContextMoveToPoint(context, verticalMarginInset_, 0.0);
    CGContextAddLineToPoint(context, verticalMarginInset_, CGRectGetHeight(self.bounds));
    
    CGContextSetStrokeColorWithColor(context, verticalMarginColor_.CGColor);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
}

- (void)drawTypesettedLinesInContext:(CGContextRef)context
{
    NSRange lineRange = [self typesettedLineRangeForDrawing];
    
    if (lineRange.location == NSNotFound)
    {
        return;
    }
    
    // Typesetted lines expect y axis to grow upwards when drawing
    CGContextSaveGState(context);
    CGContextScaleCTM(context, 1.0, -1.0);
    // Set up transform to be the virtual text space
    CGContextTranslateCTM(context, margins_.left, [self verticalOffset]);
    
    NSUInteger lastLineIndex = lineRange.location + lineRange.length;
    CGFloat baselineOffset = -[self verticalOffsetForLineAtIndex:lineRange.location];
    
    for (NSUInteger lineIndex = lineRange.location; lineIndex < lastLineIndex; ++lineIndex)
    {
        CGContextSetTextPosition(context, 0.0, baselineOffset);
        NKTLine *line = [typesettedLines_ objectAtIndex:lineIndex];
        [line drawInContext:context];
        baselineOffset -= lineHeight_;
    }
    
    CGContextRestoreGState(context);
}

- (NSRange)typesettedLineRangeForDrawing
{
    // Text sections with negative indices don't have any typesetted lines
    if (index < 0)
    {
        return NSMakeRange(NSNotFound, 0);
    }
    
    CGFloat sectionOffset = [self verticalOffset];
    // Note that lines draw from the upper-left corner
    NSInteger firstLineIndex = (NSInteger)floorf(sectionOffset - margins_.top) / lineHeight_;
    firstLineIndex -= numberOfSkirtLines_;
    firstLineIndex = MAX(firstLineIndex, 0);
    
    if (firstLineIndex > (NSInteger)([typesettedLines_ count] - 1))
    {
        return NSMakeRange(NSNotFound, 0);
    }
    
    CGFloat firstLineOffset = [self verticalOffsetForLineAtIndex:firstLineIndex];
    CGFloat nextSectionOffset = sectionOffset + CGRectGetHeight(self.bounds);
    NSUInteger numberOfLines = (NSUInteger)ceilf((nextSectionOffset - firstLineOffset) / lineHeight_);
    // Account for skirt lines before and after section
    numberOfLines += (2 * numberOfSkirtLines_);
    numberOfLines = MIN(numberOfLines, [typesettedLines_ count] - firstLineIndex);
    return NSMakeRange(firstLineIndex, numberOfLines);
}

@end
