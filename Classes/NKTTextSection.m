//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTTextSection.h"
#import "NKTLine.h"

@interface NKTTextSection()

#pragma mark -
#pragma mark Drawing

- (void)drawPageMarkingsInContext:(CGContextRef)context;
- (void)drawTextLinesInContext:(CGContextRef)context;
- (NSRange)virtualLineRange;
- (NSRange)textLineRange;

@end

@implementation NKTTextSection

@synthesize index;

@synthesize typesettedLines;

@synthesize margins;
@synthesize lineHeight;
@synthesize numberOfSkirtLines;

@synthesize horizontalLinesEnabled;
@synthesize horizontalLineColor;
@synthesize horizontalLineOffset;

#pragma mark -
#pragma mark Initializing

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        numberOfSkirtLines = 1;
    }
    
    return self;
}

- (void)dealloc {
    [typesettedLines release];
    [horizontalLineColor release];
    [super dealloc];
}

#pragma mark -
#pragma mark Drawing

- (void)drawRect:(CGRect)rect {    
    CGContextRef context = UIGraphicsGetCurrentContext();
    // Set up coordinate system with origin at the top-left with y upwards
    CGContextScaleCTM(context, 1.0, -1.0);
    
    // Move into the virtual text space
    CGFloat sectionVirtualMinY = self.index * CGRectGetHeight(self.bounds);
    CGContextTranslateCTM(context, 0.0, sectionVirtualMinY);
    
    [self drawPageMarkingsInContext:context];
    [self drawTextLinesInContext:context];
}

- (void)drawPageMarkingsInContext:(CGContextRef)context {
    CGContextSaveGState(context);
    CGContextSetShouldAntialias(context, NO);
    CGContextSetLineWidth(context, 1.0);
    
    // Draw horizontal rule lines
    if (self.horizontalLinesEnabled && self.horizontalLineColor != nil) {
        CGContextBeginPath(context);
        
        NSRange lineRange = [self virtualLineRange];
        NSUInteger lastLineIndex = lineRange.location + lineRange.length;
        CGFloat lineY = -self.margins.top - ((lineRange.location + 1) * self.lineHeight) - self.horizontalLineOffset;
        
        for (NSUInteger lineIndex = lineRange.location; lineIndex < lastLineIndex; ++lineIndex) {
            CGContextMoveToPoint(context, 0.0, lineY);
            CGContextAddLineToPoint(context, CGRectGetWidth(self.bounds), lineY);
            lineY -= lineHeight;
        }
        
        CGContextSetStrokeColorWithColor(context, self.horizontalLineColor.CGColor);
        CGContextStrokePath(context);
    }
    
    CGContextRestoreGState(context);
}

- (void)drawTextLinesInContext:(CGContextRef)context {
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
}

- (NSRange)virtualLineRange {
    CGFloat sectionVirtualMinY = self.index * CGRectGetHeight(self.bounds);
    NSInteger firstLineIndex = floorf(sectionVirtualMinY - self.margins.top) / self.lineHeight;
    firstLineIndex = MAX(firstLineIndex, 0);
    CGFloat firstLineMinY = ((CGFloat)firstLineIndex * self.lineHeight) + self.margins.top;
    CGFloat nextSectionVirtualMinY = sectionVirtualMinY + CGRectGetHeight(self.bounds);
    NSUInteger lineCount = ceilf((nextSectionVirtualMinY - firstLineMinY) / self.lineHeight);
    return NSMakeRange(firstLineIndex, lineCount);
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
