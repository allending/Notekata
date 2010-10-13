//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KBTFontFamilyDescriptor.h"
#import "KBTFont.h"

@implementation KBTFontFamilyDescriptor

@synthesize familyName = familyName_;

#pragma mark Initializing

- (id)initWithFamilyName:(NSString *)familyName
{
    if ((self = [super init]))
    {
        familyName_ = [familyName copy];
    }
    
    return self;
}

+ (id)fontFamilyDescriptorWithFamilyName:(NSString *)familyName
{
    return [[[self alloc] initWithFamilyName:familyName] autorelease];
}

- (void)dealloc
{
    [familyName_ release];
    [super dealloc];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Information About the Font Family

- (BOOL)supportsBoldTrait
{
    NSArray *fontNames = [UIFont fontNamesForFamilyName:familyName_];
    
    for (NSString *fontName in fontNames)
    {
        if (KBTFontNameIdentifiesBoldFont(fontName))
        {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)supportsItalicTrait
{
    NSArray *fontNames = [UIFont fontNamesForFamilyName:familyName_];
    
    for (NSString *fontName in fontNames)
    {
        if (KBTFontNameIdentifiesItalicFont(fontName))
        {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)supportsBoldItalicTrait
{
    NSArray *fontNames = [UIFont fontNamesForFamilyName:familyName_];
    
    for (NSString *fontName in fontNames)
    {
        if (KBTFontNameIdentifiesBoldItalicFont(fontName))
        {
            return YES;
        }
    }
    
    return NO;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Font Names for Variants

- (NSString *)bestFontNameWithBold:(BOOL)bold italic:(BOOL)italic
{
    NSArray *fontNames = [UIFont fontNamesForFamilyName:familyName_];
    NSString *bestFontName = nil;
    
    // Iterate over the fonts in the family to find one matching traits
    for (NSString *fontName in fontNames)
    {
        BOOL hasBoldKeyword = KBTFontNameHasBoldKeyword(fontName);
        BOOL hasItalicKeyword = KBTFontNameHasItalicKeyword(fontName);
        
        if (hasBoldKeyword == bold && hasItalicKeyword == italic)
        {
            bestFontName = fontName;
            break;
        }
    }

    // Use the family name directly as a last resort
    if (bestFontName == nil)
    {
        KBCLogWarning(@"could not find matching name for family name: '%@' bold: %d italic: %d, using family name",
                      familyName_,
                      bold,
                      italic);
        bestFontName = familyName_;
    }
    
    return bestFontName;
}

@end
