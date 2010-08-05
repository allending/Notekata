//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import <UIKit/UIKit.h>

// TODO: should really really tile up text frames

@class NKTTextViewCore;

@interface NKTTextView : UIScrollView {
@private
    NKTTextViewCore *textViewCore;
}

#pragma mark -
#pragma mark Accessing Text

@property (nonatomic, readwrite, copy) NSAttributedString *text;

#pragma mark -
#pragma mark Configuring Text Layout

@property (nonatomic, readwrite) CGFloat lineHeight;
@property (nonatomic, readwrite) UIEdgeInsets margins;

@end
