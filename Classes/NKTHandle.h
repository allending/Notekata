//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaUI.h"

typedef enum
{
    NKTHandleStyleTopTip,
    NKTHandleStyleBottomTip
} NKTHandleStyle;

// NKTHandle displays a non-blinking caret with a tip that is can be used for representing user
// modifiable text selections.
@interface NKTHandle : UIView
{
@private
    NKTHandleStyle style_;
    UIImageView *handleTip_;
}

#pragma mark Initializing

- (id)initWithStyle:(NKTHandleStyle)style;

@end
