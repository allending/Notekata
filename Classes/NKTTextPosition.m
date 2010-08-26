//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTTextPosition.h"
#import "NKTTextRange.h"

@implementation NKTTextPosition

@synthesize index;

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (id)initWithIndex:(NSUInteger)anIndex
{
    if ((self = [super init]))
    {
        if (anIndex == NSNotFound)
        {
            // TODO: log this
            [self release];
            return nil;
        }
        
        index = anIndex;
    }
    
    return self;
}

+ (id)textPositionWithIndex:(NSUInteger)index
{
    return [[[self alloc] initWithIndex:index] autorelease];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Creating Text Positions

- (NKTTextPosition *)nextPosition
{
    return [[[[self class] alloc] initWithIndex:index + 1] autorelease];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Creating Text Ranges

- (NKTTextRange *)textRange
{
    return [NKTTextRange textRangeWithNSRange:NSMakeRange(index, 0)];
}

@end
