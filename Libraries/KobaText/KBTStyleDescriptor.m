//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KBTStyleDescriptor.h"
#import <CoreText/CoreText.h>
#import "KBTFontFamilyDescriptor.h"

@implementation KBTStyleDescriptor

static NSString *FontFamilyNameKey = @"FontFamilyName";
static NSString *FontSizeKey = @"FontSize";
static NSString *BoldKey = @"Bold";
static NSString *ItalicKey = @"Italic";
static NSString *UnderlinedKey = @"Underlined";

#pragma mark -
#pragma mark Initializing

- (id)initWithCoreTextAttributes:(NSDictionary *)coreTextAttributes
{
    if ((self = [super init]))
    {
        if ([coreTextAttributes count] == 0)
        {
            KBCLogWarning(@"Core text attributes dictionary is empty. Initializing with default attributes.");
            fontFamilyName_ = @"Helvetica Neue";
            fontSize_ = 16.0;
        }
        else
        {
            coreTextAttributes_ = [coreTextAttributes copy];
        }
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
            KBCLogWarning(@"Font family name is nil. Using Helvetica Neue.");
            fontFamilyName = @"Helvetica Neue";
        }

        if (fontSize == 0.0)
        {
            KBCLogWarning(@"Font size is 0.0. Using 16.0.");
            fontSize = 16.0;
        }
        
        fontFamilyName_ = [fontFamilyName copy];
        fontSize_ = fontSize;
        bold_ = bold;
        italic_ = italic;
        underlined_ = underlined;
    }
    
    return self;
}

