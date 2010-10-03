//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTLine.h"
#import "NKTTextPosition.h"
#import "NKTTextRange.h"

@interface NKTLine()

#pragma mark Accessing the Typeset Line

@property (nonatomic, readonly) CTLineRef line;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------

@implementation NKTLine

@synthesize index = index_;
@synthesize range = range_;
@synthesize origin = origin_;

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (id)initWithDelegate:(id <NKTLineDelegate>)delegate
                 index:(NSUInteger)index
                 range:(NSRange)range
                origin:(CGPoint)origin
{
    if ((self = [super init]))
    {
        delegate_ = delegate;
        index_ = index;
        range_ = range;
        origin_ = origin;
    }
    
    return self;
}

- (void)dealloc
{
    if (line_ != NULL)
    {
        CFRelease(line_);
    }
    
    [super dealloc];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Accessing the Typeset Line

- (CTLineRef)line
{
    if (line_ == NULL && (range_.length != 0))
    {
        CTTypesetterRef typesetter = [delegate_ typesetter];
        line_ = CTTypesetterCreateLine(typesetter, CFRangeFromNSRange(range_));
    }
    
    return line_;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Accessing the Text Range

- (NKTTextRange *)textRange
{
    return [NKTTextRange textRangeWithRange:range_];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Line Typographic Information

- (CGFloat)ascent
{
    CGFloat ascent = 0.0;
    CTLineGetTypographicBounds(self.line, &ascent, NULL, NULL);
    return ascent;
}

- (CGFloat)descent
{
    CGFloat descent = 0.0;
    CTLineGetTypographicBounds(self.line, NULL, &descent, NULL);
    return descent;
}

- (CGFloat)leading
{
    CGFloat leading = 0.0;
    CTLineGetTypographicBounds(self.line, NULL, NULL, &leading);
    return leading;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Character Offsets

- (CGFloat)offsetForTextPosition:(NKTTextPosition *)textPosition
{
    CGFloat offset = CTLineGetOffsetForStringIndex(self.line, (CFIndex)textPosition.location, NULL);
    return offset;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Hit-Testing

- (NKTTextPosition *)closestTextPositionToPoint:(CGPoint)point
{
    if (range_.length == 0)
    {
        return [NKTTextPosition textPositionWithLocation:range_.location];
    }
    
    NSUInteger charIndex = (NSUInteger)CTLineGetStringIndexForPosition(self.line, point);
    return [NKTTextPosition textPositionWithLocation:charIndex];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Drawing

- (void)drawInContext:(CGContextRef)context
{
    CTLineDraw(self.line, context);
}

@end
