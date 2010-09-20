//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KBTFontFamilyDescriptor.h"
#import "KBTFont.h"

@interface KBTFontFamilyDescriptor()

#pragma mark Initializing

- (id)initWithFamilyName:(NSString *)familyName;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------

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

@end
