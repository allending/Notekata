//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KobaUI.h"

// NKTSelectedTextRegion represents a selected highlight region for text.
@interface NKTSelectedTextRegion : UIView
{
@private
    CGRect firstRect_;
    CGRect lastRect_;
    BOOL fillsRects_;
    BOOL strokesRects_;
    UIColor *fillColor_;
    UIColor *strokeColor_;
}

#pragma mark Accessing Rects

@property (nonatomic) CGRect firstRect;
@property (nonatomic) CGRect lastRect;

#pragma mark Configuring the Style

@property (nonatomic) BOOL fillsRects;
@property (nonatomic) BOOL strokesRects;
@property (nonatomic, retain) UIColor *fillColor;
@property (nonatomic, retain) UIColor *strokeColor;

@end
