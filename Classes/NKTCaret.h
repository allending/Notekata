//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaCore.h"

//--------------------------------------------------------------------------------------------------
// NKTCaret visually marks a location in text.
//--------------------------------------------------------------------------------------------------

@interface NKTCaret : UIView
{
@private
    BOOL blinkingEnabled;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Controlling Blinking

@property (nonatomic, readwrite, getter = isBlinkingEnabled) BOOL blinkingEnabled;

- (void)restartBlinking;

@end
