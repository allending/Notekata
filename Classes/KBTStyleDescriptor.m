//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KBTStyleDescriptor.h"
#import "KBTFont.h"
#import "KBTFontFamilyDescriptor.h"

@interface KBTStyleDescriptor()

#pragma mark Initializing

- (id)initWithFontFamilyName:(NSString *)fontFamilyName size:(CGFloat)size bold:(BOOL)bold italic:(BOOL)italic underlined:(BOOL)underlined;
- (id)initWithAttributes:(NSDictionary *)attributes;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------

@implementation KBTStyleDescriptor

#pragma mark Initializing

- (id)initWithFontFamilyName:(NSString *)fontFamilyName size:(CGFloat)size bold:(BOOL)bold italic:(BOOL)italic underlined:(BOOL)underlined
{
    if ((self = [super init]))
    {
        if (fontFamilyName == nil)
        {
            KBCLogWarning(@"font family name must not be nil, returning nil");
            [self release];
            return nil;
        }
        
        fontFamilyName_ = [fontFamilyName copy];
        size_ = size;
        bold_ = bold;
        italic_ = italic;
        underlined_ = underlined;
    }
    
    return self;
}

- (id)initWithAttributes:(NSDictionary *)attributes
{
    if ((self = [super init]))
    {
        attributes_ = [attributes copy];
    }
    
    return self;
}

+ (id)styleDescriptorWithFontFamilyName:(NSString *)fontFamilyName
                                   size:(CGFloat)size
                                   bold:(BOOL)bold
                                 italic:(BOOL)italic
                             underlined:(BOOL)underlined
{
    return [[[self alloc] initWithFontFamilyName:fontFamilyName size:size bold:bold italic:italic underlined:underlined] autorelease];
}

+ (id)styleDescriptorWithAttributes:(NSDictionary *)attributes
{
    return [[[self alloc] initWithAttributes:attributes] autorelease];
}

- (void)dealloc
{
    [fontFamilyName_ release];
    [attributes_ release];
    [super dealloc];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Information About the Style Descriptor

- (BOOL)boldTraitEnabled
{
    if (fontFamilyName_ != nil)
    {
        return bold_;
    }
    
    if (attributes_ != nil)
    {
        CTFontRef font = (CTFontRef)[attributes_ objectForKey:(id)kCTFontAttributeName];
        
        if (font == NULL)
        {
            return NO;
        }
        
        CTFontSymbolicTraits symbolicTraits = CTFontGetSymbolicTraits(font);
        return (symbolicTraits & kCTFontBoldTrait) == kCTFontBoldTrait;
    }
    
    return NO;
}

- (BOOL)italicTraitEnabled
{
    if (fontFamilyName_ != nil)
    {
        return italic_;
    }
    
    if (attributes_ != nil)
    {
        CTFontRef font = (CTFontRef)[attributes_ objectForKey:(id)kCTFontAttributeName];
        
        if (font == NULL)
        {
            return NO;
        }
        
        CTFontSymbolicTraits symbolicTraits = CTFontGetSymbolicTraits(font);
        return (symbolicTraits & kCTFontItalicTrait) == kCTFontItalicTrait;
    }
    
    return NO;
}

- (BOOL)underlineEnabled
{
    if (fontFamilyName_ != nil)
    {
        return underlined_;
    }
    
    if (attributes_ != nil)
    {
        NSNumber *underlineStyle = [attributes_ objectForKey:(id)kCTUnderlineStyleAttributeName];
        return [underlineStyle integerValue] != kCTUnderlineStyleNone;
    }
    
    return NO;
}

- (KBTFontFamilyDescriptor *)fontFamilyDescriptor
{
    if (fontFamilyName_ != nil)
    {
        return [KBTFontFamilyDescriptor fontFamilyDescriptorWithFamilyName:fontFamilyName_];
    }
    
    if (attributes_ != nil)
    {
        NSString *fontFamilyName = KBTFontFamilyNameForTextAttributes(attributes_);
        return [KBTFontFamilyDescriptor fontFamilyDescriptorWithFamilyName:fontFamilyName];
    }
    
    return nil;
}

- (CGFloat)fontSize
{
    if (attributes_ != nil)
    {
        CTFontRef font = (CTFontRef)[attributes_ objectForKey:(id)kCTFontAttributeName];
        
        if (font == NULL)
        {
            KBCLogWarning(@"could get font attribute from style attributes, returning 0.0");
            return 0.0;
        }
        
        return CTFontGetSize(font);
    }
    else
    {
        return size_;
    }
}

- (NSDictionary *)attributes
{
    if (attributes_ != nil)
    {
        return attributes_;
    }
    
    // Style descriptor was created explicitly, so generate and cache the attributes        
    NSArray *fontNames = [UIFont fontNamesForFamilyName:fontFamilyName_];
    NSString *matchingFontName = nil;
    
    // Iterate over the fonts in the family to find one matching traits
    for (NSString *fontName in fontNames)
    {
        BOOL hasBoldKeyword = KBTFontNameHasBoldKeyword(fontName);
        BOOL hasItalicKeyword = KBTFontNameHasItalicKeyword(fontName);
        
        if (hasBoldKeyword == bold_ && hasItalicKeyword == italic_)
        {
            matchingFontName = fontName;
            break;
        }
    }
    
    // Use the family name directly as a last resort
    if (matchingFontName == nil)
    {
        KBCLogWarning(@"could not find matching name for family name: '%@' size: %f bold: %d italic: %d, using family name",
                      fontFamilyName_,
                      size_,
                      bold_,
                      italic_);
        matchingFontName = fontFamilyName_;
    }
    
    CTFontRef font = CTFontCreateWithName((CFStringRef)matchingFontName, size_, NULL);
    
    if (font == NULL)
    {
        KBCLogWarning(@"could not create Core Text font with font name %@", matchingFontName);
    }
    
    NSNumber *underlineStyle = [NSNumber numberWithInt:underlined_ ? kCTUnderlineStyleSingle : kCTUnderlineStyleNone];
    attributes_ = [[NSDictionary alloc] initWithObjectsAndKeys:(id)font, (id)kCTFontAttributeName,
                                                               underlineStyle, (id)kCTUnderlineStyleAttributeName,
                                                               nil];
    return attributes_;
}

@end
