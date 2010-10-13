//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTHighlightRegion.h"

@interface NKTHighlightRegion()

#pragma mark Drawing

- (void)addCoalescedRectsToContext:(CGContextRef)context;
- (void)addDisjointedRectsToContext:(CGContextRef)context;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------

@implementation NKTHighlightRegion

@synthesize rects = rects_;
@synthesize coalescesRects = coalescesRects_;
@synthesize fillsRects = fillsRects_;
@synthesize strokesRects = strokesRects_;
@synthesize fillColor = fillColor_;
@synthesize strokeColor = strokeColor_;

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        self.userInteractionEnabled = NO;
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
        coalescesRects_ = NO;
        fillsRects_ = YES;
        strokesRects_ = YES;
        fillColor_ = [[UIColor colorWithRed:0.58 green:0.61 blue:0.71 alpha:0.25] retain];
        strokeColor_ = [[UIColor colorWithRed:0.58 green:0.61 blue:0.71 alpha:1.0] retain];
        
        // White background alternate
        //highlightColor_ = [[UIColor colorWithRed:0.834 green:0.882 blue:0.938 alpha:0.47] retain];
        //borderColor_ = [[UIColor colorWithRed:0.834 green:0.882 blue:0.929 alpha:1.0] retain];
    }
    
    return self;
}

- (void)dealloc
{
    [rects_ release];
    [fillColor_ release];
    [strokeColor_ release];
    [super dealloc];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Managing the Region's Rects

// Region rects are specified in the superview's space
- (void)setRects:(NSArray *)rects
{
    if (rects_ == rects)
    {
        return;
    }
    
    [rects_ release];
    rects_ = [rects copy];

    // Figure out the frame required to fit the rects in
    
    CGRect newFrame = CGRectNull;
    
    for (NSValue *rectValue in rects_)
    {
        newFrame = CGRectUnion(newFrame, [rectValue CGRectValue]);
    }
    
    // A little extra drawing space to compensate for Quartz's corner addressing
    newFrame.size.width += 2.0;
    newFrame.size.height += 2.0;
    
    self.frame = newFrame;
    
    [self setNeedsDisplay];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Configuring the Style

- (void)setCoalescesRects:(BOOL)coalescesRects
{
    coalescesRects_ = coalescesRects;
    [self setNeedsDisplay];
}

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

//--------------------------------------------------------------------------------------------------

#pragma mark Drawing

- (void)drawRect:(CGRect)drawingRect
{
    if (!fillsRects_ && !strokesRects_)
    {
        return;
    }
    
    if ([rects_ count] == 0)
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
    
    // Add desired path to context
    if (coalescesRects_ && [rects_ count] > 1)
    {
        [self addCoalescedRectsToContext:context];
    }
    else
    {
        [self addDisjointedRectsToContext:context];
    }
    
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

- (void)addCoalescedRectsToContext:(CGContextRef)context
{
    CGRect topRect = [[rects_ objectAtIndex:0] CGRectValue];
    CGRect bottomRect = [[rects_ objectAtIndex:[rects_ count] - 1] CGRectValue];
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, CGRectGetMinX(topRect), CGRectGetMinY(topRect));
    CGContextAddLineToPoint(context, CGRectGetMaxX(topRect), CGRectGetMinY(topRect));
    CGContextAddLineToPoint(context, CGRectGetMaxX(topRect), CGRectGetMinY(bottomRect));
    CGContextAddLineToPoint(context, CGRectGetMaxX(bottomRect), CGRectGetMinY(bottomRect));
    CGContextAddLineToPoint(context, CGRectGetMaxX(bottomRect), CGRectGetMaxY(bottomRect));
    CGContextAddLineToPoint(context, CGRectGetMinX(bottomRect), CGRectGetMaxY(bottomRect));
    CGContextAddLineToPoint(context, CGRectGetMinX(bottomRect), CGRectGetMaxY(topRect));
    CGContextAddLineToPoint(context, CGRectGetMinX(topRect), CGRectGetMaxY(topRect));
    CGContextAddLineToPoint(context, CGRectGetMinX(topRect), CGRectGetMinY(topRect));
    CGContextClosePath(context);

}

- (void)addDisjointedRectsToContext:(CGContextRef)context
{
    CGContextBeginPath(context);
    
    for (NSValue *rectValue in rects_)
    {
        CGRect regionRect = [rectValue CGRectValue];
        CGContextAddRect(context, regionRect);
    }
    
    CGContextClosePath(context);
}

@end
