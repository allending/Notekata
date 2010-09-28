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

#pragma mark Configuring the Page Style

- (void)applyPageStyle;

#pragma mark Managing Text Attributes

- (NSDictionary *)activeTextAttributes;

#pragma mark Responding to Editing Notifications

- (void)updateToolbarStyleItems;

#pragma mark Responding to Actions

- (void)boldToggleChanged:(KUIToggleButton *)toggleButton;
- (void)italicToggleChanged:(KUIToggleButton *)toggleButton;
- (void)underlineToggleChanged:(KUIToggleButton *)toggleButton;
- (void)fontButtonPressed:(UIButton *)button;

#pragma mark Changing Text Attributes

- (NSDictionary *)attributesByAddingBoldTraitToAttributes:(NSDictionary *)attributes;
- (NSDictionary *)attributesByRemovingBoldTraitFromAttributes:(NSDictionary *)attributes;
- (NSDictionary *)attributesByAddingItalicTraitToAttributes:(NSDictionary *)attributes;
- (NSDictionary *)attributesByRemovingItalicTraitFromAttributes:(NSDictionary *)attributes;
- (NSDictionary *)attributesByAddingUnderlineToAttributes:(NSDictionary *)attributes;
- (NSDictionary *)attributesByRemovingUnderlineFromAttributes:(NSDictionary *)attributes;
- (NSDictionary *)attributesBySettingFontSizeOfAttributes:(NSDictionary *)attributes;
- (NSDictionary *)attributesBySettingFontFamilyNameOfAttributes:(NSDictionary *)attributes;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------

@implementation NKTTextViewController

@synthesize toolbar = toolbar_;
@synthesize titleLabel = titleLabel_;
@synthesize edgeView = edgeView_;
@synthesize textView = textView_;
@synthesize boldToggleButton = boldToggleButton_;
@synthesize italicToggleButton = italicToggleButton_;
@synthesize underlineToggleButton = underlineToggleButton_;
@synthesize fontButton = fontButton_;
@synthesize fontToolbarItem = fontToolbarItem_;
@synthesize fontPickerViewController = fontPickerViewController_;
@synthesize fontPopoverController = fontPopoverController_;
@synthesize pageStyle = pageStyle_;

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
    {
        pageStyle_ = NKTPageStyleCreamRuledVerticalMargin;
    }
    
    return self;
}

- (void)awakeFromNib
{
    pageStyle_ = NKTPageStyleCreamRuledVerticalMargin;
}

