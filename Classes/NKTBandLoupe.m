//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTBandLoupe.h"

#import "NKTLogging.h"

@implementation NKTBandLoupe

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (id)init
{
    if ((self = [super init]))
    {
        self.backgroundColor = [UIColor clearColor];
        maskSourceImage = [[UIImage imageNamed:@"BandLoupeMask.png"] retain];
        overlayImage = [[UIImage imageNamed:@"BandLoupe.png"] retain];
        
        if (maskSourceImage == nil || overlayImage == nil)
        {
            NKTLogWarning(@"could not load required image, returning nil");
            [self release];
            return nil;
        }
        
        CGImageRef maskSourceCGImage = maskSourceImage.CGImage;        
        mask = CGImageMaskCreate(CGImageGetWidth(maskSourceCGImage),
                                 CGImageGetHeight(maskSourceCGImage),
                                 CGImageGetBitsPerComponent(maskSourceCGImage),
                                 CGImageGetBitsPerPixel(maskSourceCGImage),
                                 CGImageGetBytesPerRow(maskSourceCGImage),
                                 CGImageGetDataProvider(maskSourceCGImage),
                                 NULL,
                                 true);
        
        self.bounds = CGRectMake(0.0, 0.0, overlayImage.size.width, overlayImage.size.height);
    }
    
    return self;
}

- (void)dealloc
{
    [maskSourceImage release];
    [overlayImage release];
    
    if (mask)
    {
        CFRelease(mask);
    }
    
    [super dealloc];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Anchoring Loupes

- (CGPoint)anchor
{
    return CGPointMake(self.center.x, self.center.y + (0.5 * self.bounds.size.height));
}

- (void)setAnchor:(CGPoint)anchor
{
    self.center = CGPointMake(anchor.x, anchor.y - (0.5 * self.bounds.size.height));
}

//--------------------------------------------------------------------------------------------------

#pragma mark Drawing

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextScaleCTM(context, 1.0, -1.0);
	CGRect area = CGRectMake(0, 0, overlayImage.size.width, -overlayImage.size.height);
	CGContextDrawImage(context, area, overlayImage.CGImage);
}

@end
