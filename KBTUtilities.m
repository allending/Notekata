//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KBTUtilities.h"

void KBTEnumerateAttributedStringAttributes(NSAttributedString *attributedString, NSArray **ranges, NSArray **attributeDictionaries, BOOL coalesceRanges)
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
