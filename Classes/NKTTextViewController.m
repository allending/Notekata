//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTTextViewController.h"
#import "KobaText.h"
#import "NKTTestText.h"

@interface NKTTextViewController()

#pragma mark View Lifecycle and Memory Management

@property (nonatomic, retain) KUIToggleButton *boldToggleButton;
@property (nonatomic, retain) KUIToggleButton *italicToggleButton;
@property (nonatomic, retain) KUIToggleButton *underlineToggleButton;
@property (nonatomic, retain) UIButton *fontButton;
@property (nonatomic, retain) UIBarButtonItem *fontToolbarItem;
@property (nonatomic, retain) NKTFontPickerViewController *fontPickerViewController;
@property (nonatomic, retain) UIPopoverController *fontPopoverController;

- (UIButton *)borderedButtonForToolbar;
- (void)createToolbarItems;

#pragma mark Managing Text Attributes

- (NSDictionary *)activeTextAttributes;
- (void)updateTextViewTextAttributes;

#pragma mark Responding to Actions

- (void)updateToolbarStyleItems;

- (void)boldToggleChanged:(KUIToggleButton *)toggleButton;
- (void)italicToggleChanged:(KUIToggleButton *)toggleButton;
- (void)underlineToggleChanged:(KUIToggleButton *)toggleButton;
- (void)fontButtonPressed:(UIButton *)button;

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
@synthesize fontButton = fontButton_;
@synthesize fontToolbarItem = fontToolbarItem_;
@synthesize fontPickerViewController = fontPickerViewController_;
@synthesize fontPopoverController = fontPopoverController_;

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
    [fontToolbarItem_ release];
    [fontPickerViewController_ release];
    [fontPopoverController_ release];
    [super dealloc];
}
//--------------------------------------------------------------------------------------------------

#pragma mark View Lifecycle and Memory Management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set the background pattern for the edge view
    UIImage *edgePattern = [UIImage imageNamed:@"RedCoverPattern.png"];
    self.edgeView.backgroundColor = [UIColor colorWithPatternImage:edgePattern];
    
    // Set the background pattern that will show through the text view
    UIImage *backgroundPattern = [UIImage imageNamed:@"CreamPaperPattern.png"];
    self.view.backgroundColor = [UIColor colorWithPatternImage:backgroundPattern];
    
    // Create the font picker view controllers
    fontPickerViewController_ = [[NKTFontPickerViewController alloc] init];
    fontPickerViewController_.delegate = self;
    fontPickerViewController_.selectedFontFamilyName = @"Helvetica Neue";
    fontPickerViewController_.selectedFontSize = 16;
    fontPopoverController_ = [[UIPopoverController alloc] initWithContentViewController:fontPickerViewController_];
    fontPopoverController_.popoverContentSize = CGSizeMake(320.0, 420.0);
    
    // Set up the text view
    textView_.delegate = self;
    // TODO: Sync UI (make this better)
    [self textViewDidChangeSelection:nil];
    
    [self createToolbarItems];
    
    [self updateToolbarStyleItems];
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
    self.fontButton = nil;
    self.fontToolbarItem = nil;
    self.fontPickerViewController = nil;
    self.fontPopoverController = nil;
}

- (UIButton *)borderedButtonForToolbar
{
    UIImage *buttonImage = [UIImage imageNamed:@"DarkButton.png"];
    UIImage *buttonBackground = [buttonImage stretchableImageWithLeftCapWidth:4.0 topCapHeight:5.0];
    UIColor *highlightedColor = [UIColor colorWithRed:0.12 green:0.57 blue:0.92 alpha:1.0];
    UIColor *selectedColor = [UIColor colorWithRed:0.1 green:0.5 blue:0.9 alpha:1.0];
    UIColor *titleColor = [UIColor lightTextColor];
    UIColor *disabledColor = [UIColor darkGrayColor];
    UIFont *buttonFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:12.0];
    UIEdgeInsets buttonInsets = UIEdgeInsetsMake(6.0, 8.0, 6.0, 8.0);
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setBackgroundImage:buttonBackground forState:UIControlStateNormal];
    [button setTitleColor:highlightedColor forState:UIControlStateHighlighted|UIControlStateNormal];
    [button setTitleColor:highlightedColor forState:UIControlStateHighlighted|UIControlStateSelected];
    [button setTitleColor:selectedColor forState:UIControlStateSelected];
    [button setTitleColor:titleColor forState:UIControlStateNormal];
    [button setTitleColor:disabledColor forState:UIControlStateDisabled];
    button.titleLabel.font = buttonFont;
    button.titleEdgeInsets = buttonInsets;
    return button;
}

- (void)createToolbarItems
{
    // Title item (placed over the toolbar, not in it)
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 44.0)];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.text = @"The Expedition";
    titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0];
    titleLabel.textColor = [UIColor lightTextColor];
    titleLabel.textAlignment = UITextAlignmentCenter;
    titleLabel.center = self.toolbar.center;
    [self.view addSubview:titleLabel];
    [titleLabel release];
    
    NSMutableArray *toolbarItems = [NSMutableArray array];
    
    // Notebook item
    UIButton *notebookButton = [self borderedButtonForToolbar];
    [notebookButton setTitle:@"My Documents" forState:UIControlStateNormal];
    notebookButton.frame = CGRectMake(0.0, 0.0, 120.0, 30.0);
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
    fontButton_ = [[self borderedButtonForToolbar] retain];
    [fontButton_ addTarget:self
                    action:@selector(fontButtonPressed:)
          forControlEvents:UIControlEventTouchUpInside];
    fontButton_.frame = CGRectMake(0.0, 0.0, 120.0, 30.0);
    fontToolbarItem_ = [[UIBarButtonItem alloc] initWithCustomView:fontButton_];
    [toolbarItems addObject:fontToolbarItem_];
    
    // Bold item
    boldToggleButton_ = [[KUIToggleButton alloc] initWithStyle:KUIToggleButtonStyleTextDark];
    [boldToggleButton_ addTarget:self
                          action:@selector(boldToggleChanged:)
                forControlEvents:UIControlEventValueChanged];
    [boldToggleButton_ setTitle:@"B" forState:UIControlStateNormal];
    boldToggleButton_.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0];
    boldToggleButton_.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
    UIBarButtonItem *boldToggleItem = [[UIBarButtonItem alloc] initWithCustomView:boldToggleButton_];
    [toolbarItems addObject:boldToggleItem];
    [boldToggleItem release];
    
    // Italic item
    italicToggleButton_ = [[KUIToggleButton alloc] initWithStyle:KUIToggleButtonStyleTextDark];
    [italicToggleButton_ addTarget:self
                            action:@selector(italicToggleChanged:)
                  forControlEvents:UIControlEventValueChanged];
    [italicToggleButton_ setTitle:@"I" forState:UIControlStateNormal];
    italicToggleButton_.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Italic" size:14.0];
    italicToggleButton_.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
    UIBarButtonItem *italicToggleItem = [[UIBarButtonItem alloc] initWithCustomView:italicToggleButton_];
    [toolbarItems addObject:italicToggleItem];
    [italicToggleItem release];
    
    // Underline item
    underlineToggleButton_ = [[KUIToggleButton alloc] initWithStyle:KUIToggleButtonStyleTextDark];
    [underlineToggleButton_ addTarget:self
                               action:@selector(underlineToggleChanged:)
                     forControlEvents:UIControlEventValueChanged];
    [underlineToggleButton_ setTitle:@"U" forState:UIControlStateNormal];
    underlineToggleButton_.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:14.0];
    underlineToggleButton_.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
    UIBarButtonItem *underlineToggleItem = [[UIBarButtonItem alloc] initWithCustomView:underlineToggleButton_];
    [toolbarItems addObject:underlineToggleItem];
    [underlineToggleItem release];
    
    // Set the tool bar items
    self.toolbar.items = toolbarItems;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Managing Loupes

- (UIColor *)loupeFillColor
{
    return self.view.backgroundColor;
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
                                                                                           size:fontPickerViewController_.selectedFontSize
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

#pragma mark Responding to Font Changes

- (void)fontPickerViewController:(NKTFontPickerViewController *)fontPickerViewController
               didSelectFontSize:(CGFloat)fontSize
{
    // Push to text view
    [self updateTextViewTextAttributes];
    // TODO: Don't need to change traits support
    // [self textViewDidChangeSelection:nil];
    
    NSString *fontButtonTitle = [NSString stringWithFormat:@"%@ %d",
                                                           fontPickerViewController.selectedFontFamilyName,
                                                           (NSInteger)fontPickerViewController.selectedFontSize];
    [fontButton_ setTitle:fontButtonTitle forState:UIControlStateNormal];
}

- (void)fontPickerViewController:(NKTFontPickerViewController *)fontPickerViewController
         didSelectFontFamilyName:(NSString *)fontFamilyName
{
    // Push to text view
    [self updateTextViewTextAttributes];
    // TODO: change bold, italic, etc to reflect support by font
    [self textViewDidChangeSelection:nil];
    
    NSString *fontButtonTitle = [NSString stringWithFormat:@"%@ %d",
                                 fontPickerViewController.selectedFontFamilyName,
                                 (NSInteger)fontPickerViewController.selectedFontSize];
    [fontButton_ setTitle:fontButtonTitle forState:UIControlStateNormal];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Responding to Editing Notifications

- (void)updateToolbarStyleItems
{    
    if (textView_.isFirstResponder)
    {
        fontButton_.enabled = YES;
        
        NSDictionary *typingAttributes = [self.textView typingAttributes];
        KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithAttributes:typingAttributes];
        KBTFontFamilyDescriptor *fontFamilyDescriptor = [styleDescriptor fontFamilyDescriptor];
        
        fontPickerViewController_.selectedFontFamilyName = fontFamilyDescriptor.familyName;
        fontPickerViewController_.selectedFontSize = styleDescriptor.fontSize;
        
        NSString *fontButtonTitle = [NSString stringWithFormat:@"%@ %d",
                                                               fontFamilyDescriptor.familyName,
                                                               (NSUInteger)styleDescriptor.fontSize];
        [fontButton_ setTitle:fontButtonTitle forState:UIControlStateNormal];     
        
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
        
        underlineToggleButton_.enabled = YES;
        underlineToggleButton_.selected = styleDescriptor.underlineEnabled;
    }
    else
    {
        fontButton_.enabled = NO;
        boldToggleButton_.enabled = NO;
        boldToggleButton_.selected = NO;
        italicToggleButton_.enabled = NO;
        italicToggleButton_.selected = NO;
        underlineToggleButton_.enabled = NO;
        underlineToggleButton_.selected = NO;
    }
}

- (void)textViewDidBeginEditing:(NKTTextView *)textView
{
    [self updateToolbarStyleItems];
}

- (void)textViewDidEndEditing:(NKTTextView *)textView
{
    [self updateToolbarStyleItems];
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
    [self updateToolbarStyleItems];
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

- (void)fontButtonPressed:(UIButton *)button
{
    if (fontPopoverController_.isPopoverVisible)
    {
        [fontPopoverController_ dismissPopoverAnimated:YES];
    }
    else
    {
        [fontPopoverController_ presentPopoverFromBarButtonItem:fontToolbarItem_
                                       permittedArrowDirections:UIPopoverArrowDirectionAny
                                                       animated:YES];
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
