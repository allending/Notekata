//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTPageViewController.h"
#import "KobaText.h"
#import "NKTPage.h"
#import "NKTNotebook.h"

// NKTNotebookViewController private interface
@interface NKTPageViewController()

#pragma mark Accessing View Controllers

@property (nonatomic, assign) UIPopoverController *navigationPopoverController;
@property (nonatomic, retain) UIPopoverController *fontPopoverController;
@property (nonatomic, retain) NKTFontPickerViewController *fontPickerViewController;

#pragma mark Managing Views

@property (nonatomic, retain) UIView *creamPaperBackgroundView;
@property (nonatomic, retain) UIView *plainPaperBackgroundView;
@property (nonatomic, retain) UIImageView *capAndEdgeView;
@property (nonatomic, retain) UIImageView *edgeShadowView;
@property (nonatomic, retain) UIView *frozenOverlay;
#pragma mark Updating Model Views

- (void)updateModelViews;

#pragma mark Configuring the Page Style

- (void)styleTextView;

#pragma mark Managing the Title

- (void)updateTitleLabel;
- (void)updateNavigationButtonTitle;

#pragma mark Managing the Toolbar

@property (nonatomic, retain) UIButton *navigationButton;
@property (nonatomic, retain) UIBarButtonItem *navigationButtonItem;
@property (nonatomic, retain) KUIToggleButton *boldToggleButton;
@property (nonatomic, retain) KUIToggleButton *italicToggleButton;
@property (nonatomic, retain) KUIToggleButton *underlineToggleButton;
@property (nonatomic, retain) UIButton *fontButton;
@property (nonatomic, retain) UIBarButtonItem *fontToolbarItem;

- (UIButton *)borderedToolbarButton;
- (void)populateToolbar;
- (void)updateToolbarStyleItems;

#pragma mark Managing Text Attributes

- (NSDictionary *)currentCoreTextAttributes;
- (NSDictionary *)attributesByAddingBoldTraitToAttributes:(NSDictionary *)attributes;
- (NSDictionary *)attributesByRemovingBoldTraitFromAttributes:(NSDictionary *)attributes;
- (NSDictionary *)attributesByAddingItalicTraitToAttributes:(NSDictionary *)attributes;
- (NSDictionary *)attributesByRemovingItalicTraitFromAttributes:(NSDictionary *)attributes;
- (NSDictionary *)attributesByAddingUnderlineToAttributes:(NSDictionary *)attributes;
- (NSDictionary *)attributesByRemovingUnderlineFromAttributes:(NSDictionary *)attributes;
- (NSDictionary *)attributesBySettingFontSizeOfAttributes:(NSDictionary *)attributes;
- (NSDictionary *)attributesBySettingFontFamilyNameOfAttributes:(NSDictionary *)attributes;

#pragma mark Responding to Toolbar Actions

- (void)boldToggleChanged:(KUIToggleButton *)toggleButton;
- (void)italicToggleChanged:(KUIToggleButton *)toggleButton;
- (void)underlineToggleChanged:(KUIToggleButton *)toggleButton;
- (void)fontButtonPressed:(UIButton *)button;

#pragma mark Registering for Keyboard Events

- (void)registerForKeyboardEvents;
- (void)unregisterForKeyboardEvents;

#pragma mark Responding to Keyboard Events

- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardDidShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;
- (CGRect)keyboardFrameFromNotification:(NSNotification *)notification;
- (void)growTextViewToAccomodateKeyboardFrameFromNotification:(NSNotification *)notification;
- (void)shrinkTextViewToAccomodateKeyboardFrameFromNotification:(NSNotification *)notification;

@end

#pragma mark -

@implementation NKTPageViewController

@synthesize page = page_;

@synthesize delegate = delegate_;

@synthesize navigationPopoverController = navigationPopoverController_;
@synthesize fontPopoverController = fontPopoverController_;
@synthesize fontPickerViewController = fontPickerViewController_;

