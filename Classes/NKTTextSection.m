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
- (NSRange)horizontalRuleRange;
- (NSRange)textLineRange;

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
    
    // TODO: should return first horizontal rule visible in this section
    NSRange ruleRange = [self horizontalRuleRange];
    CGFloat ruleY = self.margins.top + self.horizontalRuleOffset + ((ruleRange.location + 1) * self.lineHeight);
    ruleY = fmod(ruleY, CGRectGetHeight(self.bounds));
    
    while (ruleY < CGRectGetHeight(self.bounds)) {
        CGContextMoveToPoint(context, 0.0, ruleY);
        CGContextAddLineToPoint(context, CGRectGetWidth(self.bounds), ruleY);
        ruleY += lineHeight;
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
    CGContextSaveGState(context);
    // Set up coordinate system with origin at the top-left with y upwards
    CGContextScaleCTM(context, 1.0, -1.0);
    // Move into the virtual text space
    CGFloat sectionVirtualMinY = self.index * CGRectGetHeight(self.bounds);
    CGContextTranslateCTM(context, 0.0, sectionVirtualMinY);
    
    NSRange lineRange = [self textLineRange];
    
    if (lineRange.location == NSNotFound || lineRange.length == 0) {
        return;
    }
    
    NSUInteger lastLineIndex = lineRange.location + lineRange.length;
    CGFloat baseline = -self.margins.top - ((lineRange.location + 1) * self.lineHeight);
    
    for (NSUInteger lineIndex = lineRange.location; lineIndex < lastLineIndex; ++lineIndex) {
        NKTLine *line = [typesettedLines objectAtIndex:lineIndex];
        CGContextSetTextPosition(context, margins.left, baseline);
        baseline -= lineHeight;
        [line drawInContext:context];
    }
    
    CGContextRestoreGState(context);
}

- (NSRange)horizontalRuleRange {
    CGFloat sectionMinY = self.index * CGRectGetHeight(self.bounds);
    NSInteger firstRuleIndex = floorf(sectionMinY - self.margins.top - self.horizontalRuleOffset) / self.lineHeight;
    firstRuleIndex = MAX(firstRuleIndex, 0);
    CGFloat firstRuleY = ((CGFloat)firstRuleIndex * self.lineHeight) + self.margins.top + self.horizontalRuleOffset;
    CGFloat nextSectionMinY = sectionMinY + CGRectGetHeight(self.bounds);
    NSUInteger ruleCount = ceilf((nextSectionMinY - firstRuleY) / self.lineHeight);
    return NSMakeRange(firstRuleIndex, ruleCount);
}

- (NSRange)textLineRange {
    CGFloat sectionVirtualMinY = self.index * CGRectGetHeight(self.bounds);
    NSInteger firstLineIndex = floorf(sectionVirtualMinY - self.margins.top) / self.lineHeight;
    firstLineIndex = MAX(firstLineIndex - (NSInteger)numberOfSkirtLines, 0);
    
    if (firstLineIndex > [typesettedLines count] - 1) {
        return NSMakeRange(NSNotFound, 0);
    }
    
    CGFloat firstLineMinY = ((CGFloat)firstLineIndex * self.lineHeight) + self.margins.top;
    CGFloat nextSectionVirtualMinY = sectionVirtualMinY + CGRectGetHeight(self.bounds);
    NSUInteger lineCount = ceilf((nextSectionVirtualMinY - firstLineMinY) / self.lineHeight);
    lineCount = MIN(lineCount + numberOfSkirtLines, [typesettedLines count] - firstLineIndex);
    return NSMakeRange(firstLineIndex, lineCount);
}

@end
