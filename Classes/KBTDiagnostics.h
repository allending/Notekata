//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaCore.h"
#import <CoreText/CoreText.h>

#pragma mark Attributed String Attributes

void KBTEnumerateAttributedStringAttributes(NSAttributedString *attributedString, NSArray **ranges, NSArray **attributes, BOOL coalesceRanges);
NSString *KBTDebugDescriptionForAttributedString(NSAttributedString *attributedString, BOOL coalesceRanges);

NSString *KBTStringFromUITextDirection(UITextDirection direction);
NSString *KBTStringFromUITextGranularity(UITextGranularity granularity);
