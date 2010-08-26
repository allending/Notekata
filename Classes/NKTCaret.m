//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTCaret.h"

@implementation NKTCaret

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        self.backgroundColor = [UIColor blueColor];
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Managing Blinking

- (void)startBlinking
{
    self.alpha = 1.0;
    [UIView beginAnimations:@"NKTCaret" context:nil];
    [UIView setAnimationRepeatCount:CGFLOAT_MAX];
    [UIView setAnimationDuration:0.85];
    self.alpha = 0.0;
    [UIView commitAnimations];
}

@end
