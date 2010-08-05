//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NKTTextFrame;

@interface NKTTextViewCore : UIView {
@private
    NSAttributedString *text;
    
    CGFloat contentWidth;
    CGFloat lineHeight;
    UIEdgeInsets margins;
    
    NKTTextFrame *textFrame;
}

#pragma mark -
#pragma mark Accessing Text

@property (nonatomic, readwrite, copy) NSAttributedString *text;

#pragma mark -
#pragma mark Configuring Text Layout

@property (nonatomic, readwrite) CGFloat contentWidth;
@property (nonatomic, readwrite) CGFloat lineHeight;
@property (nonatomic, readwrite) UIEdgeInsets margins;

#pragma mark -
#pragma mark Getting Frame Metrics

@property (nonatomic, readonly) CGSize suggestedFrameSize;

@end