@synthesize textView = textView_;
@synthesize creamPaperBackgroundView = creamPaperBackgroundView_;
@synthesize plainPaperBackgroundView = plainPaperBackgroundView_;
@synthesize coverEdgeView = coverEdgeView_;
@synthesize capAndEdgeView = capAndEdgeView_;
@synthesize edgeShadowView = edgeShadowView_;
@synthesize pageStyle = pageStyle_;
@synthesize toolbar = toolbar_;
@synthesize titleLabel = titleLabel_;
@synthesize navigationButton = navigationButton_;
@synthesize navigationButtonItem = navigationButtonItem_;
@synthesize boldToggleButton = boldToggleButton_;
@synthesize italicToggleButton = italicToggleButton_;
@synthesize underlineToggleButton = underlineToggleButton_;
@synthesize fontButton = fontButton_;
@synthesize fontToolbarItem = fontToolbarItem_;
@synthesize frozenOverlay = frozenOverlay_;

#pragma mark -
#pragma mark Initializing

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
    {
        pageStyle_ = NKTPageStyleCollegeRuledCream;
    }
    
    return self;
}

- (void)awakeFromNib
{
    pageStyle_ = NKTPageStyleCollegeRuledCream;
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc
{
    [page_ release];

    [fontPopoverController_ release];
    [fontPickerViewController_ release];

    [textView_ release];
    [creamPaperBackgroundView_ release];
    [plainPaperBackgroundView_ release];
    [coverEdgeView_ release];
    [capAndEdgeView_ release];
    [edgeShadowView_ release];
    [toolbar_ release];
    [titleLabel_ release];
    [navigationButton_ release];
    [navigationButtonItem_ release];
    [boldToggleButton_ release];
    [italicToggleButton_ release];
    [underlineToggleButton_ release];
    [fontButton_ release];
    [fontToolbarItem_ release];
    [frozenOverlay_ release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Accessing the Page

- (void)setPage:(NKTPage *)page
{
    [self setPage:page saveEditedText:YES];
}

- (void)setPage:(NKTPage *)page saveEditedText:(BOOL)saveEditedText
{
    if (page_ == page)
    {
        return;
    }
    
    if (saveEditedText)
    {
        [self saveEditedPageText];
    }
    
    if ([navigationPopoverController_ isPopoverVisible])
    {
        [navigationPopoverController_ dismissPopoverAnimated:YES];
    }
    
    if ([fontPopoverController_ isPopoverVisible])
    {
        [fontPopoverController_ dismissPopoverAnimated:YES];
    }
    
    [page_ release];
    page_ = [page retain];
    [self updateModelViews];
    [self updateToolbarStyleItems];
}

#pragma mark -
#pragma mark Saving the Page

- (void)saveEditedPageText
{
    if (page_ == nil)
    {
        return;
    }
    
    KBCLogDebug(@"***********************************************\nstart saving edited text");
    
    // Set the text of the page from the text view's text and save the page
    NSAttributedString *text = textView_.text;
    KBTAttributedStringIntermediate *intermediate = [[KBTAttributedStringIntermediate alloc] initWithAttributedString:text];
    KBCLogDebug(@"text string:\n%@", [intermediate string]);
    page_.textString = [intermediate string];
    page_.textStyleString = [intermediate styleString];
    [intermediate release];
    
    NSError *error = nil;
    
    if (![page_.managedObjectContext save:&error])
    {
        // TODO: FIX and LOG
        KBCLogWarning(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    KBCLogDebug(@"***********************************************\nend saving edited text");
}

#pragma mark -
#pragma mark Responding to Split View Controller Events

- (void)splitViewController:(UISplitViewController*)svc
     willHideViewController:(UIViewController *)aViewController
          withBarButtonItem:(UIBarButtonItem*)barButtonItem
       forPopoverController:(UIPopoverController*)pc
{
    NSMutableArray *items = [NSMutableArray arrayWithArray:self.toolbar.items];
    
    if (![items containsObject:navigationButtonItem_])
    {
        [items insertObject:navigationButtonItem_ atIndex:0];
        [self.toolbar setItems:items animated:NO];
    }
    
    navigationPopoverController_ = pc;
    [navigationPopoverController_ setDelegate:self];
}

- (void)splitViewController:(UISplitViewController*)svc
     willShowViewController:(UIViewController *)aViewController
  invalidatingBarButtonItem:(UIBarButtonItem *)button
{
    NSMutableArray *items = [NSMutableArray arrayWithArray:self.toolbar.items];
    
    if ([items containsObject:navigationButtonItem_])
    {
        [items removeObject:navigationButtonItem_];
        [self.toolbar setItems:items animated:NO];
    }
    
    navigationPopoverController_ = nil;
}

#pragma mark Responding to Popover Controller Events

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    if (popoverController == navigationPopoverController_)
    {
        return self.view.userInteractionEnabled;
    }
    
    return YES;
}

#pragma mark -
#pragma mark Responding to Font Picker View Controller Events

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
    
    textView_.inputTextAttributes = [self currentCoreTextAttributes];
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
    
    textView_.inputTextAttributes = [self currentCoreTextAttributes];
}

#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
    
    // TODO: is this right?
    self.textView.opaque = YES;
    self.textView.clearsContextBeforeDrawing = NO;
    
    // Set the background pattern for the edge view
    UIImage *edgePattern = [UIImage imageNamed:@"RedCoverPattern.png"];
    self.coverEdgeView.backgroundColor = [UIColor colorWithPatternImage:edgePattern];
    
    // Create background views
    UIImage *creamPaperPattern = [UIImage imageNamed:@"CreamPaperPattern.png"];
    creamPaperBackgroundView_ = [[UIView alloc] init];
    creamPaperBackgroundView_.opaque = YES;
    creamPaperBackgroundView_.userInteractionEnabled = NO;
    creamPaperBackgroundView_.backgroundColor = [UIColor colorWithPatternImage:creamPaperPattern];
    
    UIImage *plainPaperPattern = [UIImage imageNamed:@"PlainPaperPattern2.png"];
    plainPaperBackgroundView_ = [[UIView alloc] init];
    plainPaperBackgroundView_.opaque = YES;
    plainPaperBackgroundView_.userInteractionEnabled = NO;
    plainPaperBackgroundView_.backgroundColor = [UIColor colorWithPatternImage:plainPaperPattern];
    
    // Create a cap and edge image view to apply to the left edge of the text view
    UIImage *capAndEdgeImage = [UIImage imageNamed:@"DarkBgCap.png"];
    capAndEdgeImage = [capAndEdgeImage stretchableImageWithLeftCapWidth:6.0 topCapHeight:3.0];
    capAndEdgeView_ = [[UIImageView alloc] initWithImage:capAndEdgeImage];
    capAndEdgeView_.userInteractionEnabled = NO;
    capAndEdgeView_.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleBottomMargin;
    
    // Finally, apply a shadow to the left edge of the text view
    UIImage *edgeShadowImage = [UIImage imageNamed:@"EdgeShadow.png"];
    edgeShadowView_ = [[UIImageView alloc] initWithImage:edgeShadowImage];
    edgeShadowView_.userInteractionEnabled = NO;
    edgeShadowView_.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleBottomMargin;
    edgeShadowView_.frame = CGRectMake(5.0, 0.0, 10.0, 0.0);
    
    // Create the font picker view controllers
    fontPickerViewController_ = [[NKTFontPickerViewController alloc] init];
    fontPickerViewController_.delegate = self;
    fontPickerViewController_.selectedFontFamilyName = @"Helvetica Neue";
    fontPickerViewController_.selectedFontSize = 16;
    fontPopoverController_ = [[UIPopoverController alloc] initWithContentViewController:fontPickerViewController_];
    fontPopoverController_.popoverContentSize = CGSizeMake(320.0, 400.0);
    
    // Frozen overlay
    frozenOverlay_ = [[UIView alloc] initWithFrame:self.view.bounds];
    frozenOverlay_.backgroundColor = [UIColor grayColor];
    frozenOverlay_.userInteractionEnabled = NO;
    frozenOverlay_.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    frozenOverlay_.alpha = 0.0;
    [self.view addSubview:frozenOverlay_];
    
    // Set up the text view
    textView_.delegate = self;
    [self styleTextView];
    [self populateToolbar];
    [self updateToolbarStyleItems];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.textView = nil;
    self.creamPaperBackgroundView = nil;
    self.plainPaperBackgroundView = nil;
    self.coverEdgeView = nil;
    self.capAndEdgeView = nil;
    self.edgeShadowView = nil;
    self.toolbar = nil;
    self.titleLabel = nil;
    self.navigationButton = nil;
    self.navigationButtonItem = nil;
    self.boldToggleButton = nil;
    self.italicToggleButton = nil;
    self.underlineToggleButton = nil;
    self.fontButton = nil;
    self.fontToolbarItem = nil;
    self.fontPickerViewController = nil;
    self.fontPopoverController = nil;
    self.frozenOverlay = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self registerForKeyboardEvents];
    [self updateModelViews];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self saveEditedPageText];
    [self unregisterForKeyboardEvents];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

#pragma mark -
#pragma mark Handling Rotations

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation))
    {
        // Shift and resize text view
        CGRect frame = textView_.frame;
        frame.origin.x = 15.0;
        frame.size.width = self.view.bounds.size.width - 30.0;
        textView_.frame = frame;
        
        // Place and add adorment views
        frame.origin.x = 15.0;
        frame.size.width = 6.0;
        capAndEdgeView_.frame = frame;
        [self.view addSubview:capAndEdgeView_];
        
        frame.origin.x = 5.0;
        frame.size.width = 10.0;
        edgeShadowView_.frame = frame;
        [self.view addSubview:edgeShadowView_];
    }
    else
    {
        // Shift text view back
        CGRect frame = textView_.frame;
        frame.origin.x = 0.0;
        frame.size.width = self.view.bounds.size.width - 15.0;
        textView_.frame = frame;
        
        // Remove adornment views
        [capAndEdgeView_ removeFromSuperview];
        [edgeShadowView_ removeFromSuperview];
    }
}

