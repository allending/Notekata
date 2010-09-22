//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTTextViewController.h"
#import "KobaText.h"
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
    [fontButton_ release];
    [fontPickerViewController_ release];
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
    
    fontPickerViewController_ = [[NKTFontPickerViewController alloc] init];
    fontPickerViewController_.delegate = self;
    fontPickerViewController_.selectedFontFamilyName = @"Helvetica Neue";
    
    fontPopoverController_ = [[UIPopoverController alloc] initWithContentViewController:fontPickerViewController_];
    CGSize popoverContentSize = fontPopoverController_.popoverContentSize;
    popoverContentSize.height = 420.0;
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
    // Title item
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 44.0)];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.text = @"The Expedition";
    titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:12.0];
    titleLabel.textColor = [UIColor lightTextColor];
    titleLabel.center = self.toolbar.center;
    titleLabel.textAlignment = UITextAlignmentCenter;
    [self.view addSubview:titleLabel];
    [titleLabel release];
    
//    UIBarButtonItem *titleItem = [[UIBarButtonItem alloc] initWithCustomView:titleLabel];
//    [titleLabel release];
//    [toolbarItems addObject:titleItem];
//    [titleItem release];
    
    NSMutableArray *toolbarItems = [NSMutableArray array];
    
    // Notebook item
//    UIBarButtonItem *notebookItem = [[UIBarButtonItem alloc] initWithTitle:@"Notebook"
//                                                                     style:UIBarButtonItemStyleBordered
//                                                                    target:nil
//                                                                    action:nil];
//    [toolbarItems addObject:notebookItem];
//    [notebookItem release];
    
    
    // Notebook item
    UIButton *notebookButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [notebookButton setTitleColor:[UIColor colorWithRed:0.12 green:0.57 blue:0.92 alpha:1.0] forState:UIControlStateHighlighted|UIControlStateNormal];
    [notebookButton setTitleColor:[UIColor colorWithRed:0.12 green:0.57 blue:0.92 alpha:1.0] forState:UIControlStateHighlighted|UIControlStateSelected];
    [notebookButton setTitleColor:[UIColor colorWithRed:0.1 green:0.5 blue:0.9 alpha:1.0] forState:UIControlStateSelected];
    [notebookButton setTitleColor:[UIColor lightTextColor] forState:UIControlStateNormal];
    [notebookButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateDisabled];
    [notebookButton setTitle:@"My Documents" forState:UIControlStateNormal];
    notebookButton.clipsToBounds = YES;
    notebookButton.titleEdgeInsets = UIEdgeInsetsMake(6.0, 8.0, 6.0, 8.0);
    notebookButton.titleLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    notebookButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:12.0];
    UIImage *backgroundImage = [[UIImage imageNamed:@"DarkButton.png"] stretchableImageWithLeftCapWidth:4.0 topCapHeight:5.0];
    [notebookButton setBackgroundImage:backgroundImage forState:UIControlStateNormal];
    notebookButton.frame = CGRectMake(0.0, 10.0, 120.0, 30.0);
    UIBarButtonItem *notebookItem = [[UIBarButtonItem alloc] initWithCustomView:notebookButton];
    [toolbarItems addObject:notebookItem];
    [notebookItem release];
    
    // Left flexible space
    UIBarButtonItem *leftSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                               target:nil
                                                                               action:nil];
    [toolbarItems addObject:leftSpace];
    [leftSpace release];
    
    // Font item
    fontButton_ = [UIButton buttonWithType:UIButtonTypeCustom];
    [fontButton_ setTitleColor:[UIColor colorWithRed:0.12 green:0.57 blue:0.92 alpha:1.0] forState:UIControlStateHighlighted|UIControlStateNormal];
    [fontButton_ setTitleColor:[UIColor colorWithRed:0.12 green:0.57 blue:0.92 alpha:1.0] forState:UIControlStateHighlighted|UIControlStateSelected];
    [fontButton_ setTitleColor:[UIColor colorWithRed:0.1 green:0.5 blue:0.9 alpha:1.0] forState:UIControlStateSelected];
    [fontButton_ setTitleColor:[UIColor lightTextColor] forState:UIControlStateNormal];
    [fontButton_ setTitleColor:[UIColor darkGrayColor] forState:UIControlStateDisabled];
    [fontButton_ addTarget:self action:@selector(fontPressed:) forControlEvents:UIControlEventTouchUpInside];
    [fontButton_ setTitle:@"Futura - 16" forState:UIControlStateNormal];
    fontButton_.clipsToBounds = YES;
    fontButton_.titleEdgeInsets = UIEdgeInsetsMake(6.0, 8.0, 6.0, 8.0);
    fontButton_.titleLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    fontButton_.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:12.0];
    backgroundImage = [[UIImage imageNamed:@"DarkButton.png"] stretchableImageWithLeftCapWidth:4.0 topCapHeight:5.0];
    [fontButton_ setBackgroundImage:backgroundImage forState:UIControlStateNormal];
    fontButton_.frame = CGRectMake(0.0, 0.0, 120.0, 30.0);
    UIBarButtonItem *fontItem = [[UIBarButtonItem alloc] initWithCustomView:fontButton_];
    [toolbarItems addObject:fontItem];
    [fontItem release];
    
    // Bold item
    boldToggleButton_ = [[KUIToggleButton alloc] initWithStyle:KUIToggleButtonStyleTextDark];
    [boldToggleButton_ addTarget:self action:@selector(boldToggleChanged:) forControlEvents:UIControlEventValueChanged];
    [boldToggleButton_ setTitle:@"B" forState:UIControlStateNormal];
    boldToggleButton_.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0];
    boldToggleButton_.frame = CGRectMake(0.0, 0.0, 36.0, 36.0);
    UIBarButtonItem *boldToggleItem = [[UIBarButtonItem alloc] initWithCustomView:boldToggleButton_];
    [toolbarItems addObject:boldToggleItem];
    [boldToggleItem release];
    
    // Italic item
    italicToggleButton_ = [[KUIToggleButton alloc] initWithStyle:KUIToggleButtonStyleTextDark];
    [italicToggleButton_ addTarget:self action:@selector(italicToggleChanged:) forControlEvents:UIControlEventValueChanged];
    [italicToggleButton_ setTitle:@"I" forState:UIControlStateNormal];
    italicToggleButton_.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Italic" size:14.0];
    italicToggleButton_.frame = CGRectMake(0.0, 0.0, 36.0, 36.0);
    UIBarButtonItem *italicToggleItem = [[UIBarButtonItem alloc] initWithCustomView:italicToggleButton_];
    [toolbarItems addObject:italicToggleItem];
    [italicToggleItem release];
    
    // Underline item
    underlineToggleButton_ = [[KUIToggleButton alloc] initWithStyle:KUIToggleButtonStyleTextDark];
    [underlineToggleButton_ addTarget:self action:@selector(underlineToggleChanged:) forControlEvents:UIControlEventValueChanged];
    [underlineToggleButton_ setTitle:@"U" forState:UIControlStateNormal];
    underlineToggleButton_.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:14.0];
    underlineToggleButton_.frame = CGRectMake(0.0, 0.0, 36.0, 36.0);
    UIBarButtonItem *underlineToggleItem = [[UIBarButtonItem alloc] initWithCustomView:underlineToggleButton_];
    [toolbarItems addObject:underlineToggleItem];
    [underlineToggleItem release];
    
    // Set the tool bar items
    self.toolbar.items = toolbarItems;
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
    KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithFontFamilyName:fontPickerViewController_.selectedFontFamilyName
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

