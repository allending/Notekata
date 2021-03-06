//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaUI.h"

// NKTDragGestureRecognizer is a gesture recognizer subclass that detects tap to drag gestures.
@interface NKTDragGestureRecognizer : UIGestureRecognizer
{
@private
    NSUInteger minimumNumberOfTouches_;
    NSUInteger maximumNumberOfTouches_;
}

#pragma mark Configuring the Gesture

@property (nonatomic) NSUInteger minimumNumberOfTouches;
@property (nonatomic) NSUInteger maximumNumberOfTouches;

@end
