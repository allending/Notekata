//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KobaCore.h"

// NSAttributedStrings as used in Core Text may have attributes embedded in them which are non-serializable in general
// because the associated attributes may be Core Text objects such as CTFonts (which do not support NSCoding).
// KBTAttributedStringIntermediate is an intermediate form that allows for simple conversions between
// NSAttributedStrings and portable NSDictionary representations. This is only true for attributed strings that contain
// attributes that the Koba Text library understands.
@interface KBTAttributedStringIntermediate : NSObject
{
@private
    NSString *string_;
    NSString *styleString_;
}

#pragma mark Initializing

- (id)initWithAttributedString:(NSAttributedString *)attributedString;
- (id)initWithString:(NSString *)string styleString:(NSString *)styleString;

+ (id)attributedStringIntermediateWithAttributedString:(NSAttributedString *)attributedString;
+ (id)attributedStringIntermediateWithString:(NSString *)string styleString:(NSString *)styleString;

#pragma mark Getting Representations

- (NSAttributedString *)attributedString;
- (NSString *)string;
- (NSString *)styleString;

@end
