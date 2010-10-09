//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTLoupe.h"
#import <QuartzCore/QuartzCore.h>

@implementation NKTLoupe

@synthesize anchor = anchor_;
@synthesize zoomedView = zoomedView_;
@synthesize zoomCenter = zoomCenter_;
@synthesize fillColor = fillColor_;

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (id)init
{
    return [self initWithStyle:NKTLoupeStyleBand];
}

- (id)initWithFrame:(CGRect)frame
{
    return [self initWithStyle:NKTLoupeStyleBand];
}

- (id)initWithStyle:(NKTLoupeStyle)style
{
    if ((self = [super initWithFrame:CGRectZero]))
    {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        
        // Load and create resources
        switch (style)
        {
            case NKTLoupeStyleBand:
                maskData_ = [[UIImage imageNamed:@"BandLoupeMask.png"] retain];
                overlay_ = [[UIImage imageNamed:@"BandLoupe.png"] retain];
                anchorOffset_ = CGPointMake(overlay_.size.width * 0.5, overlay_.size.height);
                break;
            case NKTLoupeStyleRound:
                maskData_ = [[UIImage imageNamed:@"CaretLoupeMask.png"] retain];
                overlay_ = [[UIImage imageNamed:@"CaretLoupe.png"] retain];
                anchorOffset_ = CGPointMake(overlay_.size.width * 0.5, overlay_.size.height);
                break;
            default:
                KBCLogWarning(@"no style specified, returning nil");
                [self release];
                return nil;
        }
        
        if (maskData_ == nil || overlay_ == nil)
        {
            KBCLogWarning(@"could not load required image resources, returning nil");
            [self release];
            return nil;
        }
        
        CGImageRef maskSourceCGImage = maskData_.CGImage;        
        mask_ = CGImageMaskCreate(CGImageGetWidth(maskSourceCGImage),
                                 CGImageGetHeight(maskSourceCGImage),
                                 CGImageGetBitsPerComponent(maskSourceCGImage),
                                 CGImageGetBitsPerPixel(maskSourceCGImage),
                                 CGImageGetBytesPerRow(maskSourceCGImage),
                                 CGImageGetDataProvider(maskSourceCGImage),
                                 NULL,
                                 false);
        
        anchor_ = CGPointZero;
        inverseZoomScale_ = 1.0 / 1.3;

        fillColor_ = [[UIColor whiteColor] retain];
        
        // Immediately adjust the frame
        self.frame = CGRectMake(anchor_.x - (overlay_.size.width * 0.5),
                                anchor_.y - overlay_.size.height,
                                overlay_.size.width,
                                overlay_.size.height);
    }
    
    return self;
}

