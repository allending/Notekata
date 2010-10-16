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
    UIView *topFillView_;
    UIView *middleFillView_;
    UIView *bottomFillView_;
}

#pragma mark Accessing Rects

@property (nonatomic) CGRect firstRect;
@property (nonatomic) CGRect lastRect;

#pragma mark Configuring the Style

@property (nonatomic, retain) UIColor *fillColor;

@end
