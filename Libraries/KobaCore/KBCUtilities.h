//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import <UIKit/UIKit.h>

#pragma mark Working with Ranges

CFRange CFRangeFromNSRange(NSRange range);

NSDictionary *KBCPortableRepresentationFromRange(NSRange range);
NSRange KBCRangeFromPortableRepresentation(NSDictionary *portableRepresentation);
