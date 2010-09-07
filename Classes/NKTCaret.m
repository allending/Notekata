//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTCaret.h"

@implementation NKTCaret

@synthesize blinkingEnabled;

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        self.backgroundColor = [UIColor blueColor];
        self.userInteractionEnabled = NO;
        blinkingEnabled = YES;
        [self restartBlinking];
    }
    
    return self;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Controlling Blinking

- (void)setBlinkingEnabled:(BOOL)blinkingEnabledFlag
{
    if (blinkingEnabled == blinkingEnabledFlag)
    {
        return;
    }
    
    blinkingEnabled = blinkingEnabledFlag;
    
    // Not blinking => blinking
    if (blinkingEnabled)
    {
        [self restartBlinking];
    }
    // Blinking => not blinking
    else
    {
        self.alpha = 1.0;
    }
}

- (void)restartBlinking
{
    if (!self.isBlinkingEnabled)
    {
        return;
    }
    
    self.alpha = 1.0;
    [UIView beginAnimations:@"NKTCaret" context:nil];
    [UIView setAnimationRepeatCount:CGFLOAT_MAX];
    [UIView setAnimationDuration:0.875];
    self.alpha = 0.0;
    [UIView commitAnimations];
}

@end
