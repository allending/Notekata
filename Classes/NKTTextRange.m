//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTTextRange.h"
#import "NKTTextPosition.h"

@implementation NKTTextRange

@synthesize nsRange = nsRange_;

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (id)initWithNSRange:(NSRange)nsRange
{
    if ((self = [super init]))
    {
        nsRange_ = nsRange;
    }
    
    return self;
}

+ (id)textRangeWithNSRange:(NSRange)nsRange
{
    return [[[self alloc] initWithNSRange:nsRange] autorelease];
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
    return nsRange_.location;
}

- (NSUInteger)length
{
    return nsRange_.length;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Defining Ranges of Text

- (NKTTextPosition *)start
{
    return [NKTTextPosition textPositionWithLocation:nsRange_.location];
}

- (NKTTextPosition *)end
{
    return [NKTTextPosition textPositionWithLocation:NSMaxRange(nsRange_)];
}

- (BOOL)isEmpty
{
    return nsRange_.length == 0;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Checking for Text Position Containment

- (BOOL)containsTextPosition:(NKTTextPosition *)textPosition
{
    return NSLocationInRange(textPosition.location, nsRange_);
}

//--------------------------------------------------------------------------------------------------

#pragma mark Creating Text Ranges

- (NKTTextRange *)textRangeByGrowingLeft
{
    NSRange range = nsRange_;
    
    if (range.location > 0)
    {
        --range.location;
        ++range.length;
    }
    
    return [[self class] textRangeWithNSRange:range];
}

- (NKTTextRange *)textRangeByGrowingRight
{
    NSRange range = NSMakeRange(nsRange_.location, nsRange_.length + 1);
    return [[self class] textRangeWithNSRange:range];
}

- (NKTTextRange *)textRangeByChangingLocation:(NSUInteger)location
{
    NSRange range = NSMakeRange(location, nsRange_.length);
    return [[self class] textRangeWithNSRange:range];
}

- (NKTTextRange *)textRangeByChangingLength:(NSUInteger)length
{
    NSRange range = NSMakeRange(nsRange_.location, length);
    return [[self class] textRangeWithNSRange:range];
}

- (NKTTextRange *)textRangeByClippingUntilTextPosition:(NKTTextPosition *)textPosition
{
    if (self.empty && ![self isEqualToTextPosition:textPosition])
    {
        KBCLogWarning(@"range %@ is empty and is not equal to text position %@, returning nil", self, textPosition);
        return nil;
    }
    
    if (!NSLocationInRange(textPosition.location, nsRange_))
    {
        KBCLogWarning(@"text position %d is not located in non-empty range %@", textPosition, self);
    }
    
    NSRange nsRange = NSMakeRange(nsRange_.location, textPosition.location - nsRange_.location);
    return [NKTTextRange textRangeWithNSRange:nsRange];
}

- (NKTTextRange *)textRangeByClippingFromTextPosition:(NKTTextPosition *)textPosition
{
    if (self.empty && ![self isEqualToTextPosition:textPosition])
    {
        KBCLogWarning(@"range %@ is empty and is not equal to text position %@, returning nil", self, textPosition);
        return nil;
    }
    
    if (!NSLocationInRange(textPosition.location, nsRange_))
    {
        KBCLogWarning(@"text position %d is not located in non-empty range %@", textPosition, self);
    }
    
    NSRange nsRange = NSMakeRange(textPosition.location, NSMaxRange(nsRange_) -  textPosition.location);
    return [NKTTextRange textRangeWithNSRange:nsRange];
}

//--------------------------------------------------------------------------------------------------

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
    if (textRange == nil)
    {
        return NO;
    }
    
    return NSEqualRanges(nsRange_, textRange.nsRange);
}

- (BOOL)isEqualToTextPosition:(NKTTextPosition *)textPosition
{
    if (textPosition == nil)
    {
        return NO;
    }
    
    return self.empty && nsRange_.location == textPosition.location;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Describing

- (NSString *)description
{
    return NSStringFromRange(nsRange_);
}

@end
