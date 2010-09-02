//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KBCLogging.h"

void KBCLog(const char *functionName, NSString *format, ...)
{
    if (format != nil)
    {
        va_list argumentList;
        va_start(argumentList, format);
        NSString *newFormat = [NSString stringWithFormat:@"%s: %@", functionName, format];
        NSString *output = [[NSString alloc] initWithFormat:newFormat arguments:argumentList];
        NSLog(@"%@", output);
        [output release];
    }
    else
    {
        NSLog(@"%s", functionName);
    }
}
