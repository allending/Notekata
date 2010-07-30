//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NKTTextView : UIScrollView {

}

#pragma mark -
#pragma mark Managing Text

@property (nonatomic, readwrite, copy) NSAttributedString *text;

#pragma mark -
#pragma mark Managing Text Layout

@property (nonatomic, readwrite) CGFloat lineHeight;
@property (nonatomic, readwrite) UIEdgeInsets margins;

@end
