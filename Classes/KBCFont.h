//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

// There is no standard API to convert Core Text fonts to UIFonts. In fact, the font name for a
// physically identical font in both frameworks are not guaranteed to be identical.
// KBCUIFontForCTFont attempts to create an identical or similar UIFont from a CTFont.
UIFont *KBCUIFontForCTFont(CTFontRef ctFont);
