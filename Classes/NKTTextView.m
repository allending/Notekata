//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTTextView.h"
#import <CoreText/CoreText.h>

@implementation NKTTextView

@synthesize text;
@synthesize textInset;
@synthesize lineHeight;

#pragma mark -
#pragma mark Initializing

- (void)initCommonState {
    self.lineHeight = 24.0;
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self initCommonState];
        self.contentMode = UIViewContentModeRedraw;
    }
    
    return self;
}

- (void)awakeFromNib {
    [self initCommonState];
}

- (void)dealloc {
    [text release];
    [super dealloc];
}

#pragma mark -
#pragma mark Managing the Text

- (void)setText:(NSAttributedString *)newText {
    if (text != newText) {
        [text release];
        text = [newText copy];
        [self setNeedsDisplay];
    }
}

#pragma mark -
#pragma mark Managing Typography

- (void)setTextInset:(UIEdgeInsets)inset {
    textInset = inset;
    [self setNeedsDisplay];
}

- (void)setLineHeight:(CGFloat)height {
    lineHeight = height;
    [self setNeedsDisplay];
}

#pragma mark -
#pragma mark Typesetting

- (CGRect)textRect {
    return CGRectMake(self.textInset.left,
                      self.textInset.bottom,
                      self.bounds.size.width - (self.textInset.left + self.textInset.right),
                      self.bounds.size.height - (self.textInset.top + self.textInset.bottom));
}

- (void)drawLinesInContext:(CGContextRef)context {
    CGContextSaveGState(context);
    
    // Set the clip region to the view bounds excluding the bottom inset
    CGRect clipRect = self.bounds;
    clipRect.origin.y += self.textInset.bottom;
    CGContextBeginPath(context);
    CGContextAddRect(context, clipRect);
    CGContextClosePath(context);
    CGContextClip(context);
    
    // Create typesetter for the text
    CTTypesetterRef typesetter = CTTypesetterCreateWithAttributedString((CFAttributedStringRef)self.text);
    
    CFIndex length = (CFIndex)[self.text length];
    CFIndex charIndex = 0;
    CGRect textRect = [self textRect];
    // The first baseline starts one line height below the top inset
    CGFloat baseline = CGRectGetMaxY(textRect) - self.lineHeight;
    
    while (charIndex < length) {
        CFIndex lineCharCount = CTTypesetterSuggestLineBreak(typesetter, charIndex, textRect.size.width);
        CTLineRef line = CTTypesetterCreateLine(typesetter, CFRangeMake(charIndex, lineCharCount));
        CGContextSetTextPosition(context, textRect.origin.x, baseline);
        CTLineDraw(line, context);
        charIndex += lineCharCount;
        baseline -= self.lineHeight;
        CFRelease(line);
    }
    
    CFRelease(typesetter);
    CGContextRestoreGState(context);
}

- (void)drawDebugTextInsetInContext:(CGContextRef)context {
    CGContextSaveGState(context);
    CGContextBeginPath(context);
    CGContextAddRect(context, [self textRect]);
    CGContextClosePath(context);
    CGContextSetShouldAntialias(context, NO);
    CGContextSetLineWidth(context, 1.0);
    [[UIColor cyanColor] setStroke];
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
}

#pragma mark -
#pragma mark Drawing

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Set up coordinate system with origin at the bottom-left
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    [self drawLinesInContext:context];
    //[self drawDebugTextInsetInContext:context];
}

@end
