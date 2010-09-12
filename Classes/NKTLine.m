//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTLine.h"
#import "NKTTextPosition.h"
#import "NKTTextRange.h"

@implementation NKTLine

@synthesize index = index_;

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (id)initWithIndex:(NSUInteger)index text:(NSAttributedString *)text CTLine:(CTLineRef)ctLine
{
    if ((self = [super init]))
    {
        if (text == nil || ctLine == NULL)
        {
            NSLog(@"%s: invalid initialization arguments", __PRETTY_FUNCTION__);
            [self release];
            return nil;
        }
        
        index_ = index;
        text_ = [text retain];
        ctLine_ = CFRetain(ctLine);
    }
    
    return self;
}

- (void)dealloc
{
    [text_ release];
    CFRelease(ctLine_);
    [super dealloc];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Text Ranges

- (NKTTextRange *)textRange
{
    CFRange range = CTLineGetStringRange(ctLine_);
    return [NKTTextRange textRangeWithIndex:range.location length:range.length];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Typographic Bounds

- (CGFloat)ascent
{
    CGFloat ascent;
    CTLineGetTypographicBounds(ctLine_, &ascent, NULL, NULL);
    return ascent;
}

- (CGFloat)descent
{
    CGFloat descent;
    CTLineGetTypographicBounds(ctLine_, NULL, &descent, NULL);
    return descent;
}

- (CGFloat)leading
{
    CGFloat leading;
    CTLineGetTypographicBounds(ctLine_, NULL, NULL, &leading);
    return leading;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Offsets

- (CGFloat)offsetForCharAtTextPosition:(NKTTextPosition *)textPosition
{
    CGFloat offset = CTLineGetOffsetForStringIndex(ctLine_, (CFIndex)textPosition.index, NULL);
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
    
    NSUInteger charIndex = (NSUInteger)CTLineGetStringIndexForPosition(ctLine_, point);
    
    // Adjust the character index if it is beyond the text range of the line
    if (charIndex == textRange.end.index)
    {
        // Decrement unless the index is the last character and is not a line break
        if (charIndex != [text_ length] || [[text_ string] hasSuffix:@"\n"])
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
    CTLineDraw(ctLine_, context);
}

@end
