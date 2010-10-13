//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KBCGestures.h"

NSString *KBCStringForGestureRecognizerState(UIGestureRecognizerState state)
{
    switch (state)
    {
    case UIGestureRecognizerStatePossible:
        return @"UIGestureRecognizerStatePossible";
    case UIGestureRecognizerStateBegan:
        return @"UIGestureRecognizerStateBegan";
    case UIGestureRecognizerStateChanged:
        return @"UIGestureRecognizerStateChanged";
    case UIGestureRecognizerStateCancelled:
        return @"UIGestureRecognizerStateCancelled";
    case UIGestureRecognizerStateFailed:
        return @"UIGestureRecognizerStateFailed";
    case UIGestureRecognizerStateRecognized:
        return @"UIGestureRecognizerStateRecognized";
    default:
        return nil;
    }
}
