//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NSString+KobaAdditions.h"

@implementation NSString(KobaAdditions)

- (BOOL)isLastCharacterNewline
{
    if ([self length] == 0)
    {
        return NO;
    }
    
    NSCharacterSet *newlines = [NSCharacterSet newlineCharacterSet];
    return [newlines characterIsMember:[self characterAtIndex:[self length] - 1]];
}

@end
