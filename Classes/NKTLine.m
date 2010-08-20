//===================================================================================================
//
// Copyright 2010 Allen Ding. All rights reserved.
//
//===================================================================================================

#import "NKTLine.h"
#import "NKTTextPosition.h"
#import "NKTTextRange.h"

@implementation NKTLine

@synthesize ctLine;

#pragma mark -
#pragma mark Initializing

- (id)initWithCTLine:(CTLineRef)aCTLine {
    if ((self = [super init])) {
        if (aCTLine == NULL) {
            // TODO: log this
            [self release];
            return nil;
        }
        
        ctLine = CFRetain(aCTLine);
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
    CFRange cfRange = CTLineGetStringRange(ctLine);
    return [NKTTextRange textRangeWithNSRange:NSMakeRange((NSUInteger)cfRange.location, (NSUInteger)cfRange.length)];
}

#pragma mark -
#pragma mark Getting Typographic Bounds

- (CGFloat)ascent {
    CGFloat ascent;
    CTLineGetTypographicBounds(ctLine, &ascent, NULL, NULL);
    return ascent;
}

- (CGFloat)descent {
    CGFloat descent;
    CTLineGetTypographicBounds(ctLine, NULL, &descent, NULL);
    return descent;
}

- (CGFloat)leading {
    CGFloat leading;
    CTLineGetTypographicBounds(ctLine, NULL, NULL, &leading);
    return leading;
}

#pragma mark -
#pragma mark Getting Offsets

- (CGFloat)offsetForTextPosition:(NKTTextPosition *)textPosition {
    CGFloat offset = CTLineGetOffsetForStringIndex(ctLine, (CFIndex)textPosition.index, NULL);
    return offset;
}

#pragma mark -
#pragma mark Hit Testing

- (NKTTextPosition *)closestTextPositionToPoint:(CGPoint)point {
    NKTTextRange *textRange = self.textRange;
    
    if (textRange.empty) {
        return (NKTTextPosition *)[textRange start];
    }
    
    NSUInteger index = (NSUInteger)CTLineGetStringIndexForPosition(ctLine, point);
    // Clamp index because CTLineGetStringIndexForPosition potentially returns
    // the last string index on the line plus 1
    index = MIN(index, textRange.endIndex - 1);
    return [NKTTextPosition textPositionWithIndex:index];
}

#pragma mark -
#pragma mark Drawing

- (void)drawInContext:(CGContextRef)context {
    CTLineDraw(ctLine, context);
}

@end
