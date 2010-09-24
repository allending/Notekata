//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaUI.h"

typedef enum
{
    NKTLoupeStyleBand,
    NKTLoupeStyleRound
} NKTLoupeStyle;     

//--------------------------------------------------------------------------------------------------
// NKTLoupe implements a view with 'magnifying glass' behavior. It is useful for presenting regions
// of views that may be hidden under the user's touch location.
//--------------------------------------------------------------------------------------------------

@interface NKTLoupe : UIView
{
@private
    UIImage *maskData_;
    UIImage *overlay_;
    CGImageRef mask_;
    
    CGPoint anchor_;
    CGPoint anchorOffset_;
    
    UIView *zoomedView_;
    CGPoint zoomCenter_;
    CGFloat inverseZoomScale_;
    
    UIColor *fillColor_;
}

#pragma mark Initializing

- (id)initWithStyle:(NKTLoupeStyle)style;

#pragma mark Anchoring

@property (nonatomic) CGPoint anchor;

#pragma mark Zooming

@property (nonatomic, assign) UIView *zoomedView;
@property (nonatomic) CGPoint zoomCenter;
@property (nonatomic) CGFloat zoomScale;

#pragma mark Setting the Fill Color

@property (nonatomic, retain) UIColor *fillColor;

#pragma mark Displaying

- (void)setHidden:(BOOL)hidden animated:(BOOL)animated;

@end
