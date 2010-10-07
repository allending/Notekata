//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTTextRange.h"
#import "KobaText.h"
#import "NKTTextPosition.h"

@implementation NKTTextRange

@synthesize range = range_;
@synthesize affinity = affinity_;

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (id)initWithRange:(NSRange)range
{
    return [self initWithRange:range affinity:UITextStorageDirectionForward];
}

- (id)initWithRange:(NSRange)range affinity:(UITextStorageDirection)affinity
{
    if ((self = [super init]))
    {
        if (range.location == NSNotFound)
        {
            KBCLogWarning(@"location is NSNotFound, returning nil");
            [self release];
            return nil;
        }
        
        range_ = range;
        affinity_ = affinity;
    }
    
    return self;
}

+ (id)textRangeWithRange:(NSRange)range
{
    return [[[self alloc] initWithRange:range] autorelease];
}

+ (id)textRangeWithRange:(NSRange)range affinity:(UITextStorageDirection)affinity
{
    return [[[self alloc] initWithRange:range affinity:affinity] autorelease];
}

+ (NKTTextRange *)textRangeWithTextPosition:(NKTTextPosition *)firstTextPosition
                               textPosition:(NKTTextPosition *)secondTextPosition
{
    if (firstTextPosition.location < secondTextPosition.location)
    {
        NSRange range = NSMakeRange(firstTextPosition.location,
                                    secondTextPosition.location - firstTextPosition.location);
        return [NKTTextRange textRangeWithRange:range affinity:firstTextPosition.affinity];
    }
    else
    {
        NSRange range = NSMakeRange(secondTextPosition.location,
                                    firstTextPosition.location - secondTextPosition.location);
        return [NKTTextRange textRangeWithRange:range affinity:secondTextPosition.affinity];
    }
}

- (void)dealloc
{
    [super dealloc];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Copying

- (id)copyWithZone:(NSZone *)zone
{
    return [self retain];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Accessing the Range

- (NSUInteger)location
{
    return range_.location;
}

- (NSUInteger)length
{
    return range_.length;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Defining Ranges of Text

- (NKTTextPosition *)start
{
    return [NKTTextPosition textPositionWithLocation:range_.location affinity:affinity_];
}

- (NKTTextPosition *)end
{
    return [NKTTextPosition textPositionWithLocation:NSMaxRange(range_) affinity:affinity_];
}

- (BOOL)isEmpty
{
    return range_.length == 0;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Checking for Text Position Containment

- (BOOL)enclosesTextPosition:(NKTTextPosition *)textPosition
{
    if (textPosition.affinity == UITextStorageDirectionForward)
    {
        return NSLocationInRange(textPosition.location, range_);
    }
    else
    {
        return NSLocationInRange(textPosition.location, range_) || (textPosition.location == NSMaxRange(range_));
    }
}

//--------------------------------------------------------------------------------------------------

#pragma mark Creating Text Ranges

- (NKTTextRange *)textRangeByGrowingLeft
{
    NSRange range = range_;
    
    if (range.location > 0)
    {
        --range.location;
        ++range.length;
    }
    
    return [[self class] textRangeWithRange:range];
}

- (NKTTextRange *)textRangeByGrowingRight
{
    NSRange range = NSMakeRange(range_.location, range_.length + 1);
    return [[self class] textRangeWithRange:range];
}

- (NKTTextRange *)textRangeByChangingLocation:(NSUInteger)location
{
    NSRange range = NSMakeRange(location, range_.length);
    return [[self class] textRangeWithRange:range];
}

- (NKTTextRange *)textRangeByChangingLength:(NSUInteger)length
{
    NSRange range = NSMakeRange(range_.location, length);
    return [[self class] textRangeWithRange:range];
}

- (NKTTextRange *)textRangeByClippingUntilTextPosition:(NKTTextPosition *)textPosition
{
    if (self.empty && ![self isEqualToTextPosition:textPosition])
    {
        KBCLogWarning(@"range %@ is empty and is not equal to text position %@, returning nil", self, textPosition);
        return nil;
    }
    
    if (!NSLocationInRange(textPosition.location, range_))
    {
        KBCLogWarning(@"text position %d is not located in non-empty range %@", textPosition, self);
    }
    
    NSRange range = NSMakeRange(range_.location, textPosition.location - range_.location);
    return [NKTTextRange textRangeWithRange:range];
}

- (NKTTextRange *)textRangeByClippingFromTextPosition:(NKTTextPosition *)textPosition
{
    if (self.empty && ![self isEqualToTextPosition:textPosition])
    {
        KBCLogWarning(@"range %@ is empty and is not equal to text position %@, returning nil", self, textPosition);
        return nil;
    }
    
    if (!NSLocationInRange(textPosition.location, range_))
    {
        KBCLogWarning(@"text position %d is not located in non-empty range %@", textPosition, self);
    }
    
    NSRange range = NSMakeRange(textPosition.location, NSMaxRange(range_) -  textPosition.location);
    return [NKTTextRange textRangeWithRange:range];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Comparing Text Ranges

// TODO: take affinity into account

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
    if (textRange == nil)
    {
        return NO;
    }
    
    return NSEqualRanges(range_, textRange.range);
}

- (BOOL)isEqualToTextPosition:(NKTTextPosition *)textPosition
{
    if (textPosition == nil)
    {
        return NO;
    }
    
    return self.empty && range_.location == textPosition.location;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Debugging

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (%@, %@)",
                                       [self class],
                                       NSStringFromRange(range_),
                                       KBTStringFromUITextDirection(affinity_)];
}

@end
