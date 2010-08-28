//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTTextRange.h"
#import "NKTTextPosition.h"

@implementation NKTTextRange

@synthesize nsRange;

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (id)initWithNSRange:(NSRange)aNSRange
{
    if ((self = [super init]))
    {
        if (aNSRange.location == NSNotFound)
        {
            [self release];
            return nil;
        }
        
        nsRange = aNSRange;
    }
    
    return self;
}

+ (id)textRangeWithNSRange:(NSRange)nsRange
{
    return [[[self alloc] initWithNSRange:nsRange] autorelease];
}

+ (id)textRangeWithTextPosition:(NKTTextPosition *)textPosition textPosition:(NKTTextPosition *)otherTextPosition
{
    if (textPosition.index <= otherTextPosition.index)
    {
        return [self textRangeWithNSRange:NSMakeRange(textPosition.index, otherTextPosition.index - textPosition.index)];
    }
    else
    {
        return [self textRangeWithNSRange:NSMakeRange(otherTextPosition.index, textPosition.index - otherTextPosition.index)];
    }
}

//--------------------------------------------------------------------------------------------------

#pragma mark Copying

- (id)copyWithZone:(NSZone *)zone
{
    return [[NKTTextRange allocWithZone:zone] initWithNSRange:nsRange];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Defining Ranges of Text

- (UITextPosition *)start
{
    return [NKTTextPosition textPositionWithIndex:self.startIndex];
}

- (UITextPosition *)end
{
    return [NKTTextPosition textPositionWithIndex:self.endIndex];
}

- (BOOL)isEmpty
{
    return nsRange.length == 0;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Accessing Range Indices

- (NSUInteger)startIndex
{
    return nsRange.location;
}

- (NSUInteger)endIndex
{
    return nsRange.location + nsRange.length;
}

- (NSUInteger)length
{
    return nsRange.length;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Checking Text Positions

- (BOOL)containsTextPosition:(NKTTextPosition *)textPosition
{
    return textPosition.index >= self.startIndex && textPosition.index < self.endIndex;
}

@end
