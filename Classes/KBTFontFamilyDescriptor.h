//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaCore.h"

//--------------------------------------------------------------------------------------------------
// KBTFontFamilyDescriptor
//--------------------------------------------------------------------------------------------------

@interface KBTFontFamilyDescriptor : NSObject
{
@private
    NSString *familyName_;
}

#pragma mark Initializing

+ (id)fontFamilyDescriptorWithFamilyName:(NSString *)familyName;

#pragma mark Getting Information About the Font Family

@property (nonatomic, readonly) NSString *familyName;
@property (nonatomic, readonly) BOOL supportsBoldTrait;
@property (nonatomic, readonly) BOOL supportsItalicTrait;
@property (nonatomic, readonly) BOOL supportsBoldItalicTrait;

@end
