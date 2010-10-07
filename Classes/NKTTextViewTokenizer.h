//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaUI.h"

@class NKTTextView;

// NKTTextViewTokenizer is the tokenizer used by NKTTextView's implementation of the UITextInput
// protocol.
//
@interface NKTTextViewTokenizer : UITextInputStringTokenizer 
{
@private
    NKTTextView *textView_;
}

#pragma mark Initializing

- (id)initWithTextView:(NKTTextView *)textView;

@end
