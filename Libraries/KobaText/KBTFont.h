//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KobaCore.h"
#import <CoreText/CoreText.h>

#pragma mark Creating UIFonts From CTFonts

UIFont *KBTUIFontForCTFont(CTFontRef ctFont);

#pragma mark Getting Information About Font Names

BOOL KBTFontNameHasTraitKeyword(NSString *fontName, NSString *traitKeyword);
BOOL KBTFontNameHasBoldKeyword(NSString *fontName);
BOOL KBTFontNameHasItalicKeyword(NSString *fontName);
BOOL KBTFontNameIdentifiesBoldFont(NSString *fontName);
BOOL KBTFontNameIdentifiesItalicFont(NSString *fontName);
BOOL KBTFontNameIdentifiesBoldItalicFont(NSString *fontName);
