//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTTextPosition.h"
#import "NKTTextRange.h"

@implementation NKTTextPosition

@synthesize index;

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (id)initWithIndex:(NSUInteger)theIndex
{
    if ((self = [super init]))
    {
        if (theIndex == NSNotFound)
        {
            KBCLogWarning(@"index is NSNotFound, returning nil");
            [self release];
            return nil;
        }
        
        index = theIndex;
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
    if (index == 0)
    {
        return nil;
    }
    
    return [[self class] textPositionWithIndex:index - 1];
}

- (NKTTextPosition *)nextTextPosition
{
    return [[self class] textPositionWithIndex:index + 1];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Creating Text Ranges

- (NKTTextRange *)textRange
{
    return [NKTTextRange textRangeWithTextPosition:self length:0];
}

- (NKTTextRange *)textRangeWithTextPosition:(NKTTextPosition *)textPosition
{
    if (index < textPosition.index)
    {
        return [NKTTextRange textRangeWithTextPosition:self length:textPosition.index - index];
    }
    else
    {
        return [NKTTextRange textRangeWithTextPosition:textPosition length:index - textPosition.index];
    }
}

@end
