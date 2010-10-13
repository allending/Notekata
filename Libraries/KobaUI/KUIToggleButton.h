//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaCore.h"

typedef enum
{
    KUIToggleButtonStyleTextDark
} KUIToggleButtonStyle;

//--------------------------------------------------------------------------------------------------
// KUIToggleButton
//--------------------------------------------------------------------------------------------------

@interface KUIToggleButton : UIButton

#pragma mark Initializing

- (id)initWithStyle:(KUIToggleButtonStyle)style;

#pragma mark Configuring the Button Title

@property (nonatomic, copy) NSString *title;

@end
