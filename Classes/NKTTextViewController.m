//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTTextViewController.h"
#import "KobaText.h"
#import "NKTFontViewController.h"
#import "NKTTestText.h"

@interface NKTTextViewController()

#pragma mark Managing Views

@property (nonatomic, retain) KUIToggleButton *boldToggleButton;
@property (nonatomic, retain) KUIToggleButton *italicToggleButton;
@property (nonatomic, retain) KUIToggleButton *underlineToggleButton;

- (void)createToolbarItems;

#pragma mark Managing Text Attributes

- (NSDictionary *)activeTextAttributes;
- (void)updateTextViewTextAttributes;

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
    [fontViewController_ release];
    [fontPopoverController_ release];
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
    
    fontViewController_ = [[NKTFontViewController alloc] init];
    fontViewController_.delegate = self;
    fontViewController_.selectedFamilyName = @"Helvetica";
    
    fontPopoverController_ = [[UIPopoverController alloc] initWithContentViewController:fontViewController_];
    CGSize popoverContentSize = fontPopoverController_.popoverContentSize;
    popoverContentSize.height = 440.0;
    fontPopoverController_.popoverContentSize = popoverContentSize;
    
    [self createToolbarItems];
    
    textView_.delegate = self;
    
    // Sync UI
    [self textViewDidChangeSelection:nil];
//    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"What do you think about this eh" attributes:[self activeTextAttributes]];
//    textView_.text = string;
//    [string release];
//    textView_.activeTextAttributes = [self activeTextAttributes];
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

    UIButton *fontButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [fontButton setTitleColor:[UIColor colorWithRed:0.12 green:0.57 blue:0.92 alpha:1.0] forState:UIControlStateHighlighted|UIControlStateNormal];
    [fontButton setTitleColor:[UIColor colorWithRed:0.12 green:0.57 blue:0.92 alpha:1.0] forState:UIControlStateHighlighted|UIControlStateSelected];
    [fontButton setTitleColor:[UIColor colorWithRed:0.1 green:0.5 blue:0.9 alpha:1.0] forState:UIControlStateSelected];
    [fontButton setTitleColor:[UIColor lightTextColor] forState:UIControlStateNormal];
    [fontButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateDisabled];
    [fontButton addTarget:self action:@selector(fontPressed:) forControlEvents:UIControlEventTouchUpInside];
    [fontButton setTitle:@"Font" forState:UIControlStateNormal];
    fontButton.titleLabel.font = [UIFont fontWithName:@"Georgia-Bold" size:16.0];
    fontButton.frame = CGRectMake(0.0, 0.0, 100.0, 44.0);
    UIBarButtonItem *fontItem = [[UIBarButtonItem alloc] initWithCustomView:fontButton];
    
    UIBarButtonItem *debugTextItem = [[UIBarButtonItem alloc] initWithTitle:@"Debug Text"
                                                                  style:UIBarButtonItemStyleBordered
                                                                 target:self
                                                                 action:@selector(debugTextPressed:)];
    UIBarButtonItem *debugItem = [[UIBarButtonItem alloc] initWithTitle:@"Debug"
                                                                  style:UIBarButtonItemStyleBordered
                                                                 target:self
                                                                 action:@selector(debugPressed:)];
    self.toolbar.items = [NSArray arrayWithObjects:boldToggleItem,
                                                   italicToggleItem,
                                                   underlineToggleItem,
                                                   fontItem,
                                                   debugTextItem,
                                                   debugItem,
                                                   nil];
    [boldToggleItem release];
    [italicToggleItem release];
    [underlineToggleItem release];
    [fontItem release];
    [debugTextItem release];
    [debugItem release];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Configuring the View Rotation Settings

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Managing Text Attributes

- (NSDictionary *)activeTextAttributes
{
    KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithFontFamilyName:fontViewController_.selectedFamilyName
                                                                                           size:16.0
                                                                                           bold:boldToggleButton_.isSelected
                                                                                         italic:italicToggleButton_.isSelected
                                                                                     underlined:underlineToggleButton_.isSelected];
    return [styleDescriptor attributes];
}

