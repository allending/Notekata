//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTLine.h"
#import "NKTTextPosition.h"
#import "NKTTextRange.h"

@implementation NKTLine

@synthesize ctLine;

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (id)initWithText:(NSAttributedString *)theText CTLine:(CTLineRef)theCTLine
{
    if ((self = [super init]))
    {
        if (theText == nil || theCTLine == NULL)
        {
            NSLog(@"%s: nil input arguments, releasing and returning nil", __PRETTY_FUNCTION__);
            [self release];
            return nil;
        }
        
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

#pragma mark Accessing the Text Range

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
        return (NKTTextPosition *)[textRange start];
    }
    
    NSUInteger index = (NSUInteger)CTLineGetStringIndexForPosition(ctLine, point);
    
    if (index > textRange.startIndex && [[text string] characterAtIndex:(index - 1)] == '\n')
    {
        --index;
    }
    
    return [NKTTextPosition textPositionWithIndex:index];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Drawing

- (void)drawInContext:(CGContextRef)context
{
    CTLineDraw(ctLine, context);
}

@end
