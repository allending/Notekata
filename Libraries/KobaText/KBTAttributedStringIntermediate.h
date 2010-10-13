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
    NSMutableArray *styles_;
    NSMutableArray *styleRanges_;
}

#pragma mark Initializing

// Note that the attributed string is retained for efficiency, and should be truly non-mutable.
- (id)initWithAttributedString:(NSAttributedString *)attributedString;
- (id)initWithPortableRepresentation:(NSDictionary *)interchangeRepresentation;

+ (id)attributedStringIntermediateWithAttributedString:(NSAttributedString *)attributedString;
+ (id)attributedStringIntermediateWithPortableRepresentation:(NSDictionary *)interchangeRepresentation;

#pragma mark Getting Representations

- (NSDictionary *)portableRepresentation;
- (NSAttributedString *)attributedString;

@end
