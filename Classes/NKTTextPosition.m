//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTTextPosition.h"
#import "KobaText.h"
#import "NKTTextRange.h"

@implementation NKTTextPosition

@synthesize location = location_;
@synthesize affinity = affinity_;

#pragma mark -
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

#pragma mark -
#pragma mark Creating Text Positions

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
    
    return [[self class] textPositionWithLocation:(NSUInteger)newLocation affinity:affinity_];
}

#pragma mark -
#pragma mark Creating Text Ranges

- (NKTTextRange *)textRange
{
    return [NKTTextRange textRangeWithTextPosition:self textPosition:self];
}

#pragma mark -
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
    
    if (affinity_ == UITextStorageDirectionBackward && textPosition.affinity == UITextStorageDirectionForward)
    {
        return NSOrderedAscending;
    }
    else if (affinity_ == UITextStorageDirectionForward && textPosition.affinity == UITextStorageDirectionBackward)
    {
        return NSOrderedDescending;
    }
    else
    {
        return NSOrderedSame;
    }
}

- (NSComparisonResult)compareIgnoringAffinity:(NKTTextPosition *)textPosition
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

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[NKTTextPosition class]])
    {
        return NO;
    }
    
    return [self isEqualToTextPosition:object];
}

- (BOOL)isEqualToTextPosition:(NKTTextPosition *)textPosition
{
    if (textPosition == nil)
    {
        return NO;
    }
    
    return location_ == textPosition.location && affinity_ == textPosition.affinity;
}

- (BOOL)isEqualToTextPositionIgnoringAffinity:(NKTTextPosition *)textPosition
{
    if (textPosition == nil)
    {
        return NO;
    }
    
    return location_ == textPosition.location;
}

#pragma mark -
#pragma mark Debugging

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (%d, %@)",
                                       [self class],
                                       location_,
                                       KBTStringFromUITextDirection(affinity_)];
}

@end
