//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTTextViewGestureRecognizerDelegate.h"
#import "NKTTextView.h"

@implementation NKTTextViewGestureRecognizerDelegate

#pragma mark Initializing

- (id)initWithTextView:(NKTTextView *)theTextView
{
    if ((self = [super init]))
    {
        textView = theTextView;
    }
    
    return self;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Regulating Gesture Recognition

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    // todo: must hit a text section
    if (gestureRecognizer == textView.tapGestureRecognizer)
    {
        return [textView isFirstResponder];
    }
    else if (gestureRecognizer == textView.preFirstResponderTapGestureRecognizer)
    {
        return ![textView isFirstResponder];
    }
    else
    {
        return YES;
    }
}

@end
