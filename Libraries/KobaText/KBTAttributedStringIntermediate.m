//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KBTAttributedStringIntermediate.h"
#import <CoreText/CoreText.h>
#import "KBTStyleDescriptor.h"

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
        string_ = [[attributedString string] retain];
        styles_ = [[NSMutableArray array] retain];
        styleRanges_ = [[NSMutableArray array] retain];
        
        // Populate the styles and style ranges
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
            [styles_ addObject:[descriptor portableRepresentation]];
            [styleRanges_ addObject:KBCPortableRepresentationFromRange(effectiveRange)];
            index = effectiveRange.location + effectiveRange.length;
        }
    }
    
    return self;
}

- (id)initWithPortableRepresentation:(NSDictionary *)portableRepresentation
{
    if ((self = [super init]))
    {
        string_ = [[portableRepresentation objectForKey:StringKey] retain];
        styles_ = [[portableRepresentation objectForKey:StylesKey] retain];
        styleRanges_ = [[portableRepresentation objectForKey:StyleRangesKey] retain];
    }
    
    return self;
}

+ (id)attributedStringIntermediateWithAttributedString:(NSAttributedString *)attributedString
{
    return [[[self alloc] initWithAttributedString:attributedString] autorelease];
}

+ (id)attributedStringIntermediateWithPortableRepresentation:(NSDictionary *)interchangeRepresentation
{
    return [[[self alloc] initWithPortableRepresentation:interchangeRepresentation] autorelease];
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc
{
    [string_ release];
    [styles_ release];
    [styleRanges_ release];
    [super dealloc];
}

#pragma mark -
#pragma mark Getting Representations

- (NSDictionary *)portableRepresentation
{
    return [NSDictionary dictionaryWithObjectsAndKeys:string_, StringKey,
                                                      styles_, StylesKey,
                                                      styleRanges_, StyleRangesKey,
                                                      nil];
}

- (NSAttributedString *)attributedString
{
    NSMutableAttributedString *string = [[[NSMutableAttributedString alloc] initWithString:string_] autorelease];
    NSUInteger styleCount = [styles_ count];
    
    for (NSUInteger index = 0; index < styleCount; ++index)
    {
        NSDictionary *style = [styles_ objectAtIndex:index];
        NSRange styleRange = KBCRangeFromPortableRepresentation([styleRanges_ objectAtIndex:index]);
        KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithPortableRepresentation:style];
        [string setAttributes:[styleDescriptor coreTextAttributes] range:styleRange];
    }
    
    return string;
}

@end
