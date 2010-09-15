//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

@interface KBTTextStyleGenerator : NSObject

+ (id)textStyleGenerator;

@property (nonatomic) BOOL underlined;

@property (nonatomic) CTFontRef font;

- (NSDictionary *)textAttributes;

@end
