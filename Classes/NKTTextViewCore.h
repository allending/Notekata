//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NKTTextViewCore : UIView {

}

#pragma mark -
#pragma mark Managing Text

@property (nonatomic, readwrite, copy) NSAttributedString *text;

#pragma mark -
#pragma mark Managing Text Layout

@property (nonatomic, readwrite) CGFloat contentWidth;
@property (nonatomic, readwrite) CGFloat lineHeight;
@property (nonatomic, readwrite) UIEdgeInsets margins;
@property (nonatomic, readonly) CGSize suggestedFrameSize;

@end
