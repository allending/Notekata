//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KBTUtilities.h"

#pragma mark -
#pragma mark Enumerating String Attributes

void KBTEnumerateAttributedStringAttributes(NSAttributedString *attributedString,
                                            NSArray **ranges,
                                            NSArray **attributeDictionaries,
                                            BOOL coalesceRanges)
{
    NSMutableArray *mutableRanges = [NSMutableArray array];
    NSMutableArray *mutableAttributeDictionaries = [NSMutableArray array];    
    NSUInteger index = 0;
    NSUInteger length = [attributedString length];
    NSRange fullRange = NSMakeRange(0, length);
    
    while (index < length)
    {
        NSRange effectiveRange;
        NSDictionary *attributes = nil;
        
        if (coalesceRanges)
        {
            attributes = [attributedString attributesAtIndex:index longestEffectiveRange:&effectiveRange inRange:fullRange];
        }
        else
        {
            attributes = [attributedString attributesAtIndex:index effectiveRange:&effectiveRange];
        }
        
        [mutableAttributeDictionaries addObject:attributes];
        [mutableRanges addObject:[NSValue valueWithRange:effectiveRange]];
        index = effectiveRange.location + effectiveRange.length;
    }
    
    *ranges = mutableRanges;
    *attributeDictionaries = mutableAttributeDictionaries;
}

void KBTLightweightEnumerateAttributedStringAttributesInRange(NSAttributedString *attributedString,
                                                              NSArray **outAttributes,
                                                              NSRange range)
{
    NSMutableArray *coreTextAttributes = [NSMutableArray arrayWithCapacity:4];
    NSUInteger index = range.location;
    NSUInteger endIndex = NSMaxRange(range);
    
    while (index < endIndex)
    {
        NSRange effectiveRange;
        NSDictionary *attributes = [attributedString attributesAtIndex:index effectiveRange:&effectiveRange];
        [coreTextAttributes addObject:attributes];
        index = effectiveRange.location + effectiveRange.length;
    }
    
    *outAttributes = coreTextAttributes;
}

#pragma mark -
#pragma mark Getting Strings

NSString *KBTDebugDescriptionForAttributedString(NSAttributedString *attributedString, BOOL coalesceRanges)
{
    NSArray *ranges, *attributeDictionaries;
    KBTEnumerateAttributedStringAttributes(attributedString, &ranges, &attributeDictionaries, NO);
    
    NSMutableString *description = [NSMutableString string];    
    [description appendFormat:@"%d total ranges\n", [ranges count]];
    [description appendFormat:@"---------------\n"];
    
    for (NSUInteger index = 0; index < [ranges count]; ++index)
    {
        NSRange range = [[ranges objectAtIndex:index] rangeValue];
        [description appendFormat:@"range %d [%d, %d]: %@\n", 
         index,
         range.location,
         range.location + range.length,
         [[attributedString string] substringWithRange:range]];
    }
    
    return description;
}

NSString *KBTStringFromUITextDirection(UITextDirection direction)
{
    switch (direction)
    {
        case UITextStorageDirectionForward:
            return @"Forward";
        case UITextStorageDirectionBackward:
            return @"Backward";
        case UITextLayoutDirectionRight:
            return @"Right";
        case UITextLayoutDirectionLeft:
            return @"Left";
        case UITextLayoutDirectionUp:
            return @"Up";
        case UITextLayoutDirectionDown:
            return @"Down";
    }
    
    return @"Unknown";
}

NSString *KBTStringFromUITextGranularity(UITextGranularity granularity)
{
    switch (granularity)
    {
        case UITextGranularityCharacter:
            return @"Character";
        case UITextGranularityWord:
            return @"Word";
        case UITextGranularitySentence:
            return @"Sentence";
        case UITextGranularityParagraph:
            return @"Paragraph";
        case UITextGranularityLine:
            return @"Line";
        case UITextGranularityDocument:
            return @"Document";
    }
    
    return @"Unknown";
}
