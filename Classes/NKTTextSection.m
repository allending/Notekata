//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTTextSection.h"
#import "NKTLine.h"

@interface NKTTextSection()

#pragma mark -
#pragma mark Drawing

- (NSRange)rangeOfTypesettedLinesForDrawing;

@end

@implementation NKTTextSection

@synthesize index;
@synthesize typesettedLines;
@synthesize lineHeight;
@synthesize margins;
@synthesize skirtLineCount;

#pragma mark -
#pragma mark Initializing

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor clearColor];
        skirtLineCount = 1;
    }
    
    return self;
}

- (void)dealloc {
    [typesettedLines release];
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
    
    NSRange lineRange = [self rangeOfTypesettedLinesForDrawing];
    
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

- (NSRange)rangeOfTypesettedLinesForDrawing {
    CGFloat sectionVirtualMinY = self.index * CGRectGetHeight(self.bounds);
    NSInteger firstLineIndex = floorf(sectionVirtualMinY - self.margins.top) / self.lineHeight;
    firstLineIndex = MAX(firstLineIndex - (NSInteger)skirtLineCount, 0);
    
    if (firstLineIndex > [typesettedLines count] - 1) {
        return NSMakeRange(NSNotFound, 0);
    }
    
    CGFloat firstLineMinY = ((CGFloat)firstLineIndex * self.lineHeight) + self.margins.top;
    CGFloat nextSectionVirtualMinY = sectionVirtualMinY + CGRectGetHeight(self.bounds);
    NSUInteger lineCount = ceilf((nextSectionVirtualMinY - firstLineMinY) / self.lineHeight);
    lineCount = MIN(lineCount + skirtLineCount, [typesettedLines count] - firstLineIndex);
    return NSMakeRange(firstLineIndex, lineCount);
}

@end
