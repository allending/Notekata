//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTLoupe.h"
#import <QuartzCore/QuartzCore.h>

@implementation NKTLoupe

@synthesize anchor;

@synthesize zoomedView;
@synthesize zoomCenter;

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
        
        // Load and create resources
        switch (style)
        {
            case NKTLoupeStyleBand:
                maskData = [[UIImage imageNamed:@"BandLoupeMask.png"] retain];
                overlay = [[UIImage imageNamed:@"BandLoupe.png"] retain];
                anchorOffset = CGPointMake(overlay.size.width * 0.5, overlay.size.height);
                break;
            case NKTLoupeStyleRound:
                maskData = [[UIImage imageNamed:@"CaretLoupeMask.png"] retain];
                overlay = [[UIImage imageNamed:@"CaretLoupe.png"] retain];
                anchorOffset = CGPointMake(overlay.size.width * 0.5, overlay.size.height);
                break;
            default:
                break;
        }
        
        if (maskData == nil || overlay == nil)
        {
            KBCLogWarning(@"could not load required image resources, returning nil");
            [self release];
            return nil;
        }
        
        CGImageRef maskSourceCGImage = maskData.CGImage;        
        mask = CGImageMaskCreate(CGImageGetWidth(maskSourceCGImage),
                                 CGImageGetHeight(maskSourceCGImage),
                                 CGImageGetBitsPerComponent(maskSourceCGImage),
                                 CGImageGetBitsPerPixel(maskSourceCGImage),
                                 CGImageGetBytesPerRow(maskSourceCGImage),
                                 CGImageGetDataProvider(maskSourceCGImage),
                                 NULL,
                                 false);
        
        anchor = CGPointZero;
        inverseZoomScale = 1.0 / 1.3;

        // Immediately adjust the frame
        self.frame = CGRectMake(anchor.x - (overlay.size.width * 0.5),
                                anchor.y - overlay.size.height,
                                overlay.size.width,
                                overlay.size.height);
    }
    
    return self;
}

- (void)dealloc
{
    [maskData release];
    [overlay release];
    
    if (mask)
    {
        CFRelease(mask);
    }
    
    [super dealloc];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Anchoring Loupes

- (void)setAnchor:(CGPoint)newAnchor
{
    anchor = newAnchor;
    self.center = CGPointMake(anchor.x - anchorOffset.x + (overlay.size.width * 0.5),
                              anchor.y - anchorOffset.y + (overlay.size.height * 0.5));
    [self setNeedsDisplay];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Configuring Magnification

- (void)setZoomedView:(UIView *)newZoomedView
{
    zoomedView = newZoomedView;
    [self setNeedsDisplay];
}

- (void)setZoomCenter:(CGPoint)newMagnifiedCenter
{
	zoomCenter = newMagnifiedCenter;
    [self setNeedsDisplay];
}

- (CGFloat)zoomScale
{
    return 1.0 / inverseZoomScale;
}

- (void)setZoomScale:(CGFloat)zoomScale
{
    inverseZoomScale = 1.0 / zoomScale;
    [self setNeedsDisplay];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Displaying

- (void)setHidden:(BOOL)hidden animated:(BOOL)animated
{
    if (self.hidden == hidden)
    {
        return;
    }
    
    if (!animated)
    {
        self.hidden = hidden;
        return;
    }

    // Always not hidden initially if animating
    self.hidden = NO;
    
    // Animate from not hidden to hidden
    if (hidden)
    {
        self.frame = CGRectMake(anchor.x - anchorOffset.x,
                                anchor.y - anchorOffset.y,
                                overlay.size.width,
                                overlay.size.height);
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(hidingAnimationDidStop:finished:context:)];
        [UIView setAnimationDuration:0.15];
        self.frame = CGRectMake(self.anchor.x, self.anchor.y, 0.0, 0.0);
        [UIView commitAnimations];
    }
    // Animate from hidden to not hidden
    else
    {
        self.frame = CGRectMake(self.anchor.x, self.anchor.y, 0.0, 0.0);
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.15];
        self.frame = CGRectMake(anchor.x - anchorOffset.x,
                                anchor.y - anchorOffset.y,
                                overlay.size.width,
                                overlay.size.height);
        [UIView commitAnimations];
    }
}

- (void)hidingAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    self.hidden = YES;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Drawing

- (void)drawRect:(CGRect)rect
{
    CGSize zoomedSize = CGSizeMake(overlay.size.width * inverseZoomScale, overlay.size.height * inverseZoomScale);
    CGSize halfZoomedSize = CGSizeMake(zoomedSize.width * 0.5, zoomedSize.height * 0.5);
    
    // Render the relevant zoomed view region to an image context
    UIGraphicsBeginImageContext(CGSizeMake(zoomedSize.width, zoomedSize.height));
	CGContextRef context = UIGraphicsGetCurrentContext();
    // Compute clamped origin for zoomed region in zoomed view space
    CGPoint zoomOrigin = CGPointMake(zoomCenter.x - halfZoomedSize.width, zoomCenter.y - halfZoomedSize.height);
    zoomOrigin.x = KBCClamp(zoomOrigin.x, 0.0, zoomedView.bounds.size.width - zoomedSize.width);
    zoomOrigin.y = KBCClamp(zoomOrigin.y, 0.0, zoomedView.bounds.size.height - zoomedSize.height);
    // Apply inverse zoom origin so zoomed view can render directly into the context
    CGContextTranslateCTM(context, -zoomOrigin.x, -zoomOrigin.y);
    [zoomedView.layer renderInContext:context];
    UIImage *zoomedRegion = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Mask out portion of zoomed region under the loupe
	CGImageRef maskedRegion = CGImageCreateWithMask(zoomedRegion.CGImage, mask);
    
    // Render composite of masked region and overlay
	context = UIGraphicsGetCurrentContext();
	CGContextScaleCTM(context, 1.0, -1.0);
	CGRect area = CGRectMake(0, 0, overlay.size.width, -overlay.size.height);
	CGContextDrawImage(context, area, maskedRegion);
	CGContextDrawImage(context, area, overlay.CGImage);
    CFRelease(maskedRegion);
}

@end
