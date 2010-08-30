//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaCore.h"

//--------------------------------------------------------------------------------------------------
// NKTLoupe implements a view with 'magnifying glass' behavior. It is useful for presenting regions
// of views that may be hidden under the user's touch location.
//--------------------------------------------------------------------------------------------------

typedef enum
{
    NKTLoupeStyleBand,
    NKTLoupeStyleRound
} NKTLoupeStyle;     

@interface NKTLoupe : UIView
{
@private
    UIImage *maskData;
    UIImage *overlay;
    CGImageRef mask;
    
    CGPoint anchor;
    CGPoint anchorOffset;
    
    UIView *zoomedView;
    CGPoint zoomCenter;
    CGFloat inverseZoomScale;
}

#pragma mark Initializing

- (id)initWithStyle:(NKTLoupeStyle)style;

#pragma mark Managing the Loupe Anchor

@property (nonatomic, readwrite) CGPoint anchor;

#pragma mark Zooming

@property (nonatomic, readwrite, assign) UIView *zoomedView;
@property (nonatomic, readwrite) CGPoint zoomCenter;
@property (nonatomic, readwrite) CGFloat zoomScale;

#pragma mark Displaying

- (void)setHidden:(BOOL)hidden animated:(BOOL)animated;

@end
