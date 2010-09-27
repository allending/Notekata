//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KBTStyleDescriptor.h"
#import "KBTFont.h"
#import "KBTFontFamilyDescriptor.h"

@implementation KBTStyleDescriptor

#pragma mark Initializing

- (id)initWithAttributes:(NSDictionary *)attributes
{
    if ((self = [super init]))
    {
        attributes_ = [attributes copy];
    }
    
    return self;
}

- (id)initWithFontFamilyName:(NSString *)fontFamilyName
                    fontSize:(CGFloat)fontSize
                        bold:(BOOL)bold
                      italic:(BOOL)italic
                  underlined:(BOOL)underlined
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
        fontSize_ = fontSize;
        bold_ = bold;
        italic_ = italic;
        underlined_ = underlined;
    }
    
    return self;
}

+ (id)styleDescriptorWithFontFamilyName:(NSString *)fontFamilyName
                                   fontSize:(CGFloat)fontSize
                                   bold:(BOOL)bold
                                 italic:(BOOL)italic
                             underlined:(BOOL)underlined
{
    return [[[self alloc] initWithFontFamilyName:fontFamilyName
                                        fontSize:fontSize
                                            bold:bold
                                          italic:italic
                                      underlined:underlined] autorelease];
}

+ (id)styleDescriptorWithAttributes:(NSDictionary *)attributes
{
    return [[[self alloc] initWithAttributes:attributes] autorelease];
}

- (void)dealloc
{
    [attributes_ release];
    [fontFamilyName_ release];
    [super dealloc];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Text Style Attributes

- (NSDictionary *)attributes
{
    if (attributes_ != nil)
    {
        return attributes_;
    }
    
    // Style descriptor was created explicitly, so generate and cache the attributes
    KBTFontFamilyDescriptor *fontFamilyDescriptor = [KBTFontFamilyDescriptor fontFamilyDescriptorWithFamilyName:fontFamilyName_];
    NSString *bestFontName = [fontFamilyDescriptor bestFontNameWithBold:bold_ italic:italic_];
    CTFontRef font = CTFontCreateWithName((CFStringRef)bestFontName, fontSize_, NULL);
    
    if (font == NULL)
    {
        KBCLogWarning(@"could not create Core Text font with font name %@", bestFontName);
    }
    
    NSNumber *underlineStyle = [NSNumber numberWithInt:underlined_ ? kCTUnderlineStyleSingle : kCTUnderlineStyleNone];
    attributes_ = [[NSDictionary alloc] initWithObjectsAndKeys:(id)font, (id)kCTFontAttributeName,
                                                               underlineStyle, (id)kCTUnderlineStyleAttributeName,
                                                               nil];
    return attributes_;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Font Style Information

- (NSString *)fontFamilyName
{
    NSDictionary *attributes = self.attributes;
    CTFontRef font = (CTFontRef)[attributes objectForKey:(id)kCTFontAttributeName];
    
    if (font == NULL)
    {
        KBCLogWarning(@"could get font attribute from style attributes, returning nil");
        return nil;
    }
    
    NSString *fontName = (NSString *)CTFontCopyFamilyName(font);
    return [fontName autorelease];
}

- (NSString *)fontName
{
    NSDictionary *attributes = self.attributes;
    CTFontRef font = (CTFontRef)[attributes objectForKey:(id)kCTFontAttributeName];
    
    if (font == NULL)
    {
        KBCLogWarning(@"could get font attribute from style attributes, returning nil");
        return nil;
    }
    
    NSString *fontName = (NSString *)CTFontCopyPostScriptName(font);
    return [fontName autorelease];
}

- (CGFloat)fontSize
{
    NSDictionary *attributes = self.attributes;
    CTFontRef font = (CTFontRef)[attributes objectForKey:(id)kCTFontAttributeName];
        
    if (font == NULL)
    {
        KBCLogWarning(@"could get font attribute from style attributes, returning 0.0");
        return 0.0;
    }
    
    return CTFontGetSize(font);
}

- (KBTFontFamilyDescriptor *)fontFamilyDescriptor
{
   return [KBTFontFamilyDescriptor fontFamilyDescriptorWithFamilyName:self.fontFamilyName];
}

- (BOOL)fontFamilySupportsBoldTrait
{
    return self.fontFamilyDescriptor.supportsBoldTrait;
}

- (BOOL)fontFamilySupportsItalicTrait
{
    return self.fontFamilyDescriptor.supportsItalicTrait;
}

- (BOOL)fontIsBold
{
    NSDictionary *attributes = self.attributes;
    CTFontRef font = (CTFontRef)[attributes objectForKey:(id)kCTFontAttributeName];
    
    if (font == NULL)
    {
        return NO;
    }
    
    CTFontSymbolicTraits symbolicTraits = CTFontGetSymbolicTraits(font);
    return (symbolicTraits & kCTFontBoldTrait) == kCTFontBoldTrait;
}

- (BOOL)fontIsItalic
{
    NSDictionary *attributes = self.attributes;
    CTFontRef font = (CTFontRef)[attributes objectForKey:(id)kCTFontAttributeName];
    
    if (font == NULL)
    {
        return NO;
    }
    
    CTFontSymbolicTraits symbolicTraits = CTFontGetSymbolicTraits(font);
    return (symbolicTraits & kCTFontItalicTrait) == kCTFontItalicTrait;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Creating UIFonts

- (UIFont *)uiFontForFontStyle
{
    return [UIFont fontWithName:self.fontName size:self.fontSize];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Text Style Information

- (BOOL)textIsUnderlined
{
    NSDictionary *attributes = self.attributes;
    
    if (attributes != nil)
    {
        NSNumber *underlineStyle = [attributes objectForKey:(id)kCTUnderlineStyleAttributeName];
        return [underlineStyle integerValue] != kCTUnderlineStyleNone;
    }
    
    return NO;
}

@end
