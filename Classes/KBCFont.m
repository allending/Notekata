//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KBCFont.h"

// TODO: perform caching
UIFont *KBCUIFontForCTFont(CTFontRef ctFont)
{
    // Get the UIKit font names for the family
    CFStringRef familyName = CTFontCopyName(ctFont, kCTFontFamilyNameKey);
    NSArray *fontNames = [UIFont fontNamesForFamilyName:(NSString *)familyName];
    CFRelease(familyName);
    
    // Get optional style name tokens
    CFStringRef styleName = CTFontCopyName(ctFont, kCTFontStyleNameKey);
    NSArray *styleTokens = [(NSString *)styleName componentsSeparatedByString:@" "];
    
    if (styleName != NULL)
    {
        CFRelease(styleName);
    }
    
    NSString *bestFontName = nil;
    NSUInteger bestScore = 0;
    
    // Score each font name in the family font names
    for (NSString *fontName in fontNames)
    {
        NSUInteger score = 0;
        
        for (NSString *styleToken in styleTokens)
        {
            NSRange range = [fontName rangeOfString:styleToken];
            
            if (range.location != NSNotFound)
            {
                ++score;
            }
        }
        
        if (bestFontName == nil || score > bestScore)
        {
            bestFontName = fontName;
            bestScore = score;
        }
        
        // Maximum score reached
        if (bestScore == [styleTokens count])
        {
            break;
        }
    }
    
    if (bestFontName != nil)
    {
        CGFloat fontSize = CTFontGetSize(ctFont);
        return [UIFont fontWithName:bestFontName size:fontSize];
    }
    else
    {
        return nil;
    }
}
