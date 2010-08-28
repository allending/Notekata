//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTLine.h"
#import "NKTTextPosition.h"
#import "NKTTextRange.h"

@implementation NKTLine

@synthesize index;

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (id)initWithIndex:(NSUInteger)theIndex text:(NSAttributedString *)theText CTLine:(CTLineRef)theCTLine
{
    if ((self = [super init]))
    {
        if (theText == nil || theCTLine == NULL)
        {
            NSLog(@"%s: invalid initialization arguments", __PRETTY_FUNCTION__);
            [self release];
            return nil;
        }
        
        index = theIndex;
        text = [theText retain];
        ctLine = CFRetain(theCTLine);
    }
    
    return self;
}

- (void)dealloc
{
    [text release];
    CFRelease(ctLine);
    [super dealloc];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Text Ranges

- (NKTTextRange *)textRange
{
    CFRange cfRange = CTLineGetStringRange(ctLine);
    return [NKTTextRange textRangeWithNSRange:NSMakeRange((NSUInteger)cfRange.location, (NSUInteger)cfRange.length)];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Typographic Bounds

- (CGFloat)ascent
{
    CGFloat ascent;
    CTLineGetTypographicBounds(ctLine, &ascent, NULL, NULL);
    return ascent;
}

- (CGFloat)descent
{
    CGFloat descent;
    CTLineGetTypographicBounds(ctLine, NULL, &descent, NULL);
    return descent;
}

- (CGFloat)leading
{
    CGFloat leading;
    CTLineGetTypographicBounds(ctLine, NULL, NULL, &leading);
    return leading;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Offsets

- (CGFloat)offsetForCharAtTextPosition:(NKTTextPosition *)textPosition
{
    CGFloat offset = CTLineGetOffsetForStringIndex(ctLine, (CFIndex)textPosition.index, NULL);
    return offset;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Hit Testing

- (NKTTextPosition *)closestTextPositionToPoint:(CGPoint)point
{
    NKTTextRange *textRange = self.textRange;
    
    if (textRange.empty)
    {
        return (NKTTextPosition *)textRange.start;
    }
    
    NSUInteger charIndex = (NSUInteger)CTLineGetStringIndexForPosition(ctLine, point);
    
    if (charIndex > textRange.startIndex && [[text string] characterAtIndex:(charIndex - 1)] == '\n')
    {
        --charIndex;
    }
    
    return [NKTTextPosition textPositionWithIndex:charIndex];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Drawing

- (void)drawInContext:(CGContextRef)context
{
    CTLineDraw(ctLine, context);
}

@end
