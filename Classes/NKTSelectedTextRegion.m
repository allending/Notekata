//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTSelectedTextRegion.h"

// NKTSelectedTextRegion private interface
@interface NKTSelectedTextRegion()

#pragma mark Setting the View's Frame

- (void)reframe;

@end

@implementation NKTSelectedTextRegion

@synthesize firstRect = firstRect_;
@synthesize lastRect = lastRect_;

#pragma mark -
#pragma mark Initializing

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        self.userInteractionEnabled = NO;
        self.opaque = NO;
        firstRect_ = CGRectNull;
        lastRect_ = CGRectNull;
        
        UIColor *fillColor = [UIColor colorWithRed:0.25 green:0.45 blue:0.9 alpha:0.3];
        
        topFillView_ = [[UIView alloc] init];
        topFillView_.userInteractionEnabled = NO;
        topFillView_.opaque = NO;
        topFillView_.backgroundColor = fillColor;
        topFillView_.hidden = YES;
        [self addSubview:topFillView_];
        
        middleFillView_ = [[UIView alloc] init];
        middleFillView_.userInteractionEnabled = NO;
        middleFillView_.opaque = NO;
        middleFillView_.backgroundColor = fillColor;
        middleFillView_.hidden = YES;
        [self addSubview:middleFillView_];
        
        bottomFillView_ = [[UIView alloc] init];
        bottomFillView_.userInteractionEnabled = NO;
        bottomFillView_.opaque = NO;
        bottomFillView_.backgroundColor = fillColor;
        topFillView_.hidden = YES;
        [self addSubview:bottomFillView_];
    }
    
    return self;
}

- (void)dealloc
{
    [topFillView_ release];
    [middleFillView_ release];
    [bottomFillView_ release];
    [super dealloc];
}

#pragma mark -
#pragma mark Setting the View's Frame

- (void)reframe
{
    CGRect topRect = firstRect_;
    
    if (!CGRectIsNull(topRect))
    {
        topFillView_.frame = topRect;
        topFillView_.hidden = NO;
    }
    else
    {
        topFillView_.hidden = YES;
    }
    
    CGRect bottomRect = lastRect_;
    
    if (!CGRectEqualToRect(bottomRect, topRect) && !CGRectIsNull(bottomRect))
    {
        bottomFillView_.frame = bottomRect;
        bottomFillView_.hidden = NO;
    }
    else
    {
        bottomFillView_.hidden = YES;
    }
    
    if (!CGRectIsNull(topRect) && !CGRectIsNull(bottomRect) && CGRectGetMaxY(topRect) < CGRectGetMinY(bottomRect))
    {
        CGRect middleRect = CGRectMake(CGRectGetMinX(bottomRect),
                                       CGRectGetMaxY(topRect),
                                       CGRectGetMaxX(topRect) - CGRectGetMinX(bottomRect),
                                       CGRectGetMinY(bottomRect) - CGRectGetMaxY(topRect));
        middleFillView_.frame = middleRect;
        middleFillView_.hidden = NO;
    }
    else
    {
        middleFillView_.hidden = YES;
    }
}

#pragma mark -
#pragma mark Accessing Rects

- (void)setFirstRect:(CGRect)firstRect
{
    if (CGRectEqualToRect(firstRect_, firstRect))
    {
        return;
    }
    
    firstRect_ = firstRect;
    [self reframe];
}

- (void)setLastRect:(CGRect)lastRect
{
    if (CGRectEqualToRect(lastRect_, lastRect))
    {
        return;
    }
    
    lastRect_ = lastRect;
    [self reframe];
}

#pragma mark -
#pragma mark Configuring the Style

- (UIColor *)fillColor
{
    return topFillView_.backgroundColor;
}

- (void)setFillColor:(UIColor *)fillColor
{
    topFillView_.backgroundColor = fillColor;
    middleFillView_.backgroundColor = fillColor;
    bottomFillView_.backgroundColor = fillColor;
}

@end
