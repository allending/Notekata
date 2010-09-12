//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTCaret.h"

@implementation NKTCaret

@synthesize blinkingEnabled = blinkingEnabled_;

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        self.backgroundColor = [UIColor blueColor];
        self.userInteractionEnabled = NO;
        blinkingEnabled_ = YES;
        [self restartBlinking];
    }
    
    return self;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Controlling Blinking

- (void)setBlinkingEnabled:(BOOL)blinkingEnabled
{
    if (!blinkingEnabled_ && blinkingEnabled)
    {
        blinkingEnabled_ = YES;
        [self restartBlinking];
    }
    else if (blinkingEnabled_ && !blinkingEnabled)
    {
        blinkingEnabled_ = NO;
        self.alpha = 1.0;
    }
}

static const CGFloat NKTCaretBlinkPeriodSeconds = 0.875;

- (void)restartBlinking
{
    if (!blinkingEnabled_)
    {
        return;
    }
    
    self.alpha = 1.0;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationRepeatCount:CGFLOAT_MAX];
    [UIView setAnimationDuration:NKTCaretBlinkPeriodSeconds];
    self.alpha = 0.0;
    [UIView commitAnimations];
}

@end
