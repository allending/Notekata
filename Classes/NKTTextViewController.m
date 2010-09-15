//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTTextViewController.h"
#import "KobaText.h"

@interface NKTTextViewController()

#pragma mark Managing Views

@property (nonatomic, retain) KUIToggleButton *boldToggleButton;
@property (nonatomic, retain) KUIToggleButton *italicToggleButton;
@property (nonatomic, retain) KUIToggleButton *underlineToggleButton;

- (void)createToolbarItems;

#pragma mark Managing Text Attributes

- (NSDictionary *)activeTextAttributes;

#pragma mark Responding to Actions

- (void)boldToggleChanged:(KUIToggleButton *)toggleButton;
- (void)italicToggleChanged:(KUIToggleButton *)toggleButton;
- (void)underlineToggleChanged:(KUIToggleButton *)toggleButton;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------

@implementation NKTTextViewController

@synthesize toolbar = toolbar_;
@synthesize edgeView = edgeView_;
@synthesize textView = textView_;
@synthesize boldToggleButton = boldToggleButton_;
@synthesize italicToggleButton = italicToggleButton_;
@synthesize underlineToggleButton = underlineToggleButton_;

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (void)dealloc
{
    [toolbar_ release];
    [edgeView_ release];
    [textView_ release];
    [boldToggleButton_ release];
    [italicToggleButton_ release];
    [underlineToggleButton_ release];
    [super dealloc];
}
//--------------------------------------------------------------------------------------------------

#pragma mark Managing Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.toolbar = nil;
    self.edgeView = nil;
    self.textView = nil;
    self.boldToggleButton = nil;
    self.italicToggleButton = nil;
    self.underlineToggleButton = nil;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Managing Views

- (UIColor *)loupeFillColor
{
    return self.view.backgroundColor;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    UIImage *edgePattern = [UIImage imageNamed:@"RedCoverPattern.png"];
    self.edgeView.backgroundColor = [UIColor colorWithPatternImage:edgePattern];
    
    UIImage *backgroundPattern = [UIImage imageNamed:@"CreamPaperPattern.png"];
    self.view.backgroundColor = [UIColor colorWithPatternImage:backgroundPattern];
    
    [self createToolbarItems];
    
    textView_.delegate = self;
    textView_.activeTextAttributes = [self activeTextAttributes];
}

