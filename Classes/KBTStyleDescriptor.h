//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaCore.h"
#import <CoreText/CoreText.h>

//--------------------------------------------------------------------------------------------------
// KBTStyleDescriptor
//--------------------------------------------------------------------------------------------------

@interface KBTStyleDescriptor : NSObject
{
@private
    NSDictionary *attributes_;
    
    NSString *fontFamilyName_;
    CGFloat fontSize_;
    BOOL bold_;
    BOOL italic_;
    BOOL underlined_;
}

#pragma mark Initializing

- (id)initWithAttributes:(NSDictionary *)attributes;
- (id)initWithFontFamilyName:(NSString *)fontFamilyName
                    fontSize:(CGFloat)fontSize
                        bold:(BOOL)bold
                      italic:(BOOL)italic
                  underlined:(BOOL)underlined;

+ (id)styleDescriptorWithAttributes:(NSDictionary *)attributes;
+ (id)styleDescriptorWithFontFamilyName:(NSString *)fontFamilyName
                               fontSize:(CGFloat)fontSize
                                   bold:(BOOL)bold
                                 italic:(BOOL)italic
                             underlined:(BOOL)underlined;

#pragma mark Getting Text Style Attributes

- (NSDictionary *)attributes;

#pragma mark Getting Font Style Information

@property (nonatomic, readonly) NSString *fontFamilyName;
@property (nonatomic, readonly) NSString *fontName;
@property (nonatomic, readonly) CGFloat fontSize;
@property (nonatomic, readonly) BOOL fontFamilySupportsBoldTrait;
@property (nonatomic, readonly) BOOL fontFamilySupportsItalicTrait;
@property (nonatomic, readonly) BOOL fontIsBold;
@property (nonatomic, readonly) BOOL fontIsItalic;

#pragma mark Creating UIFonts

- (UIFont *)uiFontForFontStyle;

#pragma mark Getting Text Style Information

@property (nonatomic, readonly) BOOL textIsUnderlined;

@end
