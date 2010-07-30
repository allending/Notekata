//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTTextViewCore.h"
#import <CoreText/CoreText.h>
#import "NKTFramesetter.h"

@interface NKTTextViewCore()

#pragma mark -
#pragma mark Typesetting

@property (nonatomic, readwrite) NKTFramesetter *framesetter;

@end

@implementation NKTTextViewCore

@synthesize text;
@synthesize contentWidth;
@synthesize lineHeight;
@synthesize margins;
@synthesize framesetter;

#pragma mark -
#pragma mark Initializing

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor clearColor];
        self.lineHeight = 24.0;
        self.margins = UIEdgeInsetsMake(60.0, 40.0, 40.0, 80.0);
        self.contentWidth = frame.size.width;
    }
    
    return self;
}

- (void)dealloc {
    [text release];
    [framesetter release];
    [super dealloc];
}

#pragma mark -
#pragma mark Managing Text

- (void)setText:(NSAttributedString *)newText {
    if (text != newText) {
        [text release];
        text = [newText copy];
        self.framesetter = nil;
        [self setNeedsDisplay];
    }
}

#pragma mark -
#pragma mark Managing Text Layout

- (void)setContentWidth:(CGFloat)newContentWidth {
    contentWidth = newContentWidth;
    self.framesetter = nil;
    [self setNeedsDisplay];
}

- (void)setLineHeight:(CGFloat)newLineHeight {
    lineHeight = newLineHeight;
    self.framesetter = nil;
    [self setNeedsDisplay];
}

- (void)setMargins:(UIEdgeInsets)newMargins {
    margins = newMargins;
    self.framesetter = nil;
    [self setNeedsDisplay];
}

- (CGSize)suggestedFrameSize {
    CGFloat height = [self.framesetter suggestedFrameHeight] + self.margins.top + self.margins.bottom;
    return CGSizeMake(self.contentWidth, height);
}

#pragma mark -
#pragma mark Typesetting

- (NKTFramesetter *)framesetter {
    if (framesetter != nil) {
        return framesetter;
    }
    
    CGFloat lineWidth = self.contentWidth - self.margins.left - self.margins.right;
    // TODO: lineWidth must be > 0
    framesetter = [[NKTFramesetter alloc] initWithText:self.text lineWidth:lineWidth lineHeight:self.lineHeight];
    return framesetter;
}

#pragma mark -
#pragma mark Drawing

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    // Set up coordinate system with origin at the top-left with y pointing up
    CGContextScaleCTM(context, 1.0, -1.0);
    // Drawing begins with the first baseline at the top margin
    CGContextTranslateCTM(context, self.margins.left, -self.margins.top);
    [self.framesetter drawInContext:context];
}

@end
