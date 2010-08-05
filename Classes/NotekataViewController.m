//
//  Copyright Allen Ding 2010. All rights reserved.
//

#import "NotekataViewController.h"
#import <CoreText/CoreText.h>
#import "NKTTestText.h"
#import "NKTPaperView.h"
#import "NKTTextView.h"

@implementation NotekataViewController

@synthesize toolbar;
@synthesize edgeView;
@synthesize textView;
@synthesize firstPaperView;
@synthesize secondPaperView;

#pragma mark -
#pragma mark Initializing

- (void)dealloc {
    [toolbar release];
    [edgeView release];
    [textView release];
    [firstPaperView release];
    [secondPaperView release];
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
    self.firstPaperView = nil;
    self.secondPaperView = nil;
}

#pragma mark -
#pragma mark Managing Views

- (void)viewDidLoad {
    UIImage *edgePattern = [UIImage imageNamed:@"RedCoverPattern.png"];
    self.edgeView.backgroundColor = [UIColor colorWithPatternImage:edgePattern];

    UIImage *backgroundPattern = [UIImage imageNamed:@"CreamPaperPattern.png"];
    self.view.backgroundColor = [UIColor colorWithPatternImage:backgroundPattern];
    
    // self.textView.delegate = self;
    self.textView.text = NKTTestText();
    self.textView.lineHeight = 27.0f;
    
    // Add a printed paper view to the textView (at the front)
    CGFloat ruleOffset = 2.0f;
    
    CGRect firstFrame = CGRectMake(0.0, self.textView.margins.top + ruleOffset, self.textView.bounds.size.width, self.textView.bounds.size.height);
    firstPaperView = [[NKTPaperView alloc] initWithFrame:firstFrame];
    firstPaperView.lineHeight = 27.0f;
    //firstPaperView.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.0 alpha:0.2];
    [self.textView insertSubview:firstPaperView atIndex:0];
    
    // A certain number of lines fit the first frame, second frame starts at firstframe.origin.y + lineHeight * (count + 1)
    CGFloat secondFrameY = firstFrame.origin.y + 27.0 * (firstPaperView.horizontalLineCount + 1);
    CGRect secondFrame = CGRectMake(0.0, secondFrameY, firstFrame.size.width, firstFrame.size.height);
    secondPaperView = [[NKTPaperView alloc] initWithFrame:secondFrame];
    //secondPaperView.backgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:0.5 alpha:0.2];
    secondPaperView.lineHeight = 27.0f;
    [self.textView insertSubview:secondPaperView atIndex:1];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

@end