- (void)dealloc
{
    [maskData_ release];
    [overlay_ release];
    
    if (mask_)
    {
        CFRelease(mask_);
    }
    
    [fillColor_ release];
    [super dealloc];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Anchoring

- (void)setAnchor:(CGPoint)anchor
{
    anchor_ = anchor;
    self.center = CGPointMake(anchor_.x - anchorOffset_.x + (overlay_.size.width * 0.5),
                              anchor_.y - anchorOffset_.y + (overlay_.size.height * 0.5));
    [self setNeedsDisplay];
}

- (void)setFrame:(CGRect)frame
{
    if (CGRectEqualToRect(self.frame, frame))
    {
        return;
    }
    
    [super setFrame:frame];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Zooming

- (void)setZoomedView:(UIView *)zoomedView
{
    zoomedView_ = zoomedView;
    [self setNeedsDisplay];
}

- (void)setZoomCenter:(CGPoint)zoomCenter
{
	zoomCenter_ = zoomCenter;
    [self setNeedsDisplay];
}

- (CGFloat)zoomScale
{
    return 1.0 / inverseZoomScale_;
}

- (void)setZoomScale:(CGFloat)zoomScale
{
    inverseZoomScale_ = 1.0 / zoomScale;
    [self setNeedsDisplay];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Setting the Fill Color

- (void)setFillColor:(UIColor *)fillColor
{
    if (fillColor_ == fillColor)
    {
        return;
    }
    
    [fillColor_ release];
    fillColor_ = [fillColor retain];
    [self setNeedsDisplay];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Displaying

- (void)setHidden:(BOOL)hidden
{
    [self setHidden:hidden animated:NO];
}

// TODO: explain logic
- (void)setHidden:(BOOL)hidden animated:(BOOL)animated
{
    if (self.hidden == hidden)
    {
        return;
    }
    
    if (!animated)
    {
        if (hidden)
        {
            self.frame = CGRectMake(anchor_.x, anchor_.y, 0.0, 0.0);
        }
        else
        {
            self.frame = CGRectMake(anchor_.x - anchorOffset_.x,
                                    anchor_.y - anchorOffset_.y,
                                    overlay_.size.width,
                                    overlay_.size.height);
        }
        
        [super setHidden:hidden];
        return;
    }
    
    // Always not hidden initially if animating
    [super setHidden:NO];
    
    // Animate from not hidden to hidden
    if (hidden)
    {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(hidingAnimationDidStop:finished:context:)];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationDuration:0.15];
        self.frame = CGRectMake(anchor_.x, anchor_.y, 0.0, 0.0);
        self.alpha = 0.0;
        [UIView commitAnimations];
    }
    // Animate from hidden to not hidden
    else
    {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationDelay:0.15];
        [UIView setAnimationDuration:0.15];
        self.frame = CGRectMake(anchor_.x - anchorOffset_.x,
                                anchor_.y - anchorOffset_.y,
                                overlay_.size.width,
                                overlay_.size.height);
        self.alpha = 1.0;
        [UIView commitAnimations];
    }
}

- (void)hidingAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    [self setHidden:YES];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Drawing

- (void)drawRect:(CGRect)rect
{
    CGSize zoomedSize = CGSizeMake(overlay_.size.width * inverseZoomScale_, overlay_.size.height * inverseZoomScale_);
    CGSize halfZoomedSize = CGSizeMake(zoomedSize.width * 0.5, zoomedSize.height * 0.5);
    
    // Render the relevant zoomed view region to an image context
    UIGraphicsBeginImageContext(CGSizeMake(zoomedSize.width, zoomedSize.height));
	CGContextRef imageContext = UIGraphicsGetCurrentContext();
    
    // Fill the image context because things look whacky if the zoomed view has a clear background
    if (fillColor_ != nil)
    {
        CGContextSetFillColorWithColor(imageContext, fillColor_.CGColor);
    }
    
    CGContextFillRect(imageContext, CGRectMake(0.0, 0.0, zoomedSize.width, zoomedSize.height));
    // Compute clamped origin for zoomed region in zoomed view space
    CGPoint zoomOrigin = CGPointMake(zoomCenter_.x - halfZoomedSize.width, zoomCenter_.y - halfZoomedSize.height);
// TODO: clamping wrong
//    zoomOrigin.x = KBCClampFloat(zoomOrigin.x, 0.0, zoomedView_.bounds.size.width - zoomedSize.width);
//    zoomOrigin.y = KBCClampFloat(zoomOrigin.y, 0.0, zoomedView_.bounds.size.height - zoomedSize.height);
    // Apply inverse zoom origin so zoomed view can render directly into the context
    CGContextTranslateCTM(imageContext, -zoomOrigin.x, -zoomOrigin.y);
    [zoomedView_.layer renderInContext:imageContext];
    UIImage *zoomedRegion = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Mask out portion of zoomed region under the loupe
	CGImageRef maskedRegion = CGImageCreateWithMask(zoomedRegion.CGImage, mask_);
    
    // Render composite of masked region and overlay
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextScaleCTM(context, 1.0, -1.0);
	CGRect area = CGRectMake(0, 0, overlay_.size.width, -overlay_.size.height);
	CGContextDrawImage(context, area, maskedRegion);
	CGContextDrawImage(context, area, overlay_.CGImage);
    CFRelease(maskedRegion);
}

@end
