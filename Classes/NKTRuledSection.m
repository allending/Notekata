//
//  Created by Allen Ding on 7/6/10.
//

#import "NKTRuledSection.h"

@implementation NKTRuledSection

@synthesize index;
@synthesize horizontalLinesEnabled;
@synthesize horizontalLineOffset;
@synthesize horizontalLineColor;
@synthesize lineHeight;

//@synthesize verticalMarginEnabled;
//@synthesize verticalMarginInset;
//@synthesize verticalMarginColor;

#pragma mark -
#pragma mark Initializing

- (void)commonInit_NKTPaperView {
    horizontalLinesEnabled = YES;
    horizontalLineColor = [[UIColor colorWithRed:0.72 green:0.72 blue:0.59 alpha:1.0] retain];
    lineHeight = 24.0;
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self commonInit_NKTPaperView];
        self.backgroundColor = [UIColor clearColor];
        self.contentMode = UIViewContentModeRedraw;
    }
    
    return self;
}

- (void)awakeFromNib {
    [self commonInit_NKTPaperView];
}

- (void)dealloc {
    [horizontalLineColor release];
    [verticalMarginColor release];
    [super dealloc];
}

#pragma mark -
#pragma mark Configuring the Page Style

- (void)setHorizontalLinesEnabled:(BOOL)flag {
    horizontalLinesEnabled = flag;
    [self setNeedsDisplay];
}

- (void)setHorizontalLineOffset:(CGFloat)offset {
    horizontalLineOffset = offset;
    [self setNeedsDisplay];
}

- (void)setHorizontalLineColor:(UIColor *)color {
    [color retain];
    [horizontalLineColor release];
    horizontalLineColor = color;
    [self setNeedsDisplay];
}

- (void)setLineHeight:(CGFloat)newLineHeight {
    lineHeight = newLineHeight;
    [self setNeedsDisplay];
}

- (NSUInteger)horizontalLineCount {
    return self.bounds.size.height / self.lineHeight;
}

//- (void)setVerticalMarginEnabled:(BOOL)flag {
//    verticalMarginEnabled = flag;
//    [self setNeedsDisplay];
//}
//
//- (void)setVerticalMarginInset:(CGFloat)inset {
//    verticalMarginInset = inset;
//    [self setNeedsDisplay];
//}
//
//- (void)setVerticalMarginColor:(UIColor *)color {
//    [color retain];
//    [verticalMarginColor release];
//    verticalMarginColor = color;
//    [self setNeedsDisplay];
//}

#pragma mark -
#pragma mark Drawing

// options:

// add a subview to scroll view that renders page/print
// - 2 subviews, reuse each
// - this is preferable ...
// - how to know ..
// view controller handles?

// observe scrolls (set a delegate), and redraw page/print
// - probably not what is wanted

- (void)drawRect:(CGRect)rect {    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(context);
    CGContextSetAllowsAntialiasing(context, NO);
    CGContextSetLineWidth(context, 1.0);
    
    if (self.horizontalLinesEnabled) {
        CGContextBeginPath(context);
        CGFloat line = 1.0;
        
        for (; line < self.bounds.size.height; line += self.lineHeight) {
            CGContextMoveToPoint(context, 0.0, line);
            CGContextAddLineToPoint(context, self.bounds.size.width, line);
        }
        
        CGContextSetStrokeColorWithColor(context, self.horizontalLineColor.CGColor);
        CGContextStrokePath(context);
    }
    
    /*if (self.verticalMarginEnabled) {
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, self.verticalMarginInset, 0.0);
        CGContextAddLineToPoint(context, self.verticalMarginInset, self.bounds.size.height);
        [self.verticalMarginColor setStroke];
        CGContextStrokePath(context);
    }*/
    
    CGContextRestoreGState(context);
}

@end

/*- (void)setPlainStyle {
    UIImage *image = [UIImage imageNamed:@"PlainPaperPattern.png"];
    self.paperView.backgroundColor = [UIColor colorWithPatternImage:image];
    self.paperView.horizontalLinesEnabled = NO;
    self.paperView.verticalMarginEnabled = NO;
}

- (void)setPlainRuledStyle {
    UIImage *image = [UIImage imageNamed:@"PlainPaperPattern.png"];
    self.paperView.backgroundColor = [UIColor colorWithPatternImage:image];
    self.paperView.horizontalLinesEnabled = YES;
    self.paperView.horizontalLineColor = [UIColor colorWithRed:0.77 green:0.77 blue:0.72 alpha:1.0];
    self.paperView.verticalMarginEnabled = NO;
}

- (void)setCreamRuledStyle {
    UIImage *image = [UIImage imageNamed:@"CreamPaperPattern.png"];
    self.paperView.backgroundColor = [UIColor colorWithPatternImage:image];
    self.paperView.horizontalLinesEnabled = YES;
    self.paperView.horizontalLineColor = [UIColor colorWithRed:0.72 green:0.72 blue:0.59 alpha:1.0];
    self.paperView.verticalMarginEnabled = NO;
}

- (void)setCollegeRuledStyle {
    UIImage *image = [UIImage imageNamed:@"PlainPaperPattern.png"];
    self.paperView.backgroundColor = [UIColor colorWithPatternImage:image];
    self.paperView.horizontalLinesEnabled = YES;
    self.paperView.horizontalLineColor = [UIColor colorWithRed:0.69 green:0.77 blue:0.9 alpha:1.0];
    self.paperView.verticalMarginEnabled = YES;
    self.paperView.verticalMarginColor = [UIColor colorWithRed:0.83 green:0.3 blue:0.29 alpha:1.0];
    self.paperView.verticalMarginInset = 60.0;
}*/
