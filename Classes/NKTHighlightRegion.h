//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaUI.h"

// NKTHighlightRegion
//
@interface NKTHighlightRegion : UIView
{
@private
    NSArray *rects_;
    BOOL coalescesRects_;
    BOOL fillsRects_;
    BOOL strokesRects_;
    UIColor *fillColor_;
    UIColor *strokeColor_;
}

#pragma mark Managing the Region's Rects

@property (nonatomic, copy) NSArray *rects;

#pragma mark Configuring the Style

@property (nonatomic) BOOL coalescesRects;
@property (nonatomic) BOOL fillsRects;
@property (nonatomic) BOOL strokesRects;
@property (nonatomic, retain) UIColor *fillColor;
@property (nonatomic, retain) UIColor *strokeColor;

@end
