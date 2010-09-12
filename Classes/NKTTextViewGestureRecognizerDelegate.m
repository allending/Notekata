//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTTextViewGestureRecognizerDelegate.h"
#import "NKTDragGestureRecognizer.h"
#import "NKTTextRange.h"
#import "NKTTextView.h"

@implementation NKTTextViewGestureRecognizerDelegate

#pragma mark Initializing

- (id)initWithTextView:(NKTTextView *)textView
{
    if ((self = [super init]))
    {
        textView_ = textView;
    }
    
    return self;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Regulating Gesture Recognition

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint touchLocation = [gestureRecognizer locationInView:textView_];
    UIView *hitView = [textView_ hitTest:touchLocation withEvent:nil];
    
    // The text view's gesture recognizers are only allowed to recognize the gesture if the text 
    // view is the hit view (not its subviews e.g. the UITextInput autocorrection prompt)
    if (hitView != textView_)
    {
        return NO;
    }
    else if (gestureRecognizer == textView_.tapGestureRecognizer)
    {
        return [textView_ isFirstResponder];
    }
    else if (gestureRecognizer == textView_.nonEditTapGestureRecognizer)
    {
        return ![textView_ isFirstResponder];
    }
    // Double tap and drag gesture only allowed when there is no marked text
    else if (gestureRecognizer == textView_.doubleTapAndDragGestureRecognizer)
    {
        NKTTextRange *markedTextRange = (NKTTextRange *)textView_.markedTextRange;
        return (markedTextRange == nil || markedTextRange.isEmpty);
    }
    else
    {
        return YES;
    }
}

@end
