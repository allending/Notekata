//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KBCFont.h"

UIFont *KBCUIFontForCTFont(CTFontRef ctFont)
{
    CFStringRef fontName = CTFontCopyPostScriptName(ctFont);
    CGFloat fontSize = CTFontGetSize(ctFont);
    UIFont *font = [UIFont fontWithName:(NSString *)fontName size:fontSize];
    CFRelease(fontName);
    return font;
}