#pragma mark -
#pragma mark Managing Loupes

- (UIColor *)loupeFillColor
{
    return textView_.backgroundView.backgroundColor;
}

#pragma mark -
#pragma mark Updating Model Views

- (void)updateModelViews
{
    KBTAttributedStringIntermediate *intermediate = [KBTAttributedStringIntermediate attributedStringIntermediateWithString:page_.textString
                                                                                                                styleString:page_.textStyleString];
    // NOTE: needs to be in this order because the title label is read from the text view text
    textView_.text = [intermediate attributedString];
    [self updateTitleLabel];
    [self updateNavigationButtonTitle];
}

#pragma mark -
#pragma mark Configuring the Page Style

- (void)setPageStyle:(NKTPageStyle)pageStyle
{
    if (pageStyle_ == pageStyle)
    {
        return;
    }
    
    pageStyle_ = pageStyle;
    [self styleTextView];
}

- (void)styleTextView
{
    switch (pageStyle_)
    {
        case NKTPageStylePlain:
            self.textView.backgroundView = plainPaperBackgroundView_;
            self.textView.margins = UIEdgeInsetsMake(60.0, 60.0, 60.0, 60.0);
            self.textView.horizontalRulesEnabled = NO;
            self.textView.verticalMarginEnabled = NO;
            break;
            
        case NKTPageStylePlainRuled:
            self.textView.backgroundView = plainPaperBackgroundView_;
            self.textView.margins = UIEdgeInsetsMake(60.0, 60.0, 60.0, 60.0);
            self.textView.horizontalRulesEnabled = YES;
            self.textView.horizontalRuleColor = [UIColor colorWithRed:0.84 green:0.84 blue:0.88 alpha:1.0];
            self.textView.verticalMarginEnabled = NO;
            break;
            
        case NKTPageStyleCollegeRuled:
            self.textView.backgroundView = plainPaperBackgroundView_;
            self.textView.margins = UIEdgeInsetsMake(60.0, 80.0, 60.0, 60.0);
            self.textView.horizontalRulesEnabled = YES;
            self.textView.horizontalRuleColor = [UIColor colorWithRed:0.72 green:0.75 blue:0.9 alpha:0.5];
            self.textView.verticalMarginEnabled = YES;
            self.textView.verticalMarginColor = [UIColor colorWithRed:0.8 green:0.45 blue:0.49 alpha:0.5];
            self.textView.verticalMarginInset = 60.0;
            break;
            
        case NKTPageStyleCream:
            self.textView.backgroundView = creamPaperBackgroundView_;
            self.textView.margins = UIEdgeInsetsMake(60.0, 60.0, 60.0, 60.0);
            self.textView.horizontalRulesEnabled = NO;
            self.textView.verticalMarginEnabled = NO;
            break;
            
        case NKTPageStyleCreamRuled:
            self.textView.backgroundView = creamPaperBackgroundView_;
            self.textView.margins = UIEdgeInsetsMake(60.0, 60.0, 60.0, 60.0);
            self.textView.horizontalRulesEnabled = YES;
            self.textView.horizontalRuleColor = [UIColor colorWithRed:0.72 green:0.72 blue:0.59 alpha:1.0];
            self.textView.verticalMarginEnabled = NO;
            break;
            
        case NKTPageStyleCollegeRuledCream:
            self.textView.backgroundView = creamPaperBackgroundView_;
            self.textView.margins = UIEdgeInsetsMake(60.0, 80.0, 60.0, 60.0);
            self.textView.horizontalRulesEnabled = YES;
            self.textView.horizontalRuleColor = [UIColor colorWithRed:0.72 green:0.72 blue:0.59 alpha:0.5];
            self.textView.verticalMarginEnabled = YES;
            self.textView.verticalMarginColor = [UIColor colorWithRed:0.8 green:0.45 blue:0.49 alpha:0.5];
            self.textView.verticalMarginInset = 60.0;
            break;
            
        default:
            KBCLogWarning(@"unknown page style, ignoring");
            break;
    }
}

