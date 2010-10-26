//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KBTFontFamilyDescriptor.h"
#import "KBTFont.h"

@implementation KBTFontFamilyDescriptor

@synthesize familyName = familyName_;
@synthesize supportsBoldTrait = supportsBoldTrait_;
@synthesize supportsItalicTrait = supportsItalicTrait_;
@synthesize supportsBoldItalicTrait = supportsBoldItalicTrait_;

#pragma mark -
#pragma mark Initializing

- (id)initWithFamilyName:(NSString *)familyName
{
    if ((self = [super init]))
    {
        familyName_ = [familyName copy];
        
        NSArray *fontNames = [UIFont fontNamesForFamilyName:familyName_];
        
        for (NSString *fontName in fontNames)
        {
            if (KBTFontNameIdentifiesBoldFont(fontName))
            {
                supportsBoldTrait_ = YES;
            }
            
            if (KBTFontNameIdentifiesItalicFont(fontName))
            {
                supportsItalicTrait_ = YES;
            }
            
            if (KBTFontNameIdentifiesBoldItalicFont(fontName))
            {
                supportsBoldItalicTrait_ = YES;
            }
        }
    }
    
    return self;
}

+ (id)fontFamilyDescriptorWithFamilyName:(NSString *)familyName
{
    static NSMutableDictionary *descriptorCache = nil;
    
    if (descriptorCache == nil)
    {
        descriptorCache = [[NSMutableDictionary alloc] initWithCapacity:20];
    }
    
    KBTFontFamilyDescriptor *descriptor = [descriptorCache objectForKey:familyName];
    
    if (descriptor != nil)
    {
        return descriptor;
    }
    
    descriptor = [[self alloc] initWithFamilyName:familyName];
    [descriptorCache setObject:descriptor forKey:familyName];
    [descriptor release];
    return descriptor;
}

#pragma mark -
#pragma mark Memory

- (void)dealloc
{
    [familyName_ release];
    [super dealloc];
}

#pragma mark -
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
        //KBCLogDebug(@"could not find matching name for family name: '%@' bold: %d italic: %d, using family name", familyName_, bold, italic);
        bestFontName = familyName_;
    }
    
    return bestFontName;
}

@end
