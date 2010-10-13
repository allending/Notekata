//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KUIUtilities.h"

#pragma mark -
#pragma mark Getting Title Snippets

NSString *KUITrimmedSnippetFromString(NSString *string, NSUInteger maxLength)
{
    NSUInteger snippetRangeLength = MIN([string length], maxLength);
    
    if (snippetRangeLength == 0)
    {
        return [NSString string];
    }
    
    NSRange snippetRange = NSMakeRange(0, snippetRangeLength);
    NSRange newlineRange = [string rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]
                                                   options:0
                                                     range:snippetRange];
    
    if (newlineRange.location != NSNotFound)
    {
        snippetRange.length = newlineRange.location;
    }
    
    NSString *untrimmedSnippet = [string substringWithRange:snippetRange];
    return [untrimmedSnippet stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}