#pragma mark -
#pragma mark Freezing User Interaction

- (void)freezeUserInteraction
{
    [UIView beginAnimations:@"FreezeView" context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    frozenOverlay_.alpha = 0.35;
    [UIView commitAnimations];
    self.view.userInteractionEnabled = NO;
}

- (void)unfreezeUserInteraction
{
    [UIView beginAnimations:@"UnfreezeView" context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    frozenOverlay_.alpha = 0.0;
    [UIView commitAnimations];
    self.view.userInteractionEnabled = YES;
}

#pragma mark -
#pragma mark Managing the Title

- (void)updateTitleLabel
{
    titleLabel_.text = KUITrimmedSnippetFromString([textView_.text string], 50);
}

- (void)updateNavigationButtonTitle
{
    [navigationButton_ setTitle:page_.notebook.title forState:UIControlStateNormal];
}

#pragma mark -
#pragma mark Managing the Toolbar

- (UIButton *)borderedToolbarButton
{
    // Various bits and pieces of the button
    UIImage *buttonImage = [UIImage imageNamed:@"DarkButton.png"];
    UIImage *buttonBackground = [buttonImage stretchableImageWithLeftCapWidth:4.0 topCapHeight:5.0];
    UIColor *highlightedColor = [UIColor colorWithRed:0.12 green:0.57 blue:0.92 alpha:1.0];
    UIColor *selectedColor = [UIColor colorWithRed:0.1 green:0.5 blue:0.9 alpha:1.0];
    UIColor *titleColor = [UIColor lightTextColor];
    UIColor *disabledColor = [UIColor darkGrayColor];
    UIFont *buttonFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:12.0];
    UIEdgeInsets buttonInsets = UIEdgeInsetsMake(6.0, 8.0, 6.0, 8.0);
    
    // Create and return the button
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

- (void)populateToolbar
{
    NSMutableArray *toolbarItems = [NSMutableArray array];
    
    // Navigation button
    navigationButton_ = [[self borderedToolbarButton] retain];
    [navigationButton_ addTarget:self
                          action:@selector(navigationButtonPressed:)
                forControlEvents:UIControlEventTouchUpInside];
    navigationButton_.frame = CGRectMake(0.0, 0.0, 120.0, 30.0);
    navigationButtonItem_ = [[UIBarButtonItem alloc] initWithCustomView:navigationButton_];
    
    // Page style item
    UIButton *pageStyleButton = [self borderedToolbarButton];
    [pageStyleButton setTitle:@"Page Style" forState:UIControlStateNormal];
    [pageStyleButton addTarget:self
                        action:@selector(pageStylePressed:)
              forControlEvents:UIControlEventTouchUpInside];
    pageStyleButton.frame = CGRectMake(0.0, 0.0, 120.0, 30.0);
    UIBarButtonItem *pageStyleItem = [[UIBarButtonItem alloc] initWithCustomView:pageStyleButton];
    [toolbarItems addObject:pageStyleItem];
    [pageStyleItem release];
    
    // Left flexible space
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                            target:nil
                                                                            action:nil];
    [toolbarItems addObject:spacer];
    [spacer release];
    
    // Font item
    fontButton_ = [[self borderedToolbarButton] retain];
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
    
    self.toolbar.items = toolbarItems;
}

- (void)updateToolbarStyleItems
{
    if ([textView_ isFirstResponder])
    {
        UITextRange *selectedTextRange = textView_.selectedTextRange;
        NSDictionary *inputTextAttributes = self.textView.inputTextAttributes;
        KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithCoreTextAttributes:inputTextAttributes];
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

#pragma mark -
#pragma mark Managing Text Attributes

- (NSDictionary *)defaultCoreTextAttributes
{
    KBTStyleDescriptor *styleDecriptor = [KBTStyleDescriptor styleDescriptorWithFontFamilyName:@"Helvetica Neue"
                                                                                      fontSize:16.0
                                                                                          bold:NO
                                                                                        italic:NO
                                                                                    underlined:NO];
    return [styleDecriptor coreTextAttributes];
}

- (NSDictionary *)currentCoreTextAttributes
{
    KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithFontFamilyName:fontPickerViewController_.selectedFontFamilyName
                                                                                       fontSize:fontPickerViewController_.selectedFontSize
                                                                                           bold:boldToggleButton_.selected
                                                                                         italic:italicToggleButton_.selected
                                                                                     underlined:underlineToggleButton_.selected];
    return [styleDescriptor coreTextAttributes];
}

// TODO: move to class method of helper class?
//
// These methods below are meant to be used as callbacks by the NKTTextView in its
// -styleTextRange:withTarget:selector: method.

- (NSDictionary *)attributesByAddingBoldTraitToAttributes:(NSDictionary *)attributes
{
    KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithCoreTextAttributes:attributes];
    KBTStyleDescriptor *newStyleDescriptor = [styleDescriptor styleDescriptorByEnablingBoldTrait];
    return [newStyleDescriptor coreTextAttributes];
}

