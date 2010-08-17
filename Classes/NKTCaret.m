//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTCaret.h"

@implementation NKTCaret

#pragma mark -
#pragma mark Initializing

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor blueColor];
    }
    
    return self;
}

- (void)dealloc {
    [super dealloc];
}

#pragma mark -
#pragma mark Managing Blinking

- (void)restartBlinking {
    self.alpha = 1.0;
    [UIView beginAnimations:@"NKTCaret" context:nil];
    [UIView setAnimationRepeatCount:CGFLOAT_MAX];
    [UIView setAnimationDuration:0.8];
    self.alpha = 0.0;
    [UIView commitAnimations];
}

- (void)stopBlinking {
    // This cancels pending animations on alpha
    self.alpha = 1.0;
}

@end
