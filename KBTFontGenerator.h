//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

@interface KBTFontGenerator : NSObject

#pragma mark Initializing

+ (id)fontGenerator;

#pragma mark Configuring the Font

@property (nonatomic, copy) NSString *fontFamily;
@property (nonatomic) CGFloat fontSize;

@property (nonatomic) BOOL boldTraitEnabled;
@property (nonatomic) BOOL italicTraitEnabled;

- (CTFontRef)bestFont;

@end