- (NSDictionary *)attributesByRemovingBoldTraitFromAttributes:(NSDictionary *)attributes
{
    KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithCoreTextAttributes:attributes];
    KBTStyleDescriptor *newStyleDescriptor = [styleDescriptor styleDescriptorByDisablingBoldTrait];
    return [newStyleDescriptor coreTextAttributes];
}

- (NSDictionary *)attributesByAddingItalicTraitToAttributes:(NSDictionary *)attributes
{
    KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithCoreTextAttributes:attributes];
    KBTStyleDescriptor *newStyleDescriptor = [styleDescriptor styleDescriptorByEnablingItalicTrait];
    return [newStyleDescriptor coreTextAttributes];
}

- (NSDictionary *)attributesByRemovingItalicTraitFromAttributes:(NSDictionary *)attributes
{
    KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithCoreTextAttributes:attributes];
    KBTStyleDescriptor *newStyleDescriptor = [styleDescriptor styleDescriptorByDisablingItalicTrait];
    return [newStyleDescriptor coreTextAttributes];
}

- (NSDictionary *)attributesByAddingUnderlineToAttributes:(NSDictionary *)attributes
{
    KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithCoreTextAttributes:attributes];
    KBTStyleDescriptor *newStyleDescriptor = [styleDescriptor styleDescriptorByEnablingUnderline];
    return [newStyleDescriptor coreTextAttributes];
}

