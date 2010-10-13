//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KBTFont.h"

#pragma mark -
#pragma mark Creating UIFonts From CTFonts

UIFont *KBTUIFontForCTFont(CTFontRef ctFont)
{
    CFStringRef fontName = CTFontCopyPostScriptName(ctFont);
    CGFloat fontSize = CTFontGetSize(ctFont);
    UIFont *font = [UIFont fontWithName:(NSString *)fontName size:fontSize];
    CFRelease(fontName);
    return font;
}

#pragma mark -
#pragma mark Getting Information About Font Names

// Font names have the form "FontFamilyName-TraitKeywords"
BOOL KBTFontNameHasTraitKeyword(NSString *fontName, NSString *traitKeyword)
{
    NSRange separatorRange = [fontName rangeOfString:@"-"];
    
    if (separatorRange.location == NSNotFound || separatorRange.location >= [fontName length])
    {
        return NO;
    }
    
    NSUInteger searchRangeLocation = NSMaxRange(separatorRange);
    NSRange searchRange = NSMakeRange(searchRangeLocation, [fontName length] - searchRangeLocation);
    NSRange resultRange = [fontName rangeOfString:traitKeyword options:0 range:searchRange];
    return resultRange.location != NSNotFound;
}

BOOL KBTFontNameHasBoldKeyword(NSString *fontName)
{
    return KBTFontNameHasTraitKeyword(fontName, @"Bold") || KBTFontNameHasTraitKeyword(fontName, @"Black");
}

BOOL KBTFontNameHasItalicKeyword(NSString *fontName)
{
    return KBTFontNameHasTraitKeyword(fontName, @"Italic") || KBTFontNameHasTraitKeyword(fontName, @"Oblique");
}

BOOL KBTFontNameIdentifiesBoldFont(NSString *fontName)
{
    return KBTFontNameHasBoldKeyword(fontName) && !KBTFontNameHasItalicKeyword(fontName);
}

BOOL KBTFontNameIdentifiesItalicFont(NSString *fontName)
{
    return !KBTFontNameHasBoldKeyword(fontName) && KBTFontNameHasItalicKeyword(fontName);
}

BOOL KBTFontNameIdentifiesBoldItalicFont(NSString *fontName)
{
    return KBTFontNameHasBoldKeyword(fontName) && KBTFontNameHasItalicKeyword(fontName);
}