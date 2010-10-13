//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KobaCore.h"

// KBTAttributedStringTransformer is a subclass of NSValueTransformer that transforms NSAttributedStrings to and from
// NSData objects. It uses the KBTAttributedStringIntermediate class to provide a portable representation of the
// attributed string which is then used to create the NSData object.
@interface KBTAttributedStringTransformer : NSValueTransformer
{
}

@end
