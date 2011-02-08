//------------------------------------------------------------------------------
// Copyright 2011 Allen Ding
//------------------------------------------------------------------------------

#import "KOTextPDFWriter.h"
#import <CoreText/CoreText.h>

@implementation KOTextPDFWriter

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Initialization
//------------------------------------------------------------------------------

- (id)initWithString:(NSString *)aString
{
    if ((self = [super init]))
    {
        text = [[NSAttributedString alloc] initWithString:aString];
    }
    
    return self;
}

- (id)initWithAttributedString:(NSAttributedString *)anAttributedString
{
    if ((self = [super init]))
    {
        text = [anAttributedString copy];
    }
    
    return self;
}

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Writing PDFs
//------------------------------------------------------------------------------

- (void)drawPageNumber:(NSInteger)pageNumber
{
    NSString *pageString = [NSString stringWithFormat:@"Page %d", pageNumber];
    UIFont *font = [UIFont systemFontOfSize:12.0];
    CGSize maxSize = CGSizeMake(612, 72);
    CGSize pageStringSize = [pageString sizeWithFont:font constrainedToSize:maxSize lineBreakMode:UILineBreakModeClip];
    CGRect pageStringRect = CGRectMake((612.0 - pageStringSize.width) * 0.5,
                                       720.0 + ((72.0  - pageStringSize.height) * 0.5),
                                       pageStringSize.width,
                                       pageStringSize.height);
    [pageString drawInRect:pageStringRect withFont:font];
}

- (CFRange)renderPageWithTextRange:(CFRange)range framesetter:(CTFramesetterRef)framesetter
{
    // Set up context
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    
    // Create path for frame
    CGRect frameRect = CGRectMake(72, 72, 462, 648);
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, frameRect);
    
    // Create and draw frame
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, range, path, NULL);
    CFRelease(path);
    CGContextTranslateCTM(context, 0.0, 792.0);
    CGContextScaleCTM(context, 1.0, -1.0);
    CTFrameDraw(frame, context);
    CFRelease(frame);
    
    // Returned drawn range
    range = CTFrameGetVisibleStringRange(frame);
    range.location += range.length;
    range.length = 0;
    return range;
}

- (BOOL)writeToFile:(NSString *)path
{
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)text);
    
    if (framesetter == NULL)
    {
        // TODO: Report failure creating framesetter
        return NO;
    }
    
    if (!UIGraphicsBeginPDFContextToFile(path, CGRectZero, nil))
    {
        // TODO: Report failure creating context
        CFRelease(framesetter);
        return NO;
    }
    
    NSLog(@"%s: writing pdf to '%@'", __PRETTY_FUNCTION__, path);
    CFRange range = CFRangeMake(0, 0);
    NSUInteger textLength = [text length];
    NSInteger page = 1;
    
    while (range.location < textLength)
    {
        UIGraphicsBeginPDFPageWithInfo(CGRectMake(0, 0, 612, 792), nil);
        [self drawPageNumber:page++];
        range = [self renderPageWithTextRange:range framesetter:framesetter];
    }
    
    UIGraphicsEndPDFContext();
    CFRelease(framesetter);
    return YES;
}

- (BOOL)writeToMutableData:(NSMutableData *)mutableData
{
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)text);
    
    if (framesetter == NULL)
    {
        // TODO: Report failure creating framesetter
        return NO;
    }
    
    UIGraphicsBeginPDFContextToData(mutableData, CGRectZero, nil);
    CFRange range = CFRangeMake(0, 0);
    NSUInteger textLength = [text length];
    NSInteger page = 1;
    
    while (range.location < textLength)
    {
        UIGraphicsBeginPDFPageWithInfo(CGRectMake(0, 0, 612, 792), nil);
        [self drawPageNumber:page++];
        range = [self renderPageWithTextRange:range framesetter:framesetter];
    }
    
    UIGraphicsEndPDFContext();
    CFRelease(framesetter);
    return YES;    
}

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Memory Management
//------------------------------------------------------------------------------

- (void)dealloc
{
    [text release];
    [super dealloc];
}

@end
