//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaCore.h"
#import <CoreText/CoreText.h>

@class KBTFontFamilyDescriptor;

@interface KBTStyleDescriptor : NSObject
{
@private
    NSString *fontFamilyName_;
    CGFloat size_;
    BOOL bold_;
    BOOL italic_;
    BOOL underlined_;
    
    NSDictionary *attributes_;
}

#pragma mark Initializing

+ (id)styleDescriptorWithFontFamilyName:(NSString *)fontFamilyName
                                   size:(CGFloat)size
                                   bold:(BOOL)bold
                                 italic:(BOOL)italic
                             underlined:(BOOL)underlined;
+ (id)styleDescriptorWithAttributes:(NSDictionary *)attributes;

#pragma mark Getting Information About the Style Descriptor

@property (nonatomic, readonly) BOOL boldTraitEnabled;
@property (nonatomic, readonly) BOOL italicTraitEnabled;
@property (nonatomic, readonly) BOOL underlineEnabled;

- (KBTFontFamilyDescriptor *)fontFamilyDescriptor;
- (NSDictionary *)attributes;

@end
