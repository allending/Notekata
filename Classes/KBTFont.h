//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaCore.h"
#import <CoreText/CoreText.h>

UIFont *KBTUIFontForCTFont(CTFontRef ctFont);

NSString *KBTFontFamilyNameForTextAttributes(NSDictionary *attributes);

BOOL KBTFontNameHasTraitKeyword(NSString *fontName, NSString *traitKeyword);
BOOL KBTFontNameHasBoldKeyword(NSString *fontName);
BOOL KBTFontNameHasItalicKeyword(NSString *fontName);
BOOL KBTFontNameIdentifiesBoldFont(NSString *fontName);
BOOL KBTFontNameIdentifiesItalicFont(NSString *fontName);
BOOL KBTFontNameIdentifiesBoldItalicFont(NSString *fontName);
