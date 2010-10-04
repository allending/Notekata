//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTTextPosition.h"
#import "NKTTextRange.h"

@implementation NKTTextPosition

@synthesize location = location_;

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (id)initWithLocation:(NSUInteger)location
{
    if ((self = [super init]))
    {
        if (location == NSNotFound)
        {
            KBCLogWarning(@"location is NSNotFound, returning nil");
            [self release];
            return nil;
        }
        
        location_ = location;
    }
    
    return self;
}

+ (id)textPositionWithLocation:(NSUInteger)location
{
    return [[[self alloc] initWithLocation:location] autorelease];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Creating Text Positions

- (NKTTextPosition *)previousTextPosition
{
    if (location_ == 0)
    {
        return nil;
    }
    
    return [[self class] textPositionWithLocation:(location_ - 1)];
}

- (NKTTextPosition *)nextTextPosition
{
    return [[self class] textPositionWithLocation:(location_ + 1)];
}

- (NKTTextPosition *)textPositionByApplyingOffset:(NSInteger)offset
{
    NSInteger newLocation = (NSInteger)location_ + offset;
    
    if (newLocation < 0)
    {
        KBCLogWarning(@"applying offset %d to location %d creates invalid location %d, returning nil",
                      offset,
                      location_,
                      newLocation);
        return nil;
    }
    
    return [[self class] textPositionWithLocation:(NSUInteger)newLocation];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Creating Text Ranges

- (NKTTextRange *)textRange
{
    return [NKTTextRange textRangeWithRange:NSMakeRange(location_, 0)];
}

- (NKTTextRange *)textRangeWithTextPosition:(NKTTextPosition *)textPosition
{
    if (location_ < textPosition.location)
    {
        return [NKTTextRange textRangeWithRange:NSMakeRange(location_, textPosition.location - location_)];
    }
    else
    {
        return [NKTTextRange textRangeWithRange:NSMakeRange(textPosition.location,
                                                              location_ - textPosition.location)];
    }
}

//--------------------------------------------------------------------------------------------------

#pragma mark Comparing Text Posiitons

- (BOOL)isEqualToTextPosition:(NKTTextPosition *)textPosition
{
    if (textPosition == nil)
    {
        return NO;
    }
    
    return location_ == textPosition.location;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Debugging

- (NSString *)description
{
    return [NSString stringWithFormat:@"%d", location_];
}

@end
