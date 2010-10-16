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
@synthesize fillsRects = fillsRects_;
@synthesize strokesRects = strokesRects_;
@synthesize fillColor = fillColor_;
@synthesize strokeColor = strokeColor_;

#pragma mark -
#pragma mark Initializing

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        self.userInteractionEnabled = NO;
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
        self.contentMode = UIViewContentModeRedraw;
        firstRect_ = CGRectNull;
        lastRect_ = CGRectNull;
        fillsRects_ = YES;
        strokesRects_ = YES;
        fillColor_ = [[UIColor colorWithRed:0.58 green:0.61 blue:0.71 alpha:0.25] retain];
        strokeColor_ = [[UIColor colorWithRed:0.58 green:0.61 blue:0.71 alpha:1.0] retain];
    }
    
    return self;
}

- (void)dealloc
{
    [fillColor_ release];
    [strokeColor_ release];
    [super dealloc];
}

#pragma mark -
#pragma mark Setting the View's Frame

- (void)reframe
{
    // Figure out the frame required to fit the rects in
    CGRect newFrame = CGRectUnion(firstRect_, lastRect_);
    // A little extra drawing space to compensate for Quartz's corner addressing
    newFrame.size.width += 2.0;
    newFrame.size.height += 2.0;
    self.frame = newFrame;
    [self setNeedsDisplay];
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

// Region rects are specified in the superview's space
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

- (void)setFillsRects:(BOOL)fillsRects
{
    fillsRects_ = fillsRects;
    [self setNeedsDisplay];
}

- (void)setStrokesRects:(BOOL)strokesRects
{
    strokesRects_ = strokesRects;
    [self setNeedsDisplay];
}

- (void)setFillColor:(UIColor *)fillColor
{
    [fillColor retain];
    [fillColor_ release];
    fillColor_ = fillColor;
    [self setNeedsDisplay];
}

- (void)setStrokeColor:(UIColor *)strokeColor
{
    [strokeColor retain];
    [strokeColor_ release];
    strokeColor_ = strokeColor;
    [self setNeedsDisplay];
}

#pragma mark -
#pragma mark Drawing

- (void)drawRect:(CGRect)drawingRect
{
    if ((!fillsRects_ && !strokesRects_) ||
        (CGRectEqualToRect(firstRect_, CGRectNull) && CGRectEqualToRect(lastRect_, CGRectNull)))
    {
        return;
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    // Move back into superview space because rects were specified in superview space
    const CGFloat quantizationFudge = 1.0;
    CGContextTranslateCTM(context, -self.frame.origin.x, -self.frame.origin.y + quantizationFudge);
    CGContextSetShouldAntialias(context, NO);
    CGContextSetLineWidth(context, 1.0);
    CGContextSetStrokeColorWithColor(context, strokeColor_.CGColor);
    CGContextSetFillColorWithColor(context, fillColor_.CGColor);
    
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, CGRectGetMinX(firstRect_), CGRectGetMinY(firstRect_));
    CGContextAddLineToPoint(context, CGRectGetMaxX(firstRect_), CGRectGetMinY(firstRect_));
    CGContextAddLineToPoint(context, CGRectGetMaxX(firstRect_), CGRectGetMinY(lastRect_));
    CGContextAddLineToPoint(context, CGRectGetMaxX(lastRect_), CGRectGetMinY(lastRect_));
    CGContextAddLineToPoint(context, CGRectGetMaxX(lastRect_), CGRectGetMaxY(lastRect_));
    CGContextAddLineToPoint(context, CGRectGetMinX(lastRect_), CGRectGetMaxY(lastRect_));
    CGContextAddLineToPoint(context, CGRectGetMinX(lastRect_), CGRectGetMaxY(firstRect_));
    CGContextAddLineToPoint(context, CGRectGetMinX(firstRect_), CGRectGetMaxY(firstRect_));
    CGContextAddLineToPoint(context, CGRectGetMinX(firstRect_), CGRectGetMinY(firstRect_));
    CGContextClosePath(context);
    
    // Draw path with the desired mode
    if (fillsRects_ && strokesRects_)
    {
        CGContextDrawPath(context, kCGPathFillStroke);
    }
    else if (fillsRects_ && !strokesRects_)
    {
        CGContextDrawPath(context, kCGPathFill);
    }
    else if (!fillsRects_ && strokesRects_)
    {
        CGContextDrawPath(context, kCGPathStroke);
    }
}

@end
