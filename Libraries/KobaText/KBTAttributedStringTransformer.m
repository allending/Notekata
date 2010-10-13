//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KBTAttributedStringTransformer.h"
#import "CJSONDataSerializer.h"
#import "CJSONDeserializer.h"
#import "KBTAttributedStringIntermediate.h"

@implementation KBTAttributedStringTransformer

#pragma mark -
#pragma mark Getting Transformer Information

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

+ (Class)transformedValueClass
{
    return [NSData class];
}

#pragma mark -
#pragma mark Transforming Values

- (id)transformedValue:(id)value
{
    NSAttributedString *attributedString = (NSAttributedString *)value;
    KBTAttributedStringIntermediate *intermediate = [KBTAttributedStringIntermediate attributedStringIntermediateWithAttributedString:attributedString];
    NSDictionary *portableRepresentation = [intermediate portableRepresentation];
    NSError *error = nil;
    NSData *data = [[CJSONDataSerializer serializer] serializeDictionary:portableRepresentation error:&error];    

    if (error != nil)
    {
        // TODO: handle properly
        KBCLogWarning(@"%@", [error description]);
        abort();
    }
    
    return data;
}

- (id)reverseTransformedValue:(id)value
{
    NSData *data = (NSData *)value;
    NSError *error = nil;
    NSDictionary *portableRepresentation = [[CJSONDeserializer deserializer] deserialize:data error:&error];
    
    if (error != nil)
    {
        // TODO: handle properly
        KBCLogWarning(@"%@", [error description]);
        abort();
    }
    
    KBTAttributedStringIntermediate *intermediate = [KBTAttributedStringIntermediate attributedStringIntermediateWithPortableRepresentation:portableRepresentation];
    return [intermediate attributedString];
}

@end