- (void)updateTextViewTextAttributes
{
    NSDictionary *activeTextAttributes = [self activeTextAttributes];
    [textView_ setSelectedTextRangeTextAttributes:activeTextAttributes];
    textView_.activeTextAttributes = activeTextAttributes;
}

- (NSDictionary *)defaultTextAttributes
{
    return [self activeTextAttributes];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Selecting Fonts

- (void)fontViewController:(NKTFontViewController *)fontViewController didSelectFamilyName:(NSString *)familyName
{
    [self updateTextViewTextAttributes];
    // Sync UI
    [self textViewDidChangeSelection:nil];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Responding to Text Changes

- (void)textViewDidChange:(NKTTextView *)textView
{
    if (fontPopoverController_.isPopoverVisible)
    {
        [fontPopoverController_ dismissPopoverAnimated:YES];
    }
}

//--------------------------------------------------------------------------------------------------

#pragma mark Responding to Selection Changes

- (void)textViewDidChangeSelection:(NKTTextView *)textView
{
    // Update the UI state to reflect the typing text style
    // Sync UI
    
    NSDictionary *typingAttributes = [self.textView typingAttributes];
    KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithAttributes:typingAttributes];
    KBTFontFamilyDescriptor *fontFamilyDescriptor = [styleDescriptor fontFamilyDescriptor];
    
    fontViewController_.selectedFamilyName = fontFamilyDescriptor.familyName;
    
    if (fontFamilyDescriptor.supportsBoldTrait)
    {
        boldToggleButton_.enabled = YES;
        boldToggleButton_.selected = styleDescriptor.boldTraitEnabled;
    }
    else
    {
        boldToggleButton_.enabled = NO;
    }
    
    if (fontFamilyDescriptor.supportsItalicTrait)
    {
        italicToggleButton_.enabled = YES;
        italicToggleButton_.selected = styleDescriptor.italicTraitEnabled;
    }
    else
    {
        italicToggleButton_.enabled = NO;
    }

    underlineToggleButton_.selected = styleDescriptor.underlineEnabled;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Responding to Actions

- (void)boldToggleChanged:(KUIToggleButton *)toggleButton
{
    NSString *familyName = fontViewController_.selectedFamilyName;
    KBTFontFamilyDescriptor *fontFamilyDescriptor = [KBTFontFamilyDescriptor fontFamilyDescriptorWithFamilyName:familyName];
    
    if (fontFamilyDescriptor.supportsItalicTrait && !fontFamilyDescriptor.supportsBoldItalicTrait)
    {
        italicToggleButton_.selected = NO;
    }
    
    [self updateTextViewTextAttributes];
}

- (void)italicToggleChanged:(KUIToggleButton *)toggleButton
{
    NSString *familyName = fontViewController_.selectedFamilyName;
    KBTFontFamilyDescriptor *fontFamilyDescriptor = [KBTFontFamilyDescriptor fontFamilyDescriptorWithFamilyName:familyName];
    
    if (fontFamilyDescriptor.supportsBoldTrait && !fontFamilyDescriptor.supportsBoldItalicTrait)
    {
        boldToggleButton_.selected = NO;
    }
    
    [self updateTextViewTextAttributes];
}

- (void)underlineToggleChanged:(KUIToggleButton *)toggleButton
{
    [self updateTextViewTextAttributes];
}

- (void)fontPressed:(UIButton *)button
{
    if (fontPopoverController_.isPopoverVisible)
    {
        [fontPopoverController_ dismissPopoverAnimated:YES];
    }
    else
    {
        UIBarButtonItem *fontItem = [[self.toolbar items] objectAtIndex:3];
        [fontPopoverController_ presentPopoverFromBarButtonItem:fontItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (void)debugTextPressed:(UIBarButtonItem *)item
{
    textView_.text = NKTTestText();
}

- (void)debugPressed:(UIBarButtonItem *)item
{
    NSString *description = KBTDebugDescriptionForAttributedString(textView_.text, NO);
    KBCLogDebug(description);
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
