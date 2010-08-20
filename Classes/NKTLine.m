//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTLine.h"
#import "NKTTextRange.h"
#import "NKTTextPosition.h"

@implementation NKTLine

@synthesize ctLine;

#pragma mark -
#pragma mark Initializing

- (id)initWithCTLine:(CTLineRef)theCTLine {
    if ((self = [super init])) {
        if (theCTLine == NULL) {
            [self release];
            return nil;
        }
        
        ctLine = CFRetain(theCTLine);
    }
    
    return self;
}

- (void)dealloc {
    CFRelease(ctLine);
    [super dealloc];
}

#pragma mark -
#pragma mark Accessing the Text Range

- (NKTTextRange *)textRange {
    CFRange cfRange = CTLineGetStringRange(self.ctLine);
    return [NKTTextRange textRangeWithNSRange:NSMakeRange(cfRange.location, cfRange.length)];
}

#pragma mark -
#pragma mark Getting Typographic Bounds

- (CGFloat)ascent {
    CGFloat ascent;
    CTLineGetTypographicBounds(self.ctLine, &ascent, NULL, NULL);
    return ascent;
}

- (CGFloat)descent {
    CGFloat descent;
    CTLineGetTypographicBounds(self.ctLine, NULL, &descent, NULL);
    return descent;
}

- (CGFloat)leading {
    CGFloat leading;
    CTLineGetTypographicBounds(self.ctLine, NULL, NULL, &leading);
    return leading;
}

#pragma mark -
#pragma mark Getting Line Positioning

- (CGFloat)offsetForTextAtIndex:(NSUInteger)index {
    return CTLineGetOffsetForStringIndex(self.ctLine, index, NULL);
}

- (NKTTextPosition *)closestTextPositionToPoint:(CGPoint)point {
    NSUInteger index = (NSUInteger)CTLineGetStringIndexForPosition(self.ctLine, point);
    // Clamp index to positions on the line
    index = MIN(index, self.textRange.endIndex - 1);
    return [NKTTextPosition textPositionWithIndex:index];
}

#pragma mark -
#pragma mark Drawing

- (void)drawInContext:(CGContextRef)context {
    CTLineDraw(self.ctLine, context);
}

@end
