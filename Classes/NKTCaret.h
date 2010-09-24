//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaUI.h"

//--------------------------------------------------------------------------------------------------
// NKTCaret marks a text position in a text view.
//--------------------------------------------------------------------------------------------------

@interface NKTCaret : UIView
{
@private
    BOOL blinkingEnabled_;
}

#pragma mark Controlling Blinking

@property (nonatomic, getter = isBlinkingEnabled) BOOL blinkingEnabled;

- (void)restartBlinking;

@end
