//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaCore.h"
#import <CoreText/CoreText.h>

//--------------------------------------------------------------------------------------------------
// NKTFont is a thin wrapper for CTFont that provides convenient access to the font's attributes.
//--------------------------------------------------------------------------------------------------

@interface NKTFont : NSObject
{
@private
    CTFontRef ctFont;
}

#pragma mark Initializing

- (id)initWithCTFont:(CTFontRef)ctFont;

+ (id)fontWithCTFont:(CTFontRef)ctFont;

#pragma mark Creating System Fonts

+ (id)systemFont;

#pragma mark Getting Font Metrics

@property (nonatomic, readonly) CGFloat ascent;
@property (nonatomic, readonly) CGFloat descent;

@end
