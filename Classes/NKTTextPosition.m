//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTTextPosition.h"
#import "KobaText.h"
#import "NKTTextRange.h"

@implementation NKTTextPosition

@synthesize location = location_;
@synthesize affinity = affinity_;

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (id)initWithLocation:(NSUInteger)location
{
    return [self initWithLocation:location affinity:UITextStorageDirectionForward];
}

- (id)initWithLocation:(NSUInteger)location affinity:(UITextStorageDirection)affinity
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
        affinity_ = affinity;
    }
    
    return self;
}

+ (id)textPositionWithLocation:(NSUInteger)location
{
    return [[[self alloc] initWithLocation:location] autorelease];
}

+ (id)textPositionWithLocation:(NSUInteger)location affinity:(UITextStorageDirection)affinity
{
    return [[[self alloc] initWithLocation:location affinity:affinity] autorelease];
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
    return [NKTTextRange textRangeWithRange:NSMakeRange(location_, 0) affinity:affinity_];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Comparing Text Posiitons

- (NSComparisonResult)compare:(NKTTextPosition *)textPosition
{
    if (location_ < textPosition.location)
    {
        return NSOrderedAscending;
    }
    else if (location_ > textPosition.location)
    {
        return NSOrderedDescending;
    }
    else
    {
        return NSOrderedSame;
    }
}

- (BOOL)isBeforeTextPosition:(NKTTextPosition *)textPosition
{
    return [self compare:textPosition] == NSOrderedAscending;
}

- (BOOL)isAfterTextPosition:(NKTTextPosition *)textPosition
{
    return [self compare:textPosition] == NSOrderedDescending;
}

// TODO: take affinity into account?

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[NKTTextPosition class]])
    {
        return [self isEqualToTextPosition:object];
    }
    
    return NO;
}

- (BOOL)isEqualToTextPosition:(NKTTextPosition *)textPosition
{    
    return [self compare:textPosition] == NSOrderedSame;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Debugging

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (%d, %@)",
                                       [self class],
                                       location_,
                                       KBTStringFromUITextDirection(affinity_)];
}

@end
