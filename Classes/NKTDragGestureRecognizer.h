//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaCore.h"

//--------------------------------------------------------------------------------------------------
// NKTDragGestureRecognizer is a gesture recognizer subclass that detects tap to drag gestures.
//--------------------------------------------------------------------------------------------------

@interface NKTDragGestureRecognizer : UIGestureRecognizer
{
@private
    NSUInteger numberOfTapsRequired;
}

#pragma mark Configuring the Gesture

// The default numberOfTapsRequired is 2.
@property (nonatomic, readwrite) NSUInteger numberOfTapsRequired;

@end
