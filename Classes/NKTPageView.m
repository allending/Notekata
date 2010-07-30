/*//
//  Created by Allen Ding on 7/6/10.
//

#import "NKTPageView.h"
#import "NKTTextView.h"

@interface NKTPageView()

#pragma mark -
#pragma mark Accessing the Text View

@property (nonatomic, readwrite, retain) NKTTextView *textView;

#pragma mark -
#pragma mark Managing the Page Style

- (void)configureWithPlainPageStyle;
- (void)configureWithPlainRuledPageStyle;
- (void)configureWithCreamRuledPageStyle;
- (void)configureWithCollegeRuledPageStyle;

@end

@implementation NKTPageView

@synthesize textView;

@synthesize horizontalLinesEnabled;
@synthesize horizontalLineOffset;
@synthesize horizontalLineColor;

@synthesize verticalMarginEnabled;
@synthesize verticalMarginInset;
@synthesize verticalMarginColor;

#pragma mark -
#pragma mark Initializing

- (void)createTextView {
    NKTTextView *theTextView = [[NKTTextView alloc] initWithFrame:self.bounds];
    theTextView.opaque = NO;
    theTextView.backgroundColor = [UIColor clearColor];
    theTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self addSubview:theTextView];
    self.textView = theTextView;
    [theTextView release];
}

- (void)initCommonState {
    [self createTextView];
    [self configureWithStyle:NKTPageViewStyleCreamRuled];
    self.lineHeight = 24.0;
    self.horizontalLineOffset = 3.0;
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
    [textView release];
    [horizontalLineColor release];
    [verticalMarginColor release];
    [super dealloc];
}

#pragma mark -
#pragma mark Managing Text

- (NSAttributedString *)text {
    return self.textView.text;
}

- (void)setText:(NSAttributedString *)theText {
    self.textView.text = theText;
}

#pragma mark -
#pragma mark Managing Typography

- (UIEdgeInsets)textInset {
    return self.textView.textInset;
}

- (void)setTextInset:(UIEdgeInsets)inset {
    self.textView.textInset = inset;
    [self setNeedsDisplay];
}

- (CGFloat)lineHeight {
    return self.textView.lineHeight;
}

- (void)setLineHeight:(CGFloat)lineHeight {
    self.textView.lineHeight = lineHeight;
    [self setNeedsDisplay];
}

#pragma mark -
#pragma mark Managing the Page Style

- (void)configureWithStyle:(NKTPageViewStyle)style {
    switch (style) {
        case NKTPageViewStylePlain:
            [self configureWithPlainPageStyle];
            break;
        case NKTPageViewStylePlainRuled:
            [self configureWithPlainRuledPageStyle];
            break;
        case NKTPageViewStyleCreamRuled:
            [self configureWithCreamRuledPageStyle];
            break;
        case NKTPageViewStyleCollegeRuled:
            [self configureWithCollegeRuledPageStyle];
            break;
        default:
            NSLog(@"%s - unknown NKTPageViewStyle %d specified", __PRETTY_FUNCTION__, style);
            [self configureWithPlainPageStyle];
            break;
    }
}

- (void)configureWithPlainPageStyle {
    UIImage *image = [UIImage imageNamed:@"PlainPaperPattern.png"];
    self.backgroundColor = [UIColor colorWithPatternImage:image];
    self.horizontalLinesEnabled = NO;
    self.verticalMarginEnabled = NO;
    self.textInset = UIEdgeInsetsMake(40.0, 30.0, 30.0, 30.0);
}

- (void)configureWithPlainRuledPageStyle {
    UIImage *image = [UIImage imageNamed:@"PlainPaperPattern.png"];
    self.backgroundColor = [UIColor colorWithPatternImage:image];
    self.horizontalLinesEnabled = YES;
    self.horizontalLineColor = [UIColor colorWithRed:0.77 green:0.77 blue:0.72 alpha:1.0];
    self.verticalMarginEnabled = NO;
    self.textInset = UIEdgeInsetsMake(40.0, 30.0, 30.0, 30.0);
}

- (void)configureWithCreamRuledPageStyle {
    UIImage *image = [UIImage imageNamed:@"CreamPaperPattern.png"];
    self.backgroundColor = [UIColor colorWithPatternImage:image];
    self.horizontalLinesEnabled = YES;
    self.horizontalLineColor = [UIColor colorWithRed:0.72 green:0.72 blue:0.59 alpha:1.0];
    self.verticalMarginEnabled = NO;
    self.textInset = UIEdgeInsetsMake(40.0, 30.0, 30.0, 30.0);
}

- (void)configureWithCollegeRuledPageStyle {
    UIImage *image = [UIImage imageNamed:@"PlainPaperPattern.png"];
    self.backgroundColor = [UIColor colorWithPatternImage:image];
    self.horizontalLinesEnabled = YES;
    self.horizontalLineColor = [UIColor colorWithRed:0.69 green:0.77 blue:0.9 alpha:1.0];
    self.verticalMarginEnabled = YES;
    self.verticalMarginColor = [UIColor colorWithRed:0.83 green:0.3 blue:0.29 alpha:1.0];
    self.verticalMarginInset = 60.0;
    self.textInset = UIEdgeInsetsMake(40.0, 75.0, 30.0, 30.0);
}

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

- (void)setVerticalMarginEnabled:(BOOL)flag {
    verticalMarginEnabled = flag;
    [self setNeedsDisplay];
}

- (void)setVerticalMarginInset:(CGFloat)inset {
    verticalMarginInset = inset;
    [self setNeedsDisplay];
}

- (void)setVerticalMarginColor:(UIColor *)color {
    [color retain];
    [verticalMarginColor release];
    verticalMarginColor = color;
    [self setNeedsDisplay];
}

#pragma mark -
#pragma mark Drawing

- (void)drawRect:(CGRect)rect {    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(context);
    CGContextSetAllowsAntialiasing(context, NO);
    
    if (self.horizontalLinesEnabled) {
        CGContextBeginPath(context);
        CGFloat lineY = self.textView.textInset.top + self.lineHeight + self.horizontalLineOffset;
        
        for (; lineY < self.bounds.size.height; lineY += self.lineHeight) {
            CGContextMoveToPoint(context, 0.0, lineY);
            CGContextAddLineToPoint(context, self.bounds.size.width, lineY);
        }
        
        [self.horizontalLineColor setStroke];
        CGContextStrokePath(context);
    }
    
    if (self.verticalMarginEnabled) {
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, self.verticalMarginInset, 0.0);
        CGContextAddLineToPoint(context, self.verticalMarginInset, self.bounds.size.height);
        [self.verticalMarginColor setStroke];
        CGContextStrokePath(context);
    }
    
    CGContextRestoreGState(context);
}

@end
*/