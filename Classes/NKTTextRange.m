//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTTextRange.h"
#import "KobaText.h"
#import "NKTTextPosition.h"

@implementation NKTTextRange

#pragma mark -
#pragma mark Initializing

- (id)initWithTextPosition:(NKTTextPosition *)textPosition textPosition:(NKTTextPosition *)otherTextPosition
{
    if ((self = [super init]))
    {
        if ([textPosition compare:otherTextPosition] == NSOrderedAscending)
        {
            startTextPosition_ = [textPosition retain];
            endTextPosition_ = [otherTextPosition retain];
        }
        else
        {
            startTextPosition_ = [otherTextPosition retain];
            endTextPosition_ = [textPosition retain];
        }
    }
    
    return self;
}

+ (id)textRangeWithTextPosition:(NKTTextPosition *)textPosition textPosition:(NKTTextPosition *)otherTextPosition
{
    return [[[self alloc] initWithTextPosition:textPosition textPosition:otherTextPosition] autorelease];
}

- (void)dealloc
{
    [startTextPosition_ release];
    [endTextPosition_ release];
    [super dealloc];
}

#pragma mark -
#pragma mark Copying

- (id)copyWithZone:(NSZone *)zone
{
    return [self retain];
}

#pragma mark Defining Ranges of Text

- (NKTTextPosition *)start
{
    return startTextPosition_;
}

- (NKTTextPosition *)end
{
    return endTextPosition_;
}

- (BOOL)isEmpty
{
    return startTextPosition_.location == endTextPosition_.location;
}

#pragma mark -
#pragma mark Accessing the Range

- (NSRange)nsRange
{
    return NSMakeRange(startTextPosition_.location, endTextPosition_.location - startTextPosition_.location);
}

- (CFRange)cfRange
{
    return CFRangeMake(startTextPosition_.location, endTextPosition_.location - startTextPosition_.location);
}

- (NSUInteger)location
{
    return [self nsRange].location;
}

- (NSUInteger)length
{
    return [self nsRange].length;
}

#pragma mark -
#pragma mark Checking for Text Position Containment

- (BOOL)containsTextPosition:(NKTTextPosition *)textPosition
{
    return [textPosition compare:startTextPosition_] != NSOrderedAscending &&
           [textPosition compare:endTextPosition_] == NSOrderedAscending;
}

- (BOOL)containsTextPositionIgnoringAffinity:(NKTTextPosition *)textPosition
{
    return [textPosition compareIgnoringAffinity:startTextPosition_] != NSOrderedAscending &&
           [textPosition compareIgnoringAffinity:endTextPosition_] == NSOrderedAscending;
}

#pragma mark Creating Text Ranges

- (NKTTextRange *)textRangeByApplyingStartOffset:(NSUInteger)offset
{
    NKTTextPosition *newStartTextPosition = [startTextPosition_ textPositionByApplyingOffset:offset];
    return [NKTTextRange textRangeWithTextPosition:newStartTextPosition textPosition:endTextPosition_];
}

- (NKTTextRange *)textRangeByApplyingEndOffset:(NSUInteger)offset
{
    NKTTextPosition *newEndTextPosition = [endTextPosition_ textPositionByApplyingOffset:offset];
    return [NKTTextRange textRangeWithTextPosition:startTextPosition_ textPosition:newEndTextPosition];
}

#pragma mark -
#pragma mark Comparing Text Ranges

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[NKTTextRange class]])
    {
        return [self isEqualToTextRange:object];
    }
    else if ([object isKindOfClass:[NKTTextPosition class]])
    {
        return [self isEqualToTextPosition:object];
    }
    else
    {
        return [super isEqual:object];
    }
}

- (BOOL)isEqualToTextRange:(NKTTextRange *)textRange
{   
    return [startTextPosition_ isEqual:textRange.start] && [endTextPosition_ isEqual:textRange.end];
}

- (BOOL)isEqualToTextPosition:(NKTTextPosition *)textPosition
{
    return [startTextPosition_ isEqual:textPosition] && [endTextPosition_ isEqual:textPosition];
}

#pragma mark -
#pragma mark Debugging

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (%@ %@)", [self class], startTextPosition_, endTextPosition_];
}

@end
