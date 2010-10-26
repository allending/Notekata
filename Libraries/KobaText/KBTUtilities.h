//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KobaCore.h"

#pragma mark Enumerating String Attributes

void KBTEnumerateAttributedStringAttributes(NSAttributedString *attributedString,
                                            NSArray **ranges,
                                            NSArray **attributes,
                                            BOOL coalesceRanges);

void KBTLightweightEnumerateAttributedStringAttributesInRange(NSAttributedString *attributedString, NSArray **outAttributes, NSRange range);

#pragma mark Getting Strings

NSString *KBTDebugDescriptionForAttributedString(NSAttributedString *attributedString, BOOL coalesceRanges);
NSString *KBTStringFromUITextDirection(UITextDirection direction);
NSString *KBTStringFromUITextGranularity(UITextGranularity granularity);