- (void)createToolbarItems
{
    boldToggleButton_ = [[KUIToggleButton alloc] initWithStyle:KUIToggleButtonStyleTextDark];
    [boldToggleButton_ addTarget:self action:@selector(boldToggleChanged:) forControlEvents:UIControlEventValueChanged];
    [boldToggleButton_ setTitle:@"B" forState:UIControlStateNormal];
    boldToggleButton_.titleLabel.font = [UIFont fontWithName:@"Georgia-Bold" size:16.0];
    boldToggleButton_.frame = CGRectMake(0.0, 0.0, 44.0, 44.0);
    
    italicToggleButton_ = [[KUIToggleButton alloc] initWithStyle:KUIToggleButtonStyleTextDark];
    [italicToggleButton_ addTarget:self action:@selector(italicToggleChanged:) forControlEvents:UIControlEventValueChanged];
    [italicToggleButton_ setTitle:@"I" forState:UIControlStateNormal];
    italicToggleButton_.titleLabel.font = [UIFont fontWithName:@"Georgia-Italic" size:16.0];
    italicToggleButton_.frame = CGRectMake(0.0, 0.0, 44.0, 44.0);
    
    underlineToggleButton_ = [[KUIToggleButton alloc] initWithStyle:KUIToggleButtonStyleTextDark];
    [underlineToggleButton_ addTarget:self action:@selector(underlineToggleChanged:) forControlEvents:UIControlEventValueChanged];
    [underlineToggleButton_ setTitle:@"U" forState:UIControlStateNormal];
    underlineToggleButton_.titleLabel.font = [UIFont fontWithName:@"Georgia-Bold" size:16.0];
    underlineToggleButton_.frame = CGRectMake(0.0, 0.0, 44.0, 44.0);
    
    UIBarButtonItem *boldToggleItem = [[UIBarButtonItem alloc] initWithCustomView:boldToggleButton_];
    UIBarButtonItem *italicToggleItem = [[UIBarButtonItem alloc] initWithCustomView:italicToggleButton_];
    UIBarButtonItem *underlineToggleItem = [[UIBarButtonItem alloc] initWithCustomView:underlineToggleButton_];
    UIBarButtonItem *debugItem = [[UIBarButtonItem alloc] initWithTitle:@"Debug"
                                                                  style:UIBarButtonItemStyleBordered
                                                                 target:self
                                                                 action:@selector(debugPressed:)];
    self.toolbar.items = [NSArray arrayWithObjects:boldToggleItem, italicToggleItem, underlineToggleItem, debugItem, nil];
    [boldToggleItem release];
    [italicToggleItem release];
    [underlineToggleItem release];
    [debugItem release];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Configuring the View Rotation Settings

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Managing Text Attributes

- (NSDictionary *)activeTextAttributes
{
    KBTTextStyleGenerator *textStyleGenerator = [KBTTextStyleGenerator textStyleGenerator];
    textStyleGenerator.fontFamily = @"Helvetica Neue";
    textStyleGenerator.fontSize = 16.0;
    
    if (boldToggleButton_.isSelected)
    {
        textStyleGenerator.boldTraitEnabled = YES;
    }
    
    if (italicToggleButton_.isSelected)
    {
        textStyleGenerator.italicTraitEnabled = YES;
    }
    
    textStyleGenerator.textUnderlined = underlineToggleButton_.isSelected;
    return [textStyleGenerator currentTextStyleAttributes];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Responding to Actions

- (void)boldToggleChanged:(KUIToggleButton *)toggleButton
{
    textView_.activeTextAttributes = [self activeTextAttributes];
}

- (void)italicToggleChanged:(KUIToggleButton *)toggleButton
{
    textView_.activeTextAttributes = [self activeTextAttributes];   
}

- (void)underlineToggleChanged:(KUIToggleButton *)toggleButton
{
    textView_.activeTextAttributes = [self activeTextAttributes];
}

- (void)debugPressed:(UIBarButtonItem *)item
{
    NSArray *ranges, *attributeDictionaries;
    KBTEnumerateAttributedStringAttributes(textView_.text, &ranges, &attributeDictionaries, NO);
    NSString *text = [textView_.text string];
    
    NSLog(@"%d total uncoalesced ranges", [ranges count]);
    NSLog(@"---------------------------");
    
    for (NSUInteger index = 0; index < [ranges count]; ++index)
    {
        NSRange range = [[ranges objectAtIndex:index] rangeValue];
        NSLog(@"range %d [%d, %d]: %@", index, range.location, range.location + range.length, [text substringWithRange:range]);
        // NSDictionary *dictionary = [attributeDictionaries objectAtIndex:index];
    }
}

@end

/*
 - (void)setPlainStyle {
    UIImage *image = [UIImage imageNamed:@"PlainPaperPattern.png"];
    self.paperView.backgroundColor = [UIColor colorWithPatternImage:image];
    self.paperView.horizontalRulesEnabled = NO;
    self.paperView.verticalMarginEnabled = NO;
}

- (void)setPlainRuledStyle {
    UIImage *image = [UIImage imageNamed:@"PlainPaperPattern.png"];
    self.paperView.backgroundColor = [UIColor colorWithPatternImage:image];
    self.paperView.horizontalRulesEnabled = YES;
    self.paperView.horizontalRuleColor = [UIColor colorWithRed:0.77 green:0.77 blue:0.72 alpha:1.0];
    self.paperView.verticalMarginEnabled = NO;
}

- (void)setCreamRuledStyle {
    UIImage *image = [UIImage imageNamed:@"CreamPaperPattern.png"];
    self.paperView.backgroundColor = [UIColor colorWithPatternImage:image];
    self.paperView.horizontalRulesEnabled = YES;
    self.paperView.horizontalRuleColor = [UIColor colorWithRed:0.72 green:0.72 blue:0.59 alpha:1.0];
    self.paperView.verticalMarginEnabled = NO;
}

- (void)setCollegeRuledStyle {
    UIImage *image = [UIImage imageNamed:@"PlainPaperPattern.png"];
    self.paperView.backgroundColor = [UIColor colorWithPatternImage:image];
    self.paperView.horizontalRulesEnabled = YES;
    self.paperView.horizontalRuleColor = [UIColor colorWithRed:0.69 green:0.77 blue:0.9 alpha:1.0];
    self.paperView.verticalMarginEnabled = YES;
    self.paperView.verticalMarginColor = [UIColor colorWithRed:0.83 green:0.3 blue:0.29 alpha:1.0];
    self.paperView.verticalMarginInset = 60.0;
}
 */
