//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "NSString+KobaCoreAdditions.h"

@implementation NSString(KobaCoreAdditions)

#pragma mark -
#pragma mark Getting Newline Information

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