- (void)dealloc
{
    [toolbar_ release];
    [titleLabel_ release];
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
    KBCLogTrace();
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
    
    // Set the title that shows up on the toolbar
    self.titleLabel.text = @"The Expedition";
    
    // Set up the text view
    textView_.delegate = self;
    [self applyPageStyle];
    
    [self createToolbarItems];
    [self updateToolbarStyleItems];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.toolbar = nil;
    self.titleLabel = nil;
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
    NSMutableArray *toolbarItems = [NSMutableArray array];
    
    // Notebook item
    UIButton *notebookButton = [self borderedButtonForToolbar];
    [notebookButton setTitle:@"My Documents" forState:UIControlStateNormal];
    notebookButton.frame = CGRectMake(0.0, 0.0, 120.0, 30.0);
    UIBarButtonItem *notebookItem = [[UIBarButtonItem alloc] initWithCustomView:notebookButton];
    [toolbarItems addObject:notebookItem];
    [notebookItem release];
    
    // Page style item
    UIButton *pageStyleButton = [self borderedButtonForToolbar];
    [pageStyleButton setTitle:@"Page Style" forState:UIControlStateNormal];
    [pageStyleButton addTarget:self
                        action:@selector(pageStylePressed:)
              forControlEvents:UIControlEventTouchUpInside];
    pageStyleButton.frame = CGRectMake(0.0, 0.0, 120.0, 30.0);
    UIBarButtonItem *pageStyleItem = [[UIBarButtonItem alloc] initWithCustomView:pageStyleButton];
    [toolbarItems addObject:pageStyleItem];
    [pageStyleItem release];
    
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

#pragma mark Configuring the View Rotation Settings

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Configuring the Page Style

- (void)setPageStyle:(NKTPageStyle)pageStyle
{
    if (pageStyle_ == pageStyle)
    {
        return;
    }
    
    pageStyle_ = pageStyle;
    [self applyPageStyle];
}

- (void)applyPageStyle
{
    switch (pageStyle_)
    {
        case NKTPageStylePlain:
        {
            UIImage *image = [UIImage imageNamed:@"PlainPaperPattern2.png"];
            self.view.backgroundColor = [UIColor colorWithPatternImage:image];
            self.textView.margins = UIEdgeInsetsMake(60.0, 60.0, 60.0, 60.0);
            self.textView.horizontalRulesEnabled = NO;
            self.textView.verticalMarginEnabled = NO;
            break;
        }
        case NKTPageStylePlainRuled:
        {
            UIImage *image = [UIImage imageNamed:@"PlainPaperPattern2.png"];
            self.view.backgroundColor = [UIColor colorWithPatternImage:image];
            self.textView.margins = UIEdgeInsetsMake(60.0, 60.0, 60.0, 60.0);
            self.textView.horizontalRulesEnabled = YES;
            self.textView.horizontalRuleColor = [UIColor colorWithRed:0.72 green:0.72 blue:0.72 alpha:1.0];
            self.textView.verticalMarginEnabled = NO;
            break;
        }
        case NKTPageStylePlainRuledVerticalMargin:
        {
            UIImage *image = [UIImage imageNamed:@"PlainPaperPattern2.png"];
            self.view.backgroundColor = [UIColor colorWithPatternImage:image];
            self.textView.margins = UIEdgeInsetsMake(60.0, 80.0, 60.0, 60.0);
            self.textView.horizontalRulesEnabled = YES;
            self.textView.horizontalRuleColor = [UIColor colorWithRed:0.69 green:0.73 blue:0.85 alpha:1.0];
            self.textView.verticalMarginEnabled = YES;
            self.textView.verticalMarginColor = [UIColor colorWithRed:0.7 green:0.3 blue:0.29 alpha:1.0];
            self.textView.verticalMarginInset = 60.0;
            break;
        }
        case NKTPageStyleCream:
        {
            UIImage *image = [UIImage imageNamed:@"CreamPaperPattern.png"];
            self.view.backgroundColor = [UIColor colorWithPatternImage:image];
            self.textView.margins = UIEdgeInsetsMake(60.0, 60.0, 60.0, 60.0);
            self.textView.horizontalRulesEnabled = NO;
            self.textView.verticalMarginEnabled = NO;
            break;
        }
        case NKTPageStyleCreamRuled:
        {
            UIImage *image = [UIImage imageNamed:@"CreamPaperPattern.png"];
            self.view.backgroundColor = [UIColor colorWithPatternImage:image];
            self.textView.margins = UIEdgeInsetsMake(60.0, 60.0, 60.0, 60.0);
            self.textView.horizontalRulesEnabled = YES;
            self.textView.horizontalRuleColor = [UIColor colorWithRed:0.72 green:0.72 blue:0.59 alpha:1.0];
            self.textView.verticalMarginEnabled = NO;
            break;
        }
        case NKTPageStyleCreamRuledVerticalMargin:
        {
            UIImage *image = [UIImage imageNamed:@"CreamPaperPattern.png"];
            self.view.backgroundColor = [UIColor colorWithPatternImage:image];
            self.textView.margins = UIEdgeInsetsMake(60.0, 80.0, 60.0, 60.0);
            self.textView.horizontalRulesEnabled = YES;
            self.textView.horizontalRuleColor = [UIColor colorWithRed:0.72 green:0.72 blue:0.59 alpha:1.0];
            self.textView.verticalMarginEnabled = YES;
            self.textView.verticalMarginColor = [UIColor colorWithRed:0.7 green:0.3 blue:0.29 alpha:1.0];
            self.textView.verticalMarginInset = 60.0;
            break;
        }
        default:
            KBCLogWarning(@"uknown page style, ignoring");
            break;
    }
}

//--------------------------------------------------------------------------------------------------

#pragma mark Managing Loupes

- (UIColor *)loupeFillColor
{
    return self.view.backgroundColor;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Managing Text Attributes

- (NSDictionary *)activeTextAttributes
{
    KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithFontFamilyName:fontPickerViewController_.selectedFontFamilyName
                                                                                       fontSize:fontPickerViewController_.selectedFontSize
                                                                                           bold:boldToggleButton_.selected
                                                                                         italic:italicToggleButton_.selected
                                                                                     underlined:underlineToggleButton_.selected];
    return [styleDescriptor attributes];
}

- (NSDictionary *)defaultTextAttributes
{
    return [self activeTextAttributes];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Responding to Editing Notifications

- (void)updateToolbarStyleItems
{
    if ([textView_ isFirstResponder])
    {
        UITextRange *selectedTextRange = textView_.selectedTextRange;
        NSDictionary *inputTextAttributes = self.textView.inputTextAttributes;
        KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithAttributes:inputTextAttributes];
        fontButton_.enabled = YES;
        fontPickerViewController_.selectedFontFamilyName = styleDescriptor.fontFamilyName;
        fontPickerViewController_.selectedFontSize = styleDescriptor.fontSize;
        boldToggleButton_.enabled = !selectedTextRange.empty || styleDescriptor.fontFamilySupportsBoldTrait;
        boldToggleButton_.selected = boldToggleButton_.enabled && styleDescriptor.fontIsBold;
        italicToggleButton_.enabled = !selectedTextRange.empty || styleDescriptor.fontFamilySupportsItalicTrait;
        italicToggleButton_.selected = italicToggleButton_.enabled && styleDescriptor.fontIsItalic;
        underlineToggleButton_.enabled = YES;
        underlineToggleButton_.selected = styleDescriptor.textIsUnderlined;
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
     
    // Update the font button title regardless of editing state
    NSString *fontButtonTitle = [NSString stringWithFormat:@"%@ %d",
                                                           fontPickerViewController_.selectedFontFamilyName,
                                                           fontPickerViewController_.selectedFontSize];
    [fontButton_ setTitle:fontButtonTitle forState:UIControlStateNormal];
}

- (void)textViewDidBeginEditing:(NKTTextView *)textView
{
    [self updateToolbarStyleItems];
}

- (void)textViewDidEndEditing:(NKTTextView *)textView
{
    // The popover might still be visible when editing ends
    if (fontPopoverController_.popoverVisible)
    {
        [fontPopoverController_ dismissPopoverAnimated:YES];
    }
    
    [self updateToolbarStyleItems];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Responding to Text Changes

- (void)textViewDidChange:(NKTTextView *)textView
{
    if (fontPopoverController_.popoverVisible)
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

- (void)pageStylePressed:(UIButton *)button
{
    self.pageStyle = (self.pageStyle + 1) % 6;
}

- (void)fontButtonPressed:(UIButton *)button
{
    if (fontPopoverController_.popoverVisible)
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

- (void)fontPickerViewController:(NKTFontPickerViewController *)fontPickerViewController
         didSelectFontFamilyName:(NSString *)fontFamilyName
{
    [textView_ styleTextRange:textView_.selectedTextRange
                   withTarget:self
                     selector:@selector(attributesBySettingFontFamilyNameOfAttributes:)];
    
    NSString *fontButtonTitle = [NSString stringWithFormat:@"%@ %d",
                                 fontPickerViewController.selectedFontFamilyName,
                                 (NSInteger)fontPickerViewController.selectedFontSize];
    [fontButton_ setTitle:fontButtonTitle forState:UIControlStateNormal];
    
    textView_.inputTextAttributes = [self activeTextAttributes];
    [self updateToolbarStyleItems];
}

- (void)fontPickerViewController:(NKTFontPickerViewController *)fontPickerViewController
               didSelectFontSize:(CGFloat)fontSize
{
    [textView_ styleTextRange:textView_.selectedTextRange
                   withTarget:self
                     selector:@selector(attributesBySettingFontSizeOfAttributes:)];
    
    NSString *fontButtonTitle = [NSString stringWithFormat:@"%@ %d",
                                 fontPickerViewController.selectedFontFamilyName,
                                 (NSInteger)fontPickerViewController.selectedFontSize];
    [fontButton_ setTitle:fontButtonTitle forState:UIControlStateNormal];
    
    textView_.inputTextAttributes = [self activeTextAttributes];
}

- (void)boldToggleChanged:(KUIToggleButton *)toggleButton
{
    NSString *fontFamilyName = fontPickerViewController_.selectedFontFamilyName;
    KBTFontFamilyDescriptor *fontFamilyDescriptor = [KBTFontFamilyDescriptor fontFamilyDescriptorWithFamilyName:fontFamilyName];
    
    // Deselect the italic button if the font family supports bold or italic traits exclusively
    if (fontFamilyDescriptor.supportsItalicTrait && !fontFamilyDescriptor.supportsBoldItalicTrait)
    {
        italicToggleButton_.selected = NO;
    }
    
    if (toggleButton.selected)
    {
        [textView_ styleTextRange:textView_.selectedTextRange
                       withTarget:self
                         selector:@selector(attributesByAddingBoldTraitToAttributes:)];
    }
    else
    {
        [textView_ styleTextRange:textView_.selectedTextRange
                       withTarget:self
                         selector:@selector(attributesByRemovingBoldTraitFromAttributes:)];
    }
    
    textView_.inputTextAttributes = [self activeTextAttributes];
}

- (void)italicToggleChanged:(KUIToggleButton *)toggleButton
{
    NSString *familyName = fontPickerViewController_.selectedFontFamilyName;
    KBTFontFamilyDescriptor *fontFamilyDescriptor = [KBTFontFamilyDescriptor fontFamilyDescriptorWithFamilyName:familyName];
    
    // Deselect the bold button if the font family supports bold or italic traits exclusively
    if (fontFamilyDescriptor.supportsBoldTrait && !fontFamilyDescriptor.supportsBoldItalicTrait)
    {
        boldToggleButton_.selected = NO;
    }
    
    if (toggleButton.selected)
    {
        [textView_ styleTextRange:textView_.selectedTextRange
                       withTarget:self
                         selector:@selector(attributesByAddingItalicTraitToAttributes:)];
    }
    else
    {
        [textView_ styleTextRange:textView_.selectedTextRange
                       withTarget:self
                         selector:@selector(attributesByRemovingItalicTraitFromAttributes:)];
    }
    
    textView_.inputTextAttributes = [self activeTextAttributes];
}

- (void)underlineToggleChanged:(KUIToggleButton *)toggleButton
{
    if (underlineToggleButton_.selected)
    {
        [textView_ styleTextRange:textView_.selectedTextRange
                       withTarget:self
                         selector:@selector(attributesByAddingUnderlineToAttributes:)];
    }
    else
    {
        [textView_ styleTextRange:textView_.selectedTextRange
                       withTarget:self
                         selector:@selector(attributesByRemovingUnderlineFromAttributes:)];
    }
    
    textView_.inputTextAttributes = [self activeTextAttributes];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Changing Text Attributes

// These methods are meant to be used as callbacks by the text view when it is requested to style
// text within a range.

- (NSDictionary *)attributesByAddingBoldTraitToAttributes:(NSDictionary *)attributes
{
    KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithAttributes:attributes];
    KBTStyleDescriptor *newStyleDescriptor = [styleDescriptor styleDescriptorByEnablingBoldTrait];
    return [newStyleDescriptor attributes];
}

- (NSDictionary *)attributesByRemovingBoldTraitFromAttributes:(NSDictionary *)attributes
{
    KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithAttributes:attributes];
    KBTStyleDescriptor *newStyleDescriptor = [styleDescriptor styleDescriptorByDisablingBoldTrait];
    return [newStyleDescriptor attributes];
}

- (NSDictionary *)attributesByAddingItalicTraitToAttributes:(NSDictionary *)attributes
{
    KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithAttributes:attributes];
    KBTStyleDescriptor *newStyleDescriptor = [styleDescriptor styleDescriptorByEnablingItalicTrait];
    return [newStyleDescriptor attributes];
}

- (NSDictionary *)attributesByRemovingItalicTraitFromAttributes:(NSDictionary *)attributes
{
    KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithAttributes:attributes];
    KBTStyleDescriptor *newStyleDescriptor = [styleDescriptor styleDescriptorByDisablingItalicTrait];
    return [newStyleDescriptor attributes];
}

- (NSDictionary *)attributesByAddingUnderlineToAttributes:(NSDictionary *)attributes
{
    KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithAttributes:attributes];
    KBTStyleDescriptor *newStyleDescriptor = [styleDescriptor styleDescriptorByEnablingUnderline];
    return [newStyleDescriptor attributes];
}

- (NSDictionary *)attributesByRemovingUnderlineFromAttributes:(NSDictionary *)attributes
{
    KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithAttributes:attributes];
    KBTStyleDescriptor *newStyleDescriptor = [styleDescriptor styleDescriptorByDisablingUnderline];
    return [newStyleDescriptor attributes];
}

- (NSDictionary *)attributesBySettingFontSizeOfAttributes:(NSDictionary *)attributes
{
    KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithAttributes:attributes];
    KBTStyleDescriptor *newStyleDescriptor = [styleDescriptor styleDescriptorBySettingFontSize:fontPickerViewController_.selectedFontSize];
    return [newStyleDescriptor attributes];
}

- (NSDictionary *)attributesBySettingFontFamilyNameOfAttributes:(NSDictionary *)attributes
{
    KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithAttributes:attributes];
    KBTStyleDescriptor *newStyleDescriptor = [styleDescriptor styleDescriptorBySettingFontFamilyName:fontPickerViewController_.selectedFontFamilyName];
    return [newStyleDescriptor attributes];
}

@end
