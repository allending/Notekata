//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTHandle.h"

@implementation NKTHandle

#pragma mark Initializing

- (id)initWithStyle:(NKTHandleStyle)style
{
    if ((self = [super initWithFrame:CGRectZero]))
    {
        self.backgroundColor = [UIColor blueColor];
        self.userInteractionEnabled = YES;
        self.autoresizesSubviews = NO;
        style_ = style;
        UIImage *handleTipImage = [UIImage imageNamed:@"CaretHandle.png"];
        handleTip_ = [[UIImageView alloc] initWithImage:handleTipImage];
        handleTip_.userInteractionEnabled = YES;
        [self addSubview:handleTip_];
    }
    
    return self;
}

- (void)dealloc
{
    [handleTip_ release];
    [super dealloc];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Laying Out Views

- (void)layoutSubviews
{
    // PENDING: unmagic constant this code
    if (style_ == NKTHandleStyleTopTip)
    {
        handleTip_.center = CGPointMake(self.bounds.size.width * 0.5, -3.0);
    }
    else
    {
        handleTip_.center = CGPointMake(self.bounds.size.width * 0.5, self.bounds.size.height + 8.0);
    }
}

//--------------------------------------------------------------------------------------------------

#pragma mark Hit-Testing

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (!self.userInteractionEnabled || self.hidden || self.alpha < 0.01)
    {
        return nil;
    }
    
    // Attempt to hit test the tip first
    CGPoint tipLocalPoint = [self convertPoint:point toView:handleTip_];
    UIView *view = [handleTip_ hitTest:tipLocalPoint withEvent:event];
    
    if (view != nil)
    {
        return self;
    }
    
    CGRect hitTestRect = self.bounds;
    hitTestRect.origin.x = -16.0;
    hitTestRect.size.width += 30.0;
    
    if (CGRectContainsPoint(hitTestRect, point))
    {
        return self;
    }
    
    return nil;
}

@end
