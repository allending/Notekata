//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTFramesetter.h"

@implementation NKTFramesetter

#pragma mark Initializing

//--------------------------------------------------------------------------------------------------

- (id)initWithText:(NSAttributedString *)text lineWidth:(CGFloat)lineWidth lineHeight:(CGFloat)lineHeight
{
    if ((self = [super init]))
    {
        text_ = [text retain];
        lineWidth_ = lineWidth;
        lineHeight_ = lineHeight;
    }
    
    return self;
}

- (void)dealloc
{
    [text_ release];
    [super dealloc];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting the Frame Size

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Line Information

//--------------------------------------------------------------------------------------------------

- (NSUInteger)numberOfLines
{
}

@end