- (id)initWithPortableRepresentation:(NSDictionary *)portableRepresentation
{
    NSString *familyName = [portableRepresentation objectForKey:FontFamilyNameKey];
    CGFloat fontSize = [[portableRepresentation objectForKey:FontSizeKey] floatValue];
    BOOL bold = [[portableRepresentation objectForKey:BoldKey] boolValue];
    BOOL italic = [[portableRepresentation objectForKey:ItalicKey] boolValue];
    BOOL underlined = [[portableRepresentation objectForKey:UnderlinedKey] boolValue];
    return [self initWithFontFamilyName:familyName
                               fontSize:fontSize
                                   bold:bold
                                 italic:italic
                             underlined:underlined];
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

+ (id)styleDescriptorWithCoreTextAttributes:(NSDictionary *)coreTextAttributes
{
    return [[[self alloc] initWithCoreTextAttributes:coreTextAttributes] autorelease];
}

+ (id)styleDescriptorWithPortableRepresentation:(NSDictionary *)portableRepresentation
{
    return [[[self alloc] initWithPortableRepresentation:portableRepresentation] autorelease];
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc
{
    [coreTextAttributes_ release];
    [fontFamilyName_ release];
    [super dealloc];
}

#pragma mark -
#pragma mark Getting Font Style Information

- (NSString *)fontFamilyName
{
    NSDictionary *attributes = self.coreTextAttributes;
    CTFontRef font = (CTFontRef)[attributes objectForKey:(id)kCTFontAttributeName];
    
    if (font == NULL)
    {
        KBCLogWarning(@"Could not get font attribute from style attributes. Returning nil.");
        return nil;
    }
    
    NSString *fontName = (NSString *)CTFontCopyFamilyName(font);
    return [fontName autorelease];
}

- (NSString *)fontName
{
    NSDictionary *attributes = self.coreTextAttributes;
    CTFontRef font = (CTFontRef)[attributes objectForKey:(id)kCTFontAttributeName];
    
    if (font == NULL)
    {
        KBCLogWarning(@"Could not get font attribute from style attributes. Returning nil.");
        return nil;
    }
    
    NSString *fontName = (NSString *)CTFontCopyPostScriptName(font);
    return [fontName autorelease];
}

- (CGFloat)fontSize
{
    NSDictionary *attributes = self.coreTextAttributes;
    CTFontRef font = (CTFontRef)[attributes objectForKey:(id)kCTFontAttributeName];
    
    if (font == NULL)
    {
        KBCLogWarning(@"Could not get font attribute from style attributes. Returning 0.0.");
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

- (BOOL)fontFamilySupportsBoldItalicTrait
{
    return self.fontFamilyDescriptor.supportsBoldItalicTrait;
}

- (BOOL)fontIsBold
{
    NSDictionary *attributes = self.coreTextAttributes;
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
    NSDictionary *attributes = self.coreTextAttributes;
    CTFontRef font = (CTFontRef)[attributes objectForKey:(id)kCTFontAttributeName];
    
    if (font == NULL)
    {
        return NO;
    }
    
    CTFontSymbolicTraits symbolicTraits = CTFontGetSymbolicTraits(font);
    return (symbolicTraits & kCTFontItalicTrait) == kCTFontItalicTrait;
}


#pragma mark -
#pragma mark Getting Text Style Information

- (BOOL)textIsUnderlined
{
    NSDictionary *attributes = self.coreTextAttributes;
    
    if (attributes != nil)
    {
        NSNumber *underlineStyle = [attributes objectForKey:(id)kCTUnderlineStyleAttributeName];
        return [underlineStyle integerValue] != kCTUnderlineStyleNone;
    }
    
    return NO;
}

#pragma mark -
#pragma mark Creating Variant Style Descriptors

- (KBTStyleDescriptor *)styleDescriptorBySettingFontFamilyName:(NSString *)fontFamilyName
{
    return [[self class] styleDescriptorWithFontFamilyName:fontFamilyName
                                                  fontSize:self.fontSize
                                                      bold:self.fontIsBold
                                                    italic:self.fontIsItalic
                                                underlined:self.textIsUnderlined];
}

- (KBTStyleDescriptor *)styleDescriptorBySettingFontSize:(CGFloat)fontSize
{
    return [[self class] styleDescriptorWithFontFamilyName:self.fontFamilyName
                                                  fontSize:fontSize
                                                      bold:self.fontIsBold
                                                    italic:self.fontIsItalic
                                                underlined:self.textIsUnderlined];
}

- (KBTStyleDescriptor *)styleDescriptorByEnablingBoldTrait
{
    if (!self.fontFamilySupportsBoldTrait)
    {
        return self;
    }
    
    return [[self class] styleDescriptorWithFontFamilyName:self.fontFamilyName
                                                  fontSize:self.fontSize
                                                      bold:YES
                                                    italic:self.fontIsItalic && self.fontFamilySupportsBoldItalicTrait
                                                underlined:self.textIsUnderlined];
}

- (KBTStyleDescriptor *)styleDescriptorByDisablingBoldTrait
{
    if (!self.fontFamilySupportsBoldTrait)
    {
        return self;
    }
    
    return [[self class] styleDescriptorWithFontFamilyName:self.fontFamilyName
                                                  fontSize:self.fontSize
                                                      bold:NO
                                                    italic:self.fontIsItalic
                                                underlined:self.textIsUnderlined];
}

- (KBTStyleDescriptor *)styleDescriptorByEnablingItalicTrait
{
    if (!self.fontFamilySupportsItalicTrait)
    {
        return self;
    }
    
    return [[self class] styleDescriptorWithFontFamilyName:self.fontFamilyName
                                                  fontSize:self.fontSize
                                                      bold:self.fontIsBold && self.fontFamilySupportsBoldItalicTrait
                                                    italic:YES
                                                underlined:self.textIsUnderlined];
}

- (KBTStyleDescriptor *)styleDescriptorByDisablingItalicTrait
{
    if (!self.fontFamilySupportsItalicTrait)
    {
        return self;
    }
    
    return [[self class] styleDescriptorWithFontFamilyName:self.fontFamilyName
                                                  fontSize:self.fontSize
                                                      bold:self.fontIsBold
                                                    italic:NO
                                                underlined:self.textIsUnderlined];
}

- (KBTStyleDescriptor *)styleDescriptorByEnablingUnderline
{
    return [[self class] styleDescriptorWithFontFamilyName:self.fontFamilyName
                                                  fontSize:self.fontSize
                                                      bold:self.fontIsBold
                                                    italic:self.fontIsItalic
                                                underlined:YES];
}

- (KBTStyleDescriptor *)styleDescriptorByDisablingUnderline
{
    return [[self class] styleDescriptorWithFontFamilyName:self.fontFamilyName
                                                  fontSize:self.fontSize
                                                      bold:self.fontIsBold
                                                    italic:self.fontIsItalic
                                                underlined:NO];
}

#pragma mark -
#pragma mark Creating UIFonts

- (UIFont *)uiFontForFont
{
    return [UIFont fontWithName:self.fontName size:self.fontSize];
}

#pragma mark -
#pragma mark Getting Representations

// The coreTextAttributes property acts as the primary source of information for the style descriptor. Other methods in
// NKTStyleDescriptor access the property as a primitive operation. When the style descriptor is initialized without
// specifying the Core Text attributes, this causes the appropriate attributes to be created and cached in the
// coreTextAttributes_ ivar.
- (NSDictionary *)coreTextAttributes
{
    if (coreTextAttributes_ != nil)
    {
        return coreTextAttributes_;
    }
    
    KBTFontFamilyDescriptor *fontFamilyDescriptor = [KBTFontFamilyDescriptor fontFamilyDescriptorWithFamilyName:fontFamilyName_];
    NSString *bestFontName = [fontFamilyDescriptor bestFontNameWithBold:bold_ italic:italic_];
    CTFontRef bestFont = CTFontCreateWithName((CFStringRef)bestFontName, fontSize_, NULL);
    
    if (bestFont == NULL)
    {
        KBCLogWarning(@"Could not create Core Text font with font name %@. Returning nil.", bestFontName);
        return nil;
    }
    
    NSInteger underlineStyle = underlined_ ? kCTUnderlineStyleSingle : kCTUnderlineStyleNone;
    coreTextAttributes_ = [[NSDictionary alloc] initWithObjectsAndKeys:(id)bestFont, (id)kCTFontAttributeName,
                                                                       [NSNumber numberWithInt:underlineStyle], (id)kCTUnderlineStyleAttributeName,
                                                                       nil];
    CFRelease(bestFont);
    
    return coreTextAttributes_;
}

- (NSDictionary *)portableRepresentation
{
    return [NSDictionary dictionaryWithObjectsAndKeys:self.fontFamilyName, FontFamilyNameKey,
                                                      [NSNumber numberWithFloat:self.fontSize], FontSizeKey,
                                                      [NSNumber numberWithBool:self.fontIsBold], BoldKey,
                                                      [NSNumber numberWithBool:self.fontIsItalic], ItalicKey,
                                                      [NSNumber numberWithBool:self.textIsUnderlined], UnderlinedKey,
                                                      nil];
}

@end
