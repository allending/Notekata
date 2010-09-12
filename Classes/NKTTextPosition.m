//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTTextPosition.h"
#import "NKTTextRange.h"

@implementation NKTTextPosition

@synthesize index = index_;

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (id)initWithIndex:(NSUInteger)index
{
    if ((self = [super init]))
    {
        if (index == NSNotFound)
        {
            KBCLogWarning(@"index is NSNotFound, returning nil");
            [self release];
            return nil;
        }
        
        index_ = index;
    }
    
    return self;
}

+ (id)textPositionWithIndex:(NSUInteger)index
{
    return [[[self alloc] initWithIndex:index] autorelease];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Creating Text Positions

- (NKTTextPosition *)previousTextPosition
{
    if (index_ == 0)
    {
        return nil;
    }
    
    return [[self class] textPositionWithIndex:(index_ - 1)];
}

- (NKTTextPosition *)nextTextPosition
{
    return [[self class] textPositionWithIndex:(index_ + 1)];
}

- (NKTTextPosition *)textPositionByApplyingOffset:(NSInteger)offset
{
    NSInteger newIndex = (NSInteger)index_ + offset;
    
    if (newIndex < 0)
    {
        return nil;
    }
    
    return [[self class] textPositionWithIndex:newIndex];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Creating Text Ranges

- (NKTTextRange *)textRange
{
    return [NKTTextRange textRangeWithTextPosition:self length:0];
}

- (NKTTextRange *)textRangeUntilTextPosition:(NKTTextPosition *)textPosition
{
    if (index_ < textPosition.index)
    {
        return [NKTTextRange textRangeWithTextPosition:self length:(textPosition.index - index_)];
    }
    else
    {
        return [NKTTextRange textRangeWithTextPosition:textPosition length:(index_ - textPosition.index)];
    }
}

@end
