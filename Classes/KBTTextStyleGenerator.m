//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KBTTextStyleGenerator.h"

@implementation KBTTextStyleGenerator

@synthesize fontFamily = fontFamily_;
@synthesize fontSize = fontSize_;
@synthesize boldTraitEnabled = boldTraitEnabled_;
@synthesize italicTraitEnabled = italicTraitEnabled_;
@synthesize textUnderlined = textUnderlined_;

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

+ (id)textStyleGenerator
{
    return [[[self alloc] init] autorelease];
}

- (void)dealloc
{
    [fontFamily_ release];
    [super dealloc];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Configuring the Font

- (NSDictionary *)currentTextStyleAttributes
{
    CTFontSymbolicTraits symbolicTraits = 0;
    
    if (boldTraitEnabled_)
    {
        symbolicTraits |= kCTFontBoldTrait;
    }
    
    if (italicTraitEnabled_)
    {
        symbolicTraits |= kCTFontItalicTrait;
    }

    NSDictionary *traitAttributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:symbolicTraits] forKey:(id)kCTFontSymbolicTrait];
    NSDictionary *fontAttributes = [NSDictionary dictionaryWithObjectsAndKeys:traitAttributes, (id)kCTFontTraitsAttribute,
                                                                              fontFamily_, (id)kCTFontFamilyNameAttribute,
                                                                              nil];
    CTFontDescriptorRef fontDescriptor = CTFontDescriptorCreateWithAttributes((CFDictionaryRef)fontAttributes);
    CTFontRef font = CTFontCreateWithFontDescriptor(fontDescriptor, fontSize_, NULL);
    
    // query the font - make sure it is in the same family -> else fall back
    
    CFRelease(fontDescriptor);
    
    CTUnderlineStyle underlineStyle = textUnderlined_ ? kCTUnderlineStyleSingle : kCTUnderlineStyleNone;
    NSDictionary *textStyleAttributes = [NSDictionary dictionaryWithObjectsAndKeys:(id)font, (id)kCTFontAttributeName,
                                                                                    [NSNumber numberWithInt:underlineStyle], (id)kCTUnderlineStyleAttributeName,
                                                                                    nil];
    return textStyleAttributes;
}

@end
