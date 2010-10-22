//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KobaCore.h"

@interface KBTAttributedStringCodec : NSObject

#pragma mark Getting Representations

+ (void)getStyles:(NSArray **)outStyles styleRanges:(NSArray **)outStyleRanges forAttributedString:(NSAttributedString *)attributedString;

+ (NSString *)styleStringForAttributedString:(NSAttributedString *)attributedString;

+ (NSData *)dataWithAttributedString:(NSAttributedString *)attributedString;

+ (NSAttributedString *)attributedStringWithData:(NSData *)data;

+ (NSAttributedString *)attributedStringWithString:(NSString *)string styleString:(NSString *)styleString;

@end
