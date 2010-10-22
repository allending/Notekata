//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KBTAttributedStringCodec.h"
#import "CJSONDataSerializer.h"
#import "CJSONDeserializer.h"
#import "CJSONSerializer.h"
#import "KBTStyleDescriptor.h"

@implementation KBTAttributedStringCodec

static NSString *StringKey = @"String";
static NSString *StylesKey = @"Styles";
static NSString *StyleRangesKey = @"StyleRanges";

#pragma mark -
#pragma mark Getting Representations

+ (void)getStyles:(NSArray **)outStyles styleRanges:(NSArray **)outStyleRanges forAttributedString:(NSAttributedString *)attributedString
{
    NSMutableArray *styles = [[[NSMutableArray alloc] init] autorelease];
    NSMutableArray *styleRanges = [[[NSMutableArray alloc] init] autorelease];
    NSUInteger index = 0;
    NSUInteger length = [attributedString length];
    NSRange entireRange = NSMakeRange(0, length);
    
    // Extract styles
    while (index < length)
    {
        NSRange effectiveRange = NSMakeRange(NSNotFound, 0);
        NSDictionary *attributes = [attributedString attributesAtIndex:index
                                                 longestEffectiveRange:&effectiveRange
                                                               inRange:entireRange];
        KBTStyleDescriptor *descriptor = [KBTStyleDescriptor styleDescriptorWithCoreTextAttributes:attributes];
        [styles addObject:[descriptor portableRepresentation]];
        [styleRanges addObject:KBCPortableRepresentationFromRange(effectiveRange)];
        index = effectiveRange.location + effectiveRange.length;
    }
    
    *outStyles = styles;
    *outStyleRanges = styleRanges;
}

+ (NSString *)styleStringForAttributedString:(NSAttributedString *)attributedString
{
    NSArray *styles = nil;
    NSArray *styleRanges = nil;
    [self getStyles:&styles styleRanges:&styleRanges forAttributedString:attributedString];
    // Create dictionary with style information and JSONize
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        styles, StylesKey,
        styleRanges, StyleRangesKey,
        nil];
    
    NSError *error = nil;
    NSString *styleString = (NSString *)[[CJSONSerializer serializer] serializeDictionary:dictionary error:&error];
    
    if (error != nil)
    {
        // PENDING: fix and log
        KBCLogWarning(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return styleString;
}

+ (NSData *)dataWithAttributedString:(NSAttributedString *)attributedString
{
    NSString *string = [attributedString string];
    NSArray *styles = nil;
    NSArray *styleRanges = nil;
    [self getStyles:&styles styleRanges:&styleRanges forAttributedString:attributedString];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        string, StringKey,
        styles, StylesKey,
        styleRanges, StyleRangesKey,
        nil];
    
    NSError *error = nil;
    NSData *data = (NSData *)[[CJSONDataSerializer serializer] serializeDictionary:dictionary error:&error];
    
    if (error != nil)
    {
        // PENDING: fix and log
        KBCLogWarning(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return data;
}

+ (NSAttributedString *)attributedStringWithData:(NSData *)data
{
    NSError *error = nil;
    NSDictionary *dictionary = [[CJSONDeserializer deserializer] deserialize:data error:&error];
    
    if (error != nil)
    {
        // PENDING: fix and log
        KBCLogWarning(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    NSString *string = [dictionary objectForKey:StringKey];
    NSArray *styles = [dictionary objectForKey:StylesKey];
    NSArray *styleRanges = [dictionary objectForKey:StyleRangesKey];
    NSMutableAttributedString *attributedString = [[[NSMutableAttributedString alloc] initWithString:string] autorelease];
    NSUInteger styleCount = [styles count];
    
    // Apply styles
    for (NSUInteger index = 0; index < styleCount; ++index)
    {
        NSDictionary *style = [styles objectAtIndex:index];
        NSRange styleRange = KBCRangeFromPortableRepresentation([styleRanges objectAtIndex:index]);
        KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithPortableRepresentation:style];
        [attributedString setAttributes:[styleDescriptor coreTextAttributes] range:styleRange];
    }
    
    return attributedString;
}

+ (NSAttributedString *)attributedStringWithString:(NSString *)string styleString:(NSString *)styleString
{
    NSMutableAttributedString *attributedString = [[[NSMutableAttributedString alloc] initWithString:string] autorelease];
    
    if ([styleString length] > 0)
    {
        NSError *error = nil;
        NSDictionary *dictionary = [[CJSONDeserializer deserializer] deserializeAsDictionary:[styleString dataUsingEncoding:NSUTF8StringEncoding] error:&error];
        
        if (error != nil)
        {
            // PENDING: fix and log
            KBCLogWarning(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        
        NSArray *styles = [dictionary objectForKey:StylesKey];
        NSArray *styleRanges = [dictionary objectForKey:StyleRangesKey];
        NSUInteger styleCount = [styles count];
        
        for (NSUInteger index = 0; index < styleCount; ++index)
        {
            NSDictionary *style = [styles objectAtIndex:index];
            NSRange styleRange = KBCRangeFromPortableRepresentation([styleRanges objectAtIndex:index]);
            KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithPortableRepresentation:style];
            [attributedString setAttributes:[styleDescriptor coreTextAttributes] range:styleRange];
        }
    }
    
    return attributedString;
}

@end
