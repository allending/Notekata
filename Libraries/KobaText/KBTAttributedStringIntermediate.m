//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KBTAttributedStringIntermediate.h"
#import <CoreText/CoreText.h>
#import "KBTStyleDescriptor.h"
#import "CJSONSerializer.h"
#import "CJSONDeserializer.h"

@implementation KBTAttributedStringIntermediate

static NSString *StringKey = @"String";
static NSString *StylesKey = @"Styles";
static NSString *StyleRangesKey = @"StyleRanges";

#pragma mark -
#pragma mark Initializing

- (id)initWithAttributedString:(NSAttributedString *)attributedString
{
    if ((self = [super init]))
    {
        string_ = [[attributedString string] copy];
        
        // Enumerate and serialize the styles
        NSMutableArray *styles = [[NSMutableArray array] retain];
        NSMutableArray *styleRanges = [[NSMutableArray array] retain];
        NSUInteger index = 0;
        NSUInteger length = [attributedString length];
        NSRange entireRange = NSMakeRange(0, length);
        
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
        
        // Create dictionary with style information and JSONize
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:styles, StylesKey,
                                                                              styleRanges, StyleRangesKey,
                                                                              nil];
        [styles release];
        [styleRanges release];
        
        NSError *error = nil;
        styleString_ = [[[CJSONSerializer serializer] serializeDictionary:dictionary error:&error] retain];
        
        if (error != nil)
        {
            // TODO: FIX and LOG
            KBCLogWarning(@"While serializing JSON data, Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    
    return self;
}

- (id)initWithString:(NSString *)string styleString:(NSString *)styleString
{
    if ((self = [super init]))
    {
        string_ = [string copy];
        styleString_ = [styleString copy];
    }
    
    return self;
}

+ (id)attributedStringIntermediateWithAttributedString:(NSAttributedString *)attributedString
{
    return [[[self alloc] initWithAttributedString:attributedString] autorelease];
}

+ (id)attributedStringIntermediateWithString:(NSString *)string styleString:(NSString *)styleString
{
    return [[[self alloc] initWithString:string styleString:styleString] autorelease];
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc
{
    [string_ release];
    [styleString_ release];
    [super dealloc];
}

#pragma mark -
#pragma mark Getting Representations

- (NSAttributedString *)attributedString
{
    NSMutableAttributedString *attributedString = [[[NSMutableAttributedString alloc] initWithString:string_] autorelease];
    
    if ([styleString_ length] > 0)
    {
        NSError *error = nil;
        NSDictionary *dictionary = [[CJSONDeserializer deserializer] deserializeAsDictionary:[styleString_ dataUsingEncoding:NSUTF8StringEncoding]
                                                                                       error:&error];
        
        if (error != nil)
        {
            // TODO: FIX and LOG
            KBCLogWarning(@"While deserializing JSON data, Unresolved error %@, %@", error, [error userInfo]);
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

- (NSString *)string
{
    return string_;
}

- (NSString *)styleString
{
    return styleString_;
}

@end
