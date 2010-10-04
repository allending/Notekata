//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTTextSection.h"
#import "NKTLine.h"
#import "NKTFramesetter.h"

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
@synthesize framesetter = framesetter_;
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
    [framesetter_ release];
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
    KBCLogDebug(@"%@ rect:%@", self, NSStringFromCGRect(rect));
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self drawHorizontalRulesInContext:context];
    [self drawVerticalMarginInContext:context];
    [self drawTypesettedLinesInContext:context];
}

// TODO: this should not assume where the first baseline is. Instead it should get it from the
// framesetter.
//
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
    
    // Apply inverse transform to bring CTM back into framesetter space
    CGContextTranslateCTM(context, 0.0, -[self verticalOffset]);
    // Framesetter requires an inverted space
    CGContextScaleCTM(context, 1.0, -1.0);
    // Take margins into account
    CGContextTranslateCTM(context, margins_.left, -margins_.top);
    [self.framesetter drawLinesInRange:lineRange inContext:context];
}

// Computes the range for lines that should be drawn in this text section based on the current
// bounds of the text section.
//
// TODO: clean this up
//
- (NSRange)typesettedLineRangeForDrawing
{
    // Text sections with negative indices don't have any typesetted lines
    if (index < 0)
    {
        return NSMakeRange(NSNotFound, 0);
    }
    
    // Note that lines draw from the upper-left corner
    
    CGFloat sectionOffset = [self verticalOffset];
    // Find the first line index that could be visible in this section's bounds
    NSInteger firstLineIndex = (NSInteger)floorf(sectionOffset - margins_.top) / lineHeight_;
    firstLineIndex -= numberOfSkirtLines_;
    firstLineIndex = MAX(firstLineIndex, 0);
    
    if (firstLineIndex > (framesetter_.numberOfLines - 1))
    {
        return NSMakeRange(NSNotFound, 0);
    }
    
    CGFloat firstLineOffset = [self verticalOffsetForLineAtIndex:firstLineIndex];
    CGFloat nextSectionOffset = sectionOffset + CGRectGetHeight(self.bounds);
    // Find the number of lines that could be visible in this section's bounds
    NSUInteger numberOfLines = (NSUInteger)ceilf((nextSectionOffset - firstLineOffset) / lineHeight_);
    // Account for skirt lines before and after section
    numberOfLines += (2 * numberOfSkirtLines_);
    numberOfLines = MIN(numberOfLines, framesetter_.numberOfLines - firstLineIndex);
    return NSMakeRange(firstLineIndex, numberOfLines);
}

//--------------------------------------------------------------------------------------------------

#pragma mark Debugging

- (NSString *)description
{
    return [NSString stringWithFormat:@"text section %d frame:%@", index_, NSStringFromCGRect(self.frame)];
}

@end
