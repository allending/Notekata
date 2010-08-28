//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTDragGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>
#import "NKTGestureRecognizerUtilites.h"

#define NKT_LOGGING_STRIP_DEBUG 1

#import "NKTLogging.h"

@implementation NKTDragGestureRecognizer

@synthesize numberOfTapsRequired;

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (id)initWithTarget:(id)target action:(SEL)action
{
    if ((self = [super initWithTarget:target action:action]))
    {
        numberOfTapsRequired = 2;
    }
    
    return self;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Interacting with Other Gesture Recognizers

- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer
{
    return NO;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Processing Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    if ([touches count] != 1)
    {
        NKTLogDebug(@"(non-failed) -> failed (more than 1 touch began)");
        self.state = UIGestureRecognizerStateFailed;
        return;
    }
    
    // Don't interrupt gestures in progress
    if (self.state != UIGestureRecognizerStatePossible)
    {
        NKTLogDebug(@"touches began while gesture in progress, ignoring");
        return;
    }
    
    UITouch *touch = [touches anyObject];
    
    if (touch.tapCount == numberOfTapsRequired)
    {
        NKTLogDebug(@"possible -> began (tap count met)");
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(abortPossibleGesture) object:nil];
        self.state = UIGestureRecognizerStateBegan;
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    
    if (self.state == UIGestureRecognizerStateBegan)
    {
        NKTLogDebug(@"began -> changed");
        self.state = UIGestureRecognizerStateChanged;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    if (self.state == UIGestureRecognizerStateChanged || self.state == UIGestureRecognizerStateBegan)
    {
        NKTLogDebug(@"(began/changed) -> ended");
        self.state = UIGestureRecognizerStateEnded;
    }
    else if (self.state == UIGestureRecognizerStatePossible)
    {
        NKTLogDebug(@"scheduling gesture expiry");
        [self performSelector:@selector(abortPossibleGesture) withObject:nil afterDelay:0.35];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    
    NKTLogDebug(@"(any) -> cancelled");
    self.state = UIGestureRecognizerStateCancelled;
}

//--------------------------------------------------------------------------------------------------
        
#pragma mark Aborting Possible Gestures

- (void)abortPossibleGesture
{
    if (self.state == UIGestureRecognizerStatePossible)
    {
        NKTLogDebug(@"possible -> failed (time allowance expired)");
        self.state = UIGestureRecognizerStateFailed;
    }
}

@end