- (void)fontPickerViewController:(NKTFontPickerViewController *)fontPickerViewController didSelectFamilyName:(NSString *)familyName
{
    [self updateTextViewTextAttributes];
    // Sync UI
    [self textViewDidChangeSelection:nil];
    
    //fontButton_.titleLabel.font = [UIFont fontWithName:familyName size:18.0];
    [fontButton_ setTitle:[NSString stringWithFormat:@"%@ 12", familyName] forState:UIControlStateNormal];
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

// TODO: make stub for updating font button

// on initial creation
// - update buttons to sync state with the typing attributes on the current text view
// 
// when change happens through ui toolbar
// - update buttons (bold, italic, font, underline) to sync state with the individual change
// - push the individual change to the text view
//
// when change happens through text view
// - update buttons (bold, italic, font, underline) to sync state with the typing attributes
// 

- (void)textViewDidChangeSelection:(NKTTextView *)textView
{
    // Update the UI state to reflect the typing text style
    // Sync UI
    
    NSDictionary *typingAttributes = [self.textView typingAttributes];
    KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithAttributes:typingAttributes];
    KBTFontFamilyDescriptor *fontFamilyDescriptor = [styleDescriptor fontFamilyDescriptor];
    
    fontPickerViewController_.selectedFontFamilyName = fontFamilyDescriptor.familyName;
    
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
    NSString *familyName = fontPickerViewController_.selectedFontFamilyName;
    KBTFontFamilyDescriptor *fontFamilyDescriptor = [KBTFontFamilyDescriptor fontFamilyDescriptorWithFamilyName:familyName];
    
    if (fontFamilyDescriptor.supportsItalicTrait && !fontFamilyDescriptor.supportsBoldItalicTrait)
    {
        italicToggleButton_.selected = NO;
    }
    
    [self updateTextViewTextAttributes];
}

- (void)italicToggleChanged:(KUIToggleButton *)toggleButton
{
    NSString *familyName = fontPickerViewController_.selectedFontFamilyName;
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
