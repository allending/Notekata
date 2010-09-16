//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaCore.h"
#import <CoreText/CoreText.h>

// TODO: emulate NSFontManager?

@interface KBTTextStyleGenerator : NSObject
{
@private
    NSString *fontFamily_;
    CGFloat fontSize_;
    BOOL boldTraitEnabled_;
    BOOL italicTraitEnabled_;
    
    BOOL textUnderlined_;
}

#pragma mark Initializing

+ (id)textStyleGenerator;

#pragma mark Configuring the Font

@property (nonatomic, copy) NSString *fontFamily;
@property (nonatomic) CGFloat fontSize;
@property (nonatomic) BOOL boldTraitEnabled;
@property (nonatomic) BOOL italicTraitEnabled;

#pragma mark Configuring the Text

@property (nonatomic) BOOL textUnderlined;

#pragma mark Generating the Text Style

- (NSDictionary *)currentTextStyleAttributes;

@end
