//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

//--------------------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------------------------------------

@interface NKTBandLoupe : UIView
{
@private
    UIImage *maskSourceImage;
    UIImage *overlayImage;
    CGImageRef mask;
}

#pragma mark Initializing

- (id)init;

#pragma mark Anchoring Loupes

@property (nonatomic, readwrite) CGPoint anchor;

@end
