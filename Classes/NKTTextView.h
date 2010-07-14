//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NKTTextView : UIView {

}

#pragma mark -
#pragma mark Managing the Text

@property (nonatomic, readwrite, copy) NSAttributedString *text;

#pragma mark -
#pragma mark Managing Typography

@property (nonatomic, readwrite) UIEdgeInsets textInset;
@property (nonatomic, readwrite) CGFloat lineHeight;

@end
