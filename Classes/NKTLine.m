//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTLine.h"
#import "NKTTextPosition.h"
#import "NKTTextRange.h"

@implementation NKTLine

@synthesize index = index_;
@synthesize origin = origin_;

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (id)initWithIndex:(NSUInteger)index text:(NSAttributedString *)text ctLine:(CTLineRef)ctLine origin:(CGPoint)origin
{
    if ((self = [super init]))
    {
        index_ = index;
        text = text;
        
        if (ctLine)
        {
            ctLine_ = (CTLineRef)CFRetain(ctLine);
        }
        
        origin_ = origin;
    }
    
    return self;
}

- (void)dealloc
{
    if (ctLine_)
    {
        CFRelease(ctLine_);
    }
    
    [super dealloc];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Accessing the Text

- (NSString *)lineText
{
    return [[text_ string] substringWithRange:self.textRange.nsRange];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Text Ranges

- (NKTTextRange *)textRange
{
    CFRange range = CTLineGetStringRange(ctLine_);
    return [NKTTextRange textRangeWithNSRange:NSMakeRange(range.location, range.length)];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Line Geometry

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
    CGFloat offset = CTLineGetOffsetForStringIndex(ctLine_, (CFIndex)textPosition.location, NULL);
    return offset;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Hit Testing

- (NKTTextPosition *)closestTextPositionToPoint:(CGPoint)point
{
    NKTTextRange *textRange = self.textRange;
    
    if (textRange.empty)
    {
        return textRange.start;
    }
    
    NSUInteger charIndex = (NSUInteger)CTLineGetStringIndexForPosition(ctLine_, point);    
    return [NKTTextPosition textPositionWithLocation:charIndex];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Drawing

- (void)drawInContext:(CGContextRef)context
{
    CTLineDraw(ctLine_, context);
}

@end
