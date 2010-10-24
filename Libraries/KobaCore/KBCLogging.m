//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KBCLogging.h"
#import <CoreData/CoreData.h>

NSString *KBCDetailedCoreDataErrorStringFromError(NSError *error)
{
    NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
    
    if(detailedErrors != nil && [detailedErrors count] > 0)
    {
        NSMutableString *detailedErrorString = [NSMutableString string];
        
        for (NSError* detailedError in detailedErrors)
        {
            [detailedErrorString appendFormat:@"  DetailedError: %@\n", [detailedError userInfo]];
        }
        
        return detailedErrorString;
    }
    else
    {
        return [NSString stringWithFormat:@"%@", [error userInfo]];
    }
}

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
