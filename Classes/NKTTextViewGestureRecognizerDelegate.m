//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTTextViewGestureRecognizerDelegate.h"
#import "NKTDragGestureRecognizer.h"
#import "NKTTextRange.h"
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
    CGPoint touchLocation = [gestureRecognizer locationInView:textView];
    UIView *hitView = [textView hitTest:touchLocation withEvent:nil];
    
    // The text view's gesture recognizers are only allowed to recognize the gesture if the text 
    // view is the hit view (not its subviews e.g. the UITextInput autocorrection prompt)
    if (hitView != textView)
    {
        return NO;
    }
    else if (gestureRecognizer == textView.tapGestureRecognizer)
    {
        return [textView isFirstResponder];
    }
    else if (gestureRecognizer == textView.nonEditTapGestureRecognizer)
    {
        return ![textView isFirstResponder];
    }
    // Double tap and drag gesture only allowed when there is no marked text
    else if (gestureRecognizer == textView.doubleTapAndDragGestureRecognizer)
    {
        NKTTextRange *markedTextRange = (NKTTextRange *)textView.markedTextRange;
        return (markedTextRange == nil || markedTextRange.isEmpty);
    }
    else
    {
        return YES;
    }
}

@end
