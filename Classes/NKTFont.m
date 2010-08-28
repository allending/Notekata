//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTFont.h"

#import "NKTLogging.h"

@implementation NKTFont

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (id)initWithCTFont:(CTFontRef)theCTFont
{
    if ((self = [super init]))
    {
        if (theCTFont == NULL)
        {
            NKTLogWarning(@"theCTFont argument is nil, releasing self and returning nil");
            [self release];
            return nil;
        }

        ctFont = CFRetain(theCTFont);
    }
    
    return self;
}

+ (id)fontWithCTFont:(CTFontRef)ctFont
{
    return [[[self alloc] initWithCTFont:ctFont] autorelease];
}

- (void)dealloc
{
    CFRelease(ctFont);
    [super dealloc];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Creating System Fonts

+ (id)systemFont
{
    UIFont *systemFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    CTFontRef font = CTFontCreateWithName((CFStringRef)systemFont.fontName, systemFont.pointSize, nil);
    return [self fontWithCTFont:font];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Font Metrics

- (CGFloat)ascent
{
    return CTFontGetAscent(ctFont);
}

- (CGFloat)descent
{
    return CTFontGetDescent(ctFont);
}

@end