- (NSDictionary *)attributesByRemovingUnderlineFromAttributes:(NSDictionary *)attributes
{
    KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithCoreTextAttributes:attributes];
    KBTStyleDescriptor *newStyleDescriptor = [styleDescriptor styleDescriptorByDisablingUnderline];
    return [newStyleDescriptor coreTextAttributes];
}

- (NSDictionary *)attributesBySettingFontSizeOfAttributes:(NSDictionary *)attributes
{
    KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithCoreTextAttributes:attributes];
    KBTStyleDescriptor *newStyleDescriptor = [styleDescriptor styleDescriptorBySettingFontSize:fontPickerViewController_.selectedFontSize];
    return [newStyleDescriptor coreTextAttributes];
}

- (NSDictionary *)attributesBySettingFontFamilyNameOfAttributes:(NSDictionary *)attributes
{
    KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithCoreTextAttributes:attributes];
    KBTStyleDescriptor *newStyleDescriptor = [styleDescriptor styleDescriptorBySettingFontFamilyName:fontPickerViewController_.selectedFontFamilyName];
    return [newStyleDescriptor coreTextAttributes];
}

#pragma mark -
#pragma mark Responding to Toolbar Actions

- (void)navigationButtonPressed:(UIButton *)button
{
    if (navigationPopoverController_.popoverVisible)
    {
        [navigationPopoverController_ dismissPopoverAnimated:YES];
    }
    else
    {
        [self.textView resignFirstResponder];
        [navigationPopoverController_ presentPopoverFromBarButtonItem:navigationButtonItem_
                                             permittedArrowDirections:UIPopoverArrowDirectionAny
                                                             animated:YES];
    }
}

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
    
    textView_.inputTextAttributes = [self currentCoreTextAttributes];
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
    
    textView_.inputTextAttributes = [self currentCoreTextAttributes];
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
    
    textView_.inputTextAttributes = [self currentCoreTextAttributes];
}

