//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KUIToggleButton.h"

@implementation KUIToggleButton

#pragma mark Initializing

- (id)initWithStyle:(KUIToggleButtonStyle)style
{
    if ((self = [super initWithFrame:CGRectZero]))
    {
        switch (style)
        {
            case KUIToggleButtonStyleTextDark:
                [self setTitleColor:[UIColor colorWithRed:0.12 green:0.57 blue:0.92 alpha:1.0] forState:UIControlStateHighlighted|UIControlStateNormal];
                [self setTitleColor:[UIColor colorWithRed:0.12 green:0.57 blue:0.92 alpha:1.0] forState:UIControlStateHighlighted|UIControlStateSelected];
                [self setTitleColor:[UIColor colorWithRed:0.1 green:0.5 blue:0.9 alpha:1.0] forState:UIControlStateSelected];
                [self setTitleColor:[UIColor lightTextColor] forState:UIControlStateNormal];
                [self setTitleColor:[UIColor darkGrayColor] forState:UIControlStateDisabled|UIControlStateNormal];
                [self setTitleColor:[UIColor darkGrayColor] forState:UIControlStateDisabled|UIControlStateSelected];
                break;
            default:
                break;
        }
    }
    
    return self;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Configuring the Button Title

- (NSString *)title
{
    return [self titleForState:UIControlStateNormal];
}

- (void)setTitle:(NSString *)title
{
    [self setTitle:title forState:UIControlStateNormal];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Responding to Touch Events

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    BOOL toggleSelectionState = (self.state & UIControlStateHighlighted);
    
    if (toggleSelectionState)
    {
        self.selected = !self.selected;
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

@end
