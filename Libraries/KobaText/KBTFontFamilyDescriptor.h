//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KobaCore.h"

// KBTFontFamilyDescriptor
@interface KBTFontFamilyDescriptor : NSObject
{
@private
    NSString *familyName_;
    BOOL supportsBoldTrait_;
    BOOL supportsItalicTrait_;
    BOOL supportsBoldItalicTrait_;
}

#pragma mark Initializing

+ (id)fontFamilyDescriptorWithFamilyName:(NSString *)familyName;

#pragma mark Getting Information About the Font Family

@property (nonatomic, readonly) NSString *familyName;
@property (nonatomic, readonly) BOOL supportsBoldTrait;
@property (nonatomic, readonly) BOOL supportsItalicTrait;
@property (nonatomic, readonly) BOOL supportsBoldItalicTrait;

#pragma mark Getting Font Names

- (NSString *)bestFontNameWithBold:(BOOL)bold italic:(BOOL)italic;

@end
