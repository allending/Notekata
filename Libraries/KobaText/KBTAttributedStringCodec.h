//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KobaCore.h"

@interface KBTAttributedStringCodec : NSObject

#pragma mark Getting Representations

+ (NSData *)dataWithAttributedString:(NSAttributedString *)attributedString;

+ (NSAttributedString *)attributedStringWithData:(NSData *)data;

@end
