//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaCore.h"

@class NKTTextView;

//--------------------------------------------------------------------------------------------------
// Internal class used by NKTTextView as the delegate for the gesture recognizers it creates. The
// reason this class exists is because implementing the UIGestureRecognizerDelegate protocol
// directly NKTTextView conflicts with UIScrollView's behavior.
//--------------------------------------------------------------------------------------------------

@interface NKTTextViewGestureRecognizerDelegate : NSObject <UIGestureRecognizerDelegate>
{
@private
    NKTTextView *textView_;
}

#pragma mark Initializing

- (id)initWithTextView:(NKTTextView *)textView;

@end
