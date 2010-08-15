//
//  Copyright Allen Ding 2010. All rights reserved.
//

#import "NotekataViewController.h"
#import "NKTTestText.h"
#import "NKTTextView.h"

@implementation NotekataViewController

@synthesize toolbar;
@synthesize edgeView;
@synthesize textView;

#pragma mark -
#pragma mark Initializing

- (void)dealloc {
    [toolbar release];
    [edgeView release];
    [textView release];
    [super dealloc];
}

#pragma mark -
#pragma mark Managing Memory

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.toolbar = nil;
    self.edgeView = nil;
    self.textView = nil;
}

#pragma mark -
#pragma mark Managing Views

- (void)viewDidLoad {
    UIImage *edgePattern = [UIImage imageNamed:@"RedCoverPattern.png"];
    self.edgeView.backgroundColor = [UIColor colorWithPatternImage:edgePattern];

    UIImage *backgroundPattern = [UIImage imageNamed:@"CreamPaperPattern.png"];
    self.view.backgroundColor = [UIColor colorWithPatternImage:backgroundPattern];
    
    self.textView.text = NKTTestText();
    
    UIBarButtonItem *defaultLineHeight = [[UIBarButtonItem alloc] initWithTitle:@"Default Line Height"
                                                                          style:UIBarButtonItemStyleBordered
                                                                         target:self
                                                                         action:@selector(useDefaultLineHeight)];
    UIBarButtonItem *largeLineHeight = [[UIBarButtonItem alloc] initWithTitle:@"Large Line Height"
                                                                        style:UIBarButtonItemStyleBordered
                                                                       target:self
                                                                       action:@selector(useLargeLineHeight)];
    UIBarButtonItem *defaultMargins = [[UIBarButtonItem alloc] initWithTitle:@"Default Margins"
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:self
                                                                      action:@selector(useDefaultMargins)];
    UIBarButtonItem *zeroMargins = [[UIBarButtonItem alloc] initWithTitle:@"Zero Margins"
                                                                    style:UIBarButtonItemStyleBordered
                                                                   target:self
                                                                   action:@selector(useZeroMargins)];
    UIBarButtonItem *largeMargins = [[UIBarButtonItem alloc] initWithTitle:@"Large Margins"
                                                                     style:UIBarButtonItemStyleBordered
                                                                    target:self
                                                                    action:@selector(useLargeMargins)];
    NSArray *items = [NSArray arrayWithObjects:defaultLineHeight, largeLineHeight, defaultMargins, zeroMargins, largeMargins, nil];
    [defaultLineHeight release];
    [largeLineHeight release];
    [defaultMargins release];
    [zeroMargins release];
    [largeMargins release];
    toolbar.items = items;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)useDefaultLineHeight {
    textView.lineHeight = 30.0;
}

- (void)useLargeLineHeight {
    textView.lineHeight = 47.0;
}

- (void)useDefaultMargins {
    textView.margins = UIEdgeInsetsMake(60.0, 40.0, 80.0, 60.0);
}

- (void)useZeroMargins {
    textView.margins = UIEdgeInsetsZero;
}

- (void)useLargeMargins {
    textView.margins = UIEdgeInsetsMake(90.0, 90.0, 120.0, 90.0);
}

@end

/*
 - (void)setPlainStyle {
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
}
 */
