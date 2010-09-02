//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTTextRange.h"
#import "NKTTextPosition.h"

@implementation NKTTextRange

@synthesize length;

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (id)initWithTextPosition:(NKTTextPosition *)textPosition length:(NSUInteger)theLength
{
    if ((self = [super init]))
    {
        start = [textPosition retain];
        length = theLength;
    }
    
    return self;
}

- (id)initWithIndex:(NSUInteger)index length:(NSUInteger)theLength
{
    return [self initWithTextPosition:[NKTTextPosition textPositionWithIndex:index] length:theLength];
}

+ (id)textRangeWithTextPosition:(NKTTextPosition *)textPosition length:(NSUInteger)length
{
    return [[[self alloc] initWithTextPosition:textPosition length:length] autorelease];
}

+ (id)textRangeWithIndex:(NSUInteger)index length:(NSUInteger)length
{
    return [[[self alloc] initWithIndex:index length:length] autorelease];
}

- (void)dealloc
{
    [start release];
    [super dealloc];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Copying

- (id)copyWithZone:(NSZone *)zone
{
    return [self retain];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Defining Ranges of Text

- (NKTTextPosition *)start
{
    return start;
}

- (NKTTextPosition *)end
{
    return [NKTTextPosition textPositionWithIndex:start.index + length];
}

- (BOOL)isEmpty
{
    return length == 0;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting NSRanges

- (NSRange)nsRange
{
    return NSMakeRange(start.index, length);
}

//--------------------------------------------------------------------------------------------------

#pragma mark Checking Text Positions

- (BOOL)containsTextPosition:(NKTTextPosition *)textPosition
{
    return textPosition.index >= start.index && textPosition.index < start.index + length;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Creating Text Ranges

- (NKTTextRange *)textRangeByGrowingLeft
{
    if (start.index > 0)
    {
        return [[self class] textRangeWithIndex:(start.index - 1) length:length + 1];
    }
    else
    {
        return [[self retain] autorelease];
    }
}

- (NKTTextRange *)textRangeByReplacingLengthWithLength:(NSUInteger)theLength
{
    return [[self class] textRangeWithIndex:start.index length:theLength];
}

- (NKTTextRange *)textRangeByReplacingStartIndexWithIndex:(NSUInteger)theIndex
{
    return [[self class] textRangeWithIndex:theIndex length:length];
}

@end
