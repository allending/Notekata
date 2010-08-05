//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTTextViewCore.h"
#import "NKTTextFrame.h"

@interface NKTTextViewCore()

#pragma mark -
#pragma mark Generating Text Frames

@property (nonatomic, readwrite) NKTTextFrame *textFrame;

@end

@implementation NKTTextViewCore

@synthesize text;

@synthesize contentWidth;
@synthesize lineHeight;
@synthesize margins;

@synthesize textFrame;

#pragma mark -
#pragma mark Initializing

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor clearColor];
        lineHeight = 24.0;
        margins = UIEdgeInsetsMake(60.0, 40.0, 40.0, 80.0);
        contentWidth = frame.size.width;
    }
    
    return self;
}

- (void)dealloc {
    [text release];
    [textFrame release];
    [super dealloc];
}

#pragma mark -
#pragma mark Accessing Text

- (void)setText:(NSAttributedString *)newText {
    if (text != newText) {
        [text release];
        text = [newText copy];
        self.textFrame = nil;
        [self setNeedsDisplay];
    }
}

#pragma mark -
#pragma mark Configuring Text Layout

- (void)setContentWidth:(CGFloat)newContentWidth {
    contentWidth = newContentWidth;
    self.textFrame = nil;
    [self setNeedsDisplay];
}

- (void)setLineHeight:(CGFloat)newLineHeight {
    lineHeight = newLineHeight;
    self.textFrame = nil;
    [self setNeedsDisplay];
}

- (void)setMargins:(UIEdgeInsets)newMargins {
    margins = newMargins;
    self.textFrame = nil;
    [self setNeedsDisplay];
}

- (CGSize)suggestedFrameSize {
    CGFloat height = [self.textFrame suggestedFrameHeight] + self.margins.top + self.margins.bottom;
    return CGSizeMake(self.contentWidth, height);
}

#pragma mark -
#pragma mark Generating Text Metrics

- (NKTTextFrame *)textFrame {
    if (textFrame != nil) {
        return textFrame;
    }
    
    CGFloat lineWidth = self.contentWidth - self.margins.left - self.margins.right;
    // TODO: make sure lineWidth > 0
    textFrame = [[NKTTextFrame alloc] initWithText:self.text lineWidth:lineWidth lineHeight:self.lineHeight];
    return textFrame;
}

#pragma mark -
#pragma mark Drawing

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    // Set up coordinate system with origin at the top-left with y upwards
    CGContextScaleCTM(context, 1.0, -1.0);
    // Drawing begins with the first baseline at the top margin
    CGContextTranslateCTM(context, self.margins.left, -self.margins.top);
    [self.textFrame drawInContext:context];
}

@end
