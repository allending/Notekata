//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTTextSection.h"
#import "NKTLine.h"

@interface NKTTextSection()

#pragma mark -
#pragma mark Drawing

- (void)drawHorizontalRulesInContext:(CGContextRef)context;
- (void)drawVerticalMarginInContext:(CGContextRef)context;
- (void)drawTypesettedLinesInContext:(CGContextRef)context;
- (NSRange)typesettedLineRangeForDrawing;

@end

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
#pragma mark Drawing

- (void)drawRect:(CGRect)rect {    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self drawHorizontalRulesInContext:context];
    [self drawVerticalMarginInContext:context];
    [self drawTypesettedLinesInContext:context];
}

- (void)drawHorizontalRulesInContext:(CGContextRef)context {
    if (self.index < 0 || !self.horizontalRulesEnabled || self.horizontalRuleColor == nil) {
        return;
    }
    
    CGContextSaveGState(context);
    CGContextSetShouldAntialias(context, NO);
    CGContextSetLineWidth(context, 1.0);

    CGContextBeginPath(context);
    // Figure out where the horizontal rules in the section start
    CGFloat topRuleVirtualY = self.margins.top + self.lineHeight + self.horizontalRuleOffset;
    CGFloat sectionVirtualMinY = (CGFloat)self.index * CGRectGetHeight(self.bounds);
    NSInteger firstVisibleRuleIndex = (NSInteger)ceil((sectionVirtualMinY - topRuleVirtualY) / self.lineHeight);
    firstVisibleRuleIndex = MAX(firstVisibleRuleIndex, 0);
    CGFloat ruleLocalY = ((CGFloat)firstVisibleRuleIndex * self.lineHeight) + topRuleVirtualY - sectionVirtualMinY;

    // Draw the horizontal rules in local space
    while (ruleLocalY < CGRectGetHeight(self.bounds)) {
        CGContextMoveToPoint(context, 0.0, ruleLocalY);
        CGContextAddLineToPoint(context, CGRectGetWidth(self.bounds), ruleLocalY);
        ruleLocalY += self.lineHeight;
    }
    
    CGContextSetStrokeColorWithColor(context, self.horizontalRuleColor.CGColor);
    CGContextStrokePath(context);
    
    CGContextRestoreGState(context);
}

- (void)drawVerticalMarginInContext:(CGContextRef)context {
    if (!self.verticalMarginEnabled || self.verticalMarginColor == nil) {
        return;
    }
    
    CGContextSaveGState(context);
    CGContextSetShouldAntialias(context, NO);
    CGContextSetLineWidth(context, 1.0);
    
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, self.verticalMarginInset, 0.0);
    CGContextAddLineToPoint(context, self.verticalMarginInset, CGRectGetHeight(self.bounds));
    CGContextSetStrokeColorWithColor(context, self.verticalMarginColor.CGColor);
    CGContextStrokePath(context);
    
    CGContextRestoreGState(context);
}

- (void)drawTypesettedLinesInContext:(CGContextRef)context {
    NSRange lineRange = [self typesettedLineRangeForDrawing];
    
    if (lineRange.location == NSNotFound) {
        return;
    }
    
    CGContextSaveGState(context);
    // Set up transform so that text draws correctly
    CGContextScaleCTM(context, 1.0, -1.0);
    // Move into the virtual text space
    CGFloat minY = (CGFloat)self.index * CGRectGetHeight(self.bounds);
    CGContextTranslateCTM(context, 0.0, minY);
    
    NSUInteger lastLineIndex = lineRange.location + lineRange.length;
    CGFloat baseline = -self.margins.top - ((CGFloat)(lineRange.location + 1) * self.lineHeight);
    
    for (NSUInteger lineIndex = lineRange.location; lineIndex < lastLineIndex; ++lineIndex) {
        NKTLine *line = [self.typesettedLines objectAtIndex:lineIndex];
        CGContextSetTextPosition(context, self.margins.left, baseline);
        baseline -= self.lineHeight;
        [line drawInContext:context];
    }
    
    CGContextRestoreGState(context);
}

- (NSRange)typesettedLineRangeForDrawing {
    CGFloat sectionVirtualMinY = self.index * CGRectGetHeight(self.bounds);
    // Note that lines draw from the upper-left corner
    NSInteger firstLineIndex = (NSInteger)floorf(sectionVirtualMinY - self.margins.top) / self.lineHeight;
    firstLineIndex -= self.numberOfSkirtLines;
    firstLineIndex = MAX(firstLineIndex, 0);
    
    if (firstLineIndex > [self.typesettedLines count] - 1) {
        return NSMakeRange(NSNotFound, 0);
    }
    
    CGFloat firstLineVirtualY = ((CGFloat)firstLineIndex * self.lineHeight) + self.margins.top;
    CGFloat nextSectionVirtualMinY = sectionVirtualMinY + CGRectGetHeight(self.bounds);
    NSInteger numberOfLines = (NSInteger)ceilf((nextSectionVirtualMinY - firstLineVirtualY) / self.lineHeight);
    numberOfLines += 2 * self.numberOfSkirtLines;
    numberOfLines = MIN(numberOfLines, [self.typesettedLines count] - firstLineIndex);
    return NSMakeRange(firstLineIndex, numberOfLines);
}

@end
