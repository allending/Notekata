//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KobaCore.h"

// KBTStyleDescriptor represents information about a style for a range of text. It provides methods to easily make
// queries about fonts, traits, and text attributes. Variant KBTStyleDescriptors can easily be created from existing
// style descriptors. NKTStyleDescriptor also plays a role as an intermediate form that provides simple conversions
// between Core Text attributes (for use in attributed strings), and portable representations that are serializable.
@interface KBTStyleDescriptor : NSObject
{
@private
    NSDictionary *coreTextAttributes_;
    NSString *fontFamilyName_;
    CGFloat fontSize_;
    BOOL bold_;
    BOOL italic_;
    BOOL underlined_;
}

#pragma mark Initializing

- (id)initWithCoreTextAttributes:(NSDictionary *)coreTextAttributes;
- (id)initWithFontFamilyName:(NSString *)fontFamilyName
                    fontSize:(CGFloat)fontSize
                        bold:(BOOL)bold
                      italic:(BOOL)italic
                  underlined:(BOOL)underlined;
- (id)initWithPortableRepresentation:(NSDictionary *)portableRepresentation;

+ (id)styleDescriptorWithCoreTextAttributes:(NSDictionary *)coreTextAttributes;
+ (id)styleDescriptorWithFontFamilyName:(NSString *)fontFamilyName
                               fontSize:(CGFloat)fontSize
                                   bold:(BOOL)bold
                                 italic:(BOOL)italic
                             underlined:(BOOL)underlined;
+ (id)styleDescriptorWithPortableRepresentation:(NSDictionary *)portableRepresentation;

// TODO: break out fonts into separate descriptor?

#pragma mark Getting Font Style Information

@property (nonatomic, readonly) NSString *fontFamilyName;
@property (nonatomic, readonly) NSString *fontName;
@property (nonatomic, readonly) CGFloat fontSize;
@property (nonatomic, readonly) BOOL fontFamilySupportsBoldTrait;
@property (nonatomic, readonly) BOOL fontFamilySupportsItalicTrait;
@property (nonatomic, readonly) BOOL fontFamilySupportsBoldItalicTrait;
@property (nonatomic, readonly) BOOL fontIsBold;
@property (nonatomic, readonly) BOOL fontIsItalic;

#pragma mark Getting Text Style Information

@property (nonatomic, readonly) BOOL textIsUnderlined;

#pragma mark Creating Variant Style Descriptors

- (KBTStyleDescriptor *)styleDescriptorBySettingFontFamilyName:(NSString *)fontFamilyName;
- (KBTStyleDescriptor *)styleDescriptorBySettingFontSize:(CGFloat)fontSize;
- (KBTStyleDescriptor *)styleDescriptorByEnablingBoldTrait;
- (KBTStyleDescriptor *)styleDescriptorByDisablingBoldTrait;
- (KBTStyleDescriptor *)styleDescriptorByEnablingItalicTrait;
- (KBTStyleDescriptor *)styleDescriptorByDisablingItalicTrait;
- (KBTStyleDescriptor *)styleDescriptorByEnablingUnderline;
- (KBTStyleDescriptor *)styleDescriptorByDisablingUnderline;

#pragma mark Creating UIFonts

- (UIFont *)uiFontForFont;

#pragma mark Getting Representations

- (NSDictionary *)coreTextAttributes;
- (NSDictionary *)portableRepresentation;

@end
