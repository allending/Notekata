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

#pragma mark Controlling Simultaneous Gesture Recognition

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint touchLocation = [gestureRecognizer locationInView:textView];
    UIView *hitView = [textView hitTest:touchLocation withEvent:nil];
    
    // The text view's gesture recognizers are only allowed to recognize the gesture if the text view
    // is the hit view (not its subviews e.g. the UITextInput autocorrection prompt).
    if (hitView != textView)
    {
        return NO;
    }
    
    if (gestureRecognizer == textView.tapGestureRecognizer)
    {
        return [textView isFirstResponder];
    }
    else if (gestureRecognizer == textView.nonEditTapGestureRecognizer)
    {
        return ![textView isFirstResponder];
    }
    else
    {
        return YES;
    }
}

@end
