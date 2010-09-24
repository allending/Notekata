//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KUISegmentedControl.h"

@implementation KUISegmentedControl

#pragma mark Responding to Touch Events

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self sendActionsForControlEvents:UIControlEventTouchDown];
    [super touchesBegan:touches withEvent:event];
}

@end
