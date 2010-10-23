//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KBCUtilities.h"

#pragma mark -
#pragma mark Working with Ranges

CFRange CFRangeFromNSRange(NSRange range)
{
    return CFRangeMake((CFIndex)range.location, (CFIndex)range.length);
}

static NSString *LocationKey = @"Location";
static NSString *LengthKey = @"Length";

NSDictionary *KBCPortableRepresentationFromRange(NSRange range)
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithUnsignedInteger:range.location], LocationKey,
            [NSNumber numberWithUnsignedInteger:range.length], LengthKey,
            nil];
}

NSRange KBCRangeFromPortableRepresentation(NSDictionary *portableRepresentation)
{
    NSUInteger location = [[portableRepresentation objectForKey:LocationKey] unsignedIntegerValue];
    NSUInteger length = [[portableRepresentation objectForKey:LengthKey] unsignedIntegerValue];
    return NSMakeRange(location, length);
}

NSString *KBCUUIDString(void)
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *uuidString = (NSString *)CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    return [uuidString autorelease];
}
