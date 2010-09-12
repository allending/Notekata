//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTTextRange.h"
#import "NKTTextPosition.h"

@implementation NKTTextRange

@synthesize length = length_;

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (id)initWithTextPosition:(NKTTextPosition *)textPosition length:(NSUInteger)length
{
    if ((self = [super init]))
    {
        start_ = [textPosition retain];
        length_ = length;
    }
    
    return self;
}

- (id)initWithIndex:(NSUInteger)index length:(NSUInteger)length
{
    return [self initWithTextPosition:[NKTTextPosition textPositionWithIndex:index] length:length];
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
    [start_ release];
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
    return start_;
}

- (NKTTextPosition *)end
{
    return [NKTTextPosition textPositionWithIndex:start_.index + length_];
}

- (BOOL)isEmpty
{
    return length_ == 0;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting NSRanges

- (NSRange)nsRange
{
    return NSMakeRange(start_.index, length_);
}

//--------------------------------------------------------------------------------------------------

#pragma mark Checking Text Positions

- (BOOL)containsTextPosition:(NKTTextPosition *)textPosition
{
    return textPosition.index >= start_.index && textPosition.index < (start_.index + length_);
}

//--------------------------------------------------------------------------------------------------

#pragma mark Creating Text Ranges

- (NKTTextRange *)textRangeByGrowingLeft
{
    if (start_.index > 0)
    {
        return [[self class] textRangeWithIndex:(start_.index - 1) length:length_ + 1];
    }
    else
    {
        return [[self retain] autorelease];
    }
}

- (NKTTextRange *)textRangeByReplacingLengthWithLength:(NSUInteger)length
{
    return [[self class] textRangeWithIndex:start_.index length:length];
}

- (NKTTextRange *)textRangeByReplacingStartIndexWithIndex:(NSUInteger)index
{
    return [[self class] textRangeWithIndex:index length:length_];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Comparing Text Ranges

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[NKTTextRange class]])
    {
        return [self isEqualToTextRange:object];
    }
    
    return [super isEqual:object];
}

- (BOOL)isEqualToTextRange:(NKTTextRange *)textRange
{
    return start_.index == textRange.start.index && length_ == textRange.length;
}

@end
