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
    CFRange range = CTLineGetStringRange(ctLine);
    return [NKTTextRange textRangeWithIndex:range.location length:range.length];
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

// TODO: document the specifics of what this does
- (NKTTextPosition *)closestTextPositionToPoint:(CGPoint)point
{
    NKTTextRange *textRange = self.textRange;
    
    if (textRange.empty)
    {
        return textRange.start;
    }
    
    NSUInteger charIndex = (NSUInteger)CTLineGetStringIndexForPosition(ctLine, point);
    
    // Adjust the character index if it is beyond the text range of the line
    if (charIndex == textRange.end.index)
    {
        // Decrement unless the index is the last character and is not a line break
        if (charIndex != [text length] || [[text string] hasSuffix:@"\n"])
        {
            --charIndex;
        }
    }
    
    return [NKTTextPosition textPositionWithIndex:charIndex];
}

- (NKTTextPosition *)closestTextPositionToPoint:(CGPoint)point withinRange:(NKTTextRange *)textRange
{
    NKTTextPosition *textPosition = [self closestTextPositionToPoint:point];
    
    if (textPosition.index < textRange.start.index)
    {
        return textRange.start;
    }
    else if (textPosition.index > textRange.end.index)
    {
        return textRange.end;
    }
    else
    {
        return textPosition;
    }
}

//--------------------------------------------------------------------------------------------------

#pragma mark Drawing

- (void)drawInContext:(CGContextRef)context
{
    CTLineDraw(ctLine, context);
}

@end