#pragma mark -
#pragma mark Responding to Text View Events

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
    [self saveEditedPageText];
}

- (void)textViewDidChangeSelection:(NKTTextView *)textView
{
    [self updateToolbarStyleItems];
}

- (void)textViewDidChange:(NKTTextView *)textView
{
    if (fontPopoverController_.popoverVisible)
    {
        [fontPopoverController_ dismissPopoverAnimated:YES];
    }
    
    if (navigationPopoverController_.popoverVisible)
    {
        [navigationPopoverController_ dismissPopoverAnimated:YES];
    }
    
    if ([delegate_ respondsToSelector:@selector(pageViewController:textViewDidChange:)])
    {
        [delegate_ pageViewController:self textViewDidChange:textView_];
    }
    
    [self updateTitleLabel];
}

#pragma mark -
#pragma mark Registering for Keyboard Events

- (void)registerForKeyboardEvents
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)unregisterForKeyboardEvents
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark Responding to Keyboard Events

static const CGFloat KeyboardOverlapTolerance = 1.0;

- (void)keyboardWillShow:(NSNotification *)notification
{
    [self growTextViewToAccomodateKeyboardFrameFromNotification:notification];
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    [self shrinkTextViewToAccomodateKeyboardFrameFromNotification:notification];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    [self growTextViewToAccomodateKeyboardFrameFromNotification:notification];
}

- (CGRect)keyboardFrameFromNotification:(NSNotification *)notification
{
    NSValue* windowFrameValue = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect windowFrame = [windowFrameValue CGRectValue];
    return [self.view convertRect:windowFrame fromView:self.view.window];
}

// Does nothing if the keyboard frame overlaps the text view frame
- (void)growTextViewToAccomodateKeyboardFrameFromNotification:(NSNotification *)notification
{
    CGRect keyboardFrame = [self keyboardFrameFromNotification:notification];
    CGRect textViewFrame = textView_.frame;
    CGFloat heightOverlap = CGRectGetMaxY(textViewFrame) - CGRectGetMinY(keyboardFrame);
    
    // When the height overlap is negative, we grow the text view before the keyboard appears. Even though this grows
    // the text view frame, we should be safe from the shrinking logic in keyboardDidShow: because the overlap would
    // be 0 or close to it by then.
    if (heightOverlap < KeyboardOverlapTolerance)
    {
        CGPoint originalOffset = self.textView.contentOffset;
        
        // Resize scroll view frame
        textViewFrame.size.height -= heightOverlap;
        textView_.frame = textViewFrame;
        
        self.textView.contentOffset = originalOffset;
    }
}

// Does nothing if the keyboard frame does not overlap the text view frame
- (void)shrinkTextViewToAccomodateKeyboardFrameFromNotification:(NSNotification *)notification
{
    CGRect textViewFrame = textView_.frame;
    CGRect keyboardFrame = [self keyboardFrameFromNotification:notification];
    CGFloat heightOverlap = CGRectGetMaxY(textViewFrame) - CGRectGetMinY(keyboardFrame);
    
    // When the height overlap is positive, we shrink the text view after the keyboard appears.
    if (heightOverlap > KeyboardOverlapTolerance)
    {
        // Resize scroll view frame
        textViewFrame.size.height -= heightOverlap;
        textView_.frame = textViewFrame;
        [textView_ scrollTextRangeToVisible:textView_.selectedTextRange animated:YES];
    }
}

@end
