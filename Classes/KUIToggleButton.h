//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaCore.h"

typedef enum
{
    KUIToggleButtonStyleTextDark
} KUIToggleButtonStyle;

//--------------------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------------------------------------

@interface KUIToggleButton : UIButton

#pragma mark Initializing

- (id)initWithStyle:(KUIToggleButtonStyle)style;

#pragma mark Configuring the Button Title

@property (nonatomic, copy) NSString *title;

#pragma mark Configuring the Button Image

@end
