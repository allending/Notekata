//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTPageViewController.h"
#import "KobaText.h"
#import "NKTPage.h"
#import "NKTNotebook.h"

@implementation NKTPageViewController

@synthesize page = page_;
@synthesize pageStyle = pageStyle_;
@synthesize delegate = delegate_;

@synthesize fontPopoverController = fontPopoverController_;
@synthesize fontPickerViewController = fontPickerViewController_;

@synthesize textView = textView_;
@synthesize creamPaperBackgroundView = creamPaperBackgroundView_;
@synthesize plainPaperBackgroundView = plainPaperBackgroundView_;
@synthesize rightEdgeView = rightEdgeView_;
@synthesize leftEdgeView = leftEdgeView_;
@synthesize edgeShadowView = leftEdgeShadowView_;
@synthesize frozenOverlayView = frozenOverlayView_;

@synthesize toolbar = toolbar_;
@synthesize notebookItem = notebookItem_;
@synthesize actionItem = actionItem_;
@synthesize fontItem = fontItem_;
@synthesize spacerItem = spacerItem_;
@synthesize boldItem = boldItem_;
@synthesize italicItem = italicItem_;
@synthesize underlineItem = underlineItem_;
@synthesize titleLabel = titleLabel_;
@synthesize boldToggleButton = boldToggleButton_;
@synthesize italicToggleButton = italicToggleButton_;
@synthesize underlineToggleButton = underlineToggleButton_;

static const CGFloat KeyboardOverlapTolerance = 1.0;

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
#pragma mark Memory

- (void)dealloc
{
    [page_ release];
    
    [notebookPopoverController_ release];
    [fontPopoverController_ release];
    [fontPickerViewController_ release];
    
    [textView_ release];
    [creamPaperBackgroundView_ release];
    [plainPaperBackgroundView_ release];
    [rightEdgeView_ release];
    [leftEdgeView_ release];
    [leftEdgeShadowView_ release];
    [frozenOverlayView_ release];
    
    [toolbar_ release];
    [notebookItem_ release];
    [actionItem_ release];
    [spacerItem_ release];
    [fontItem_ release];
    [boldItem_ release];
    [italicItem_ release];
    [underlineItem_ release];
    
    [titleLabel_ release];
    [boldToggleButton_ release];
    [italicToggleButton_ release];
    [underlineToggleButton_ release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark View Controller

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    toolbar_.barStyle = UIBarStyleBlack;
        
    // Configure background views
    creamPaperBackgroundView_ = [[UIView alloc] init];
    creamPaperBackgroundView_.opaque = YES;
    creamPaperBackgroundView_.userInteractionEnabled = NO;
    creamPaperBackgroundView_.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"CreamPaperPattern.png"]];
    plainPaperBackgroundView_ = [[UIView alloc] init];
    plainPaperBackgroundView_.opaque = YES;
    plainPaperBackgroundView_.userInteractionEnabled = NO;
    plainPaperBackgroundView_.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"PlainPaperPattern2.png"]];
    
    // Configure right edge view
    rightEdgeView_.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"RedCoverPattern.png"]];
    
    // Configure left edge view
    UIImage *leftEdgeImage = [[UIImage imageNamed:@"DarkBgCap.png"] stretchableImageWithLeftCapWidth:6.0 topCapHeight:3.0];
    leftEdgeView_ = [[UIImageView alloc] initWithImage:leftEdgeImage];
    leftEdgeView_.userInteractionEnabled = NO;
    leftEdgeView_.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleBottomMargin;
    
    // Configure left edge shadow view
    leftEdgeShadowView_ = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"EdgeShadow.png"]];
    leftEdgeShadowView_.userInteractionEnabled = NO;
    leftEdgeShadowView_.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleBottomMargin;
    leftEdgeShadowView_.frame = CGRectMake(5.0, 0.0, 10.0, 0.0);
    
    // Configure frozen overlay view
    frozenOverlayView_ = [[UIView alloc] initWithFrame:self.view.bounds];
    frozenOverlayView_.backgroundColor = [UIColor blackColor];
    frozenOverlayView_.userInteractionEnabled = NO;
    frozenOverlayView_.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    frozenOverlayView_.alpha = 0.0;
    [self.view addSubview:frozenOverlayView_];
    
    // Configure bold item
    boldToggleButton_ = [[KUIToggleButton alloc] initWithStyle:KUIToggleButtonStyleTextDark];
    [boldToggleButton_ addTarget:self action:@selector(boldItemTapped:) forControlEvents:UIControlEventValueChanged];
    [boldToggleButton_ setTitle:@"B" forState:UIControlStateNormal];
    boldToggleButton_.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0];
    boldToggleButton_.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
    boldItem_.customView = boldToggleButton_;

    // Configure italic item
    italicToggleButton_ = [[KUIToggleButton alloc] initWithStyle:KUIToggleButtonStyleTextDark];
    [italicToggleButton_ addTarget:self action:@selector(italicItemTapped:) forControlEvents:UIControlEventValueChanged];
    [italicToggleButton_ setTitle:@"I" forState:UIControlStateNormal];
    italicToggleButton_.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Italic" size:14.0];
    italicToggleButton_.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
    italicItem_.customView = italicToggleButton_;
    
    // Configure underline item
    underlineToggleButton_ = [[KUIToggleButton alloc] initWithStyle:KUIToggleButtonStyleTextDark];
    [underlineToggleButton_ addTarget:self action:@selector(underlineItemTapped:) forControlEvents:UIControlEventValueChanged];
    [underlineToggleButton_ setTitle:@"U" forState:UIControlStateNormal];
    underlineToggleButton_.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:14.0];
    underlineToggleButton_.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
    underlineItem_.customView = underlineToggleButton_;
    
    // Create the font picker view
    fontPickerViewController_ = [[NKTFontPickerViewController alloc] init];
    fontPickerViewController_.delegate = self;
    fontPickerViewController_.selectedFontFamilyName = @"Helvetica Neue";
    fontPickerViewController_.selectedFontSize = 16;
    fontPopoverController_ = [[UIPopoverController alloc] initWithContentViewController:fontPickerViewController_];
    fontPopoverController_.popoverContentSize = CGSizeMake(320.0, 400.0);
    
    // Set up the text view
    textView_.delegate = self;
    [self applyPageStyle];
    
    if (page_ != nil)
    {
        [self configureForNonNilPageAnimated:NO];
    }
    else
    {
        [self configureForNilPageAnimated:NO];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.fontPickerViewController = nil;
    self.fontPopoverController = nil;
    
    self.textView = nil;
    self.creamPaperBackgroundView = nil;
    self.plainPaperBackgroundView = nil;
    self.rightEdgeView = nil;
    self.leftEdgeView = nil;
    self.edgeShadowView = nil;
    self.frozenOverlayView = nil;
    
    self.toolbar = nil;
    self.notebookItem = nil;
    self.actionItem = nil;
    self.spacerItem = nil;
    self.fontItem = nil;
    self.boldItem = nil;
    self.italicItem = nil;
    self.underlineItem = nil;
    self.titleLabel = nil;
    self.boldToggleButton = nil;
    self.italicToggleButton = nil;
    self.underlineToggleButton = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updatePageViews];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self savePendingChanges];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

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
        leftEdgeView_.frame = frame;
        [self.view addSubview:leftEdgeView_];
        
        frame.origin.x = 5.0;
        frame.size.width = 10.0;
        leftEdgeShadowView_.frame = frame;
        [self.view addSubview:leftEdgeShadowView_];
    }
    else
    {
        // Shift text view back
        CGRect frame = textView_.frame;
        frame.origin.x = 0.0;
        frame.size.width = self.view.bounds.size.width - 15.0;
        textView_.frame = frame;
        
        // Remove adornment views
        [leftEdgeView_ removeFromSuperview];
        [leftEdgeShadowView_ removeFromSuperview];
    }
}

#pragma mark -
#pragma mark Page

- (void)setPage:(NKTPage *)page
{
    if (page_ == page)
    {
        return;
    }
    
    if ([fontPopoverController_ isPopoverVisible])
    {
        [fontPopoverController_ dismissPopoverAnimated:YES];
    }
    
    // PENDING: figure this out .. save or not?
    // PENDING: store a flag so this does not call delegate
    // NOTE: this causes a save to occur on the previous page!
    //[self resignFirstResponder];
    //[self savePendingChanges];
    
    [page_ release];
    page_ = [page retain];
    
    // When the page is set to nil, the page view controller goes into a special state
    if (page_ != nil)
    {
        [self configureForNonNilPageAnimated:NO];
        [self updatePageViews];
    }
    else
    {
        [self configureForNilPageAnimated:NO];
    }
}

// PENDING: this should be unnecessary
- (void)savePendingChanges
{
    if (page_ == nil)
    {
        return;
    }
    
    // PENDING: store a dirty flag to avoid needless saving
    // Set the text of the page from the text view's text and save the page
    NSAttributedString *text = textView_.text;
    KBTAttributedStringIntermediate *intermediate = [[KBTAttributedStringIntermediate alloc] initWithAttributedString:text];
    page_.textString = [intermediate string];
    page_.textStyleString = [intermediate styleString];
    [intermediate release];
    
    NSError *error = nil;
    if (![page_.managedObjectContext save:&error])
    {
        // PENDING: fix and log
        KBCLogWarning(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

#pragma mark -
#pragma mark Styles

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
            self.textView.verticalMarginColor = [UIColor colorWithRed:0.8 green:0.5 blue:0.49 alpha:0.5];
            self.textView.verticalMarginInset = 60.0;
            break;
            
        default:
            KBCLogWarning(@"unknown page style, ignoring");
            break;
    }
}

#pragma mark -
#pragma mark Freezing

- (void)freeze
{
    if (frozen_)
    {
        return;
    }
    
    frozen_ = YES;
    [UIView beginAnimations:@"FreezeView" context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    frozenOverlayView_.alpha = 0.37;
    [UIView commitAnimations];
    self.view.userInteractionEnabled = NO;
    self.toolbar.userInteractionEnabled = NO;
}

- (void)unfreeze
{
    if (!frozen_)
    {
        return;
    }
    
    frozen_ = NO;
    [UIView beginAnimations:@"UnfreezeView" context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    frozenOverlayView_.alpha = 0.0;
    [UIView commitAnimations];
    self.view.userInteractionEnabled = YES;
    self.toolbar.userInteractionEnabled = YES;
}

#pragma mark -
#pragma mark Navigation

- (void)dismissNotebookPopoverAnimated
{
    if (notebookPopoverController_.popoverVisible)
    {
        [notebookPopoverController_ dismissPopoverAnimated:YES];
    }
}

- (void)dismissNotebookPopoverAnimated:(BOOL)animated
{
    if (notebookPopoverController_.popoverVisible)
    {
        [notebookPopoverController_ dismissPopoverAnimated:animated];
    }
}

#pragma mark -
#pragma mark Split View Controller

- (void)splitViewController:(UISplitViewController*)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController:(UIPopoverController*)pc
{
    notebookPopoverController_ = pc;
    [notebookPopoverController_ setDelegate:self];
    [self updateToolbarAnimated:NO];
}

- (void)splitViewController:(UISplitViewController*)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)button
{
    notebookPopoverController_ = nil;
    [self updateToolbarAnimated:NO];
}

#pragma mark -
#pragma mark Notebook Popover Controller

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    if (popoverController == notebookPopoverController_)
    {
        // PENDING: this is kinda leaky ... maybe ask delegate?
        // If the controller is frozen, then we must not dismiss the popover, or there might be no
        // way to unfreeze the controller
        return !frozen_;
    }
    
    return YES;
}

#pragma mark -
#pragma mark Font Picker View Controller

- (void)fontPickerViewController:(NKTFontPickerViewController *)fontPickerViewController didSelectFontFamilyName:(NSString *)fontFamilyName
{
    [textView_ styleTextRange:textView_.selectedTextRange withTarget:self selector:@selector(attributesBySettingFontFamilyNameOfAttributes:)];
    textView_.inputTextAttributes = [self currentCoreTextAttributes];
    [self updateTextEditingItems];
}

- (void)fontPickerViewController:(NKTFontPickerViewController *)fontPickerViewController didSelectFontSize:(CGFloat)fontSize
{
    [textView_ styleTextRange:textView_.selectedTextRange withTarget:self selector:@selector(attributesBySettingFontSizeOfAttributes:)];
    textView_.inputTextAttributes = [self currentCoreTextAttributes];
    [self updateTextEditingItems];
}

#pragma mark -
#pragma mark Actions

- (void)notebookItemTapped:(id)sender
{
    if (notebookPopoverController_.popoverVisible && !frozen_)
    {
        [notebookPopoverController_ dismissPopoverAnimated:YES];
    }
    else
    {
        [self.textView resignFirstResponder];
        [notebookPopoverController_ presentPopoverFromBarButtonItem:notebookItem_ permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (void)actionItemTapped:(id)sender
{
    self.pageStyle = (self.pageStyle + 1) % 6;
}

- (void)fontItemTapped:(id)sender
{
    if (fontPopoverController_.popoverVisible)
    {
        [fontPopoverController_ dismissPopoverAnimated:YES];
    }
    else
    {
        [fontPopoverController_ presentPopoverFromBarButtonItem:fontItem_ permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (void)boldItemTapped:(id)sender
{
    NSString *familyName = fontPickerViewController_.selectedFontFamilyName;
    KBTFontFamilyDescriptor *fontFamilyDescriptor = [KBTFontFamilyDescriptor fontFamilyDescriptorWithFamilyName:familyName];
    
    // Deselect the italic button if the font family supports bold or italic traits exclusively
    if (fontFamilyDescriptor.supportsItalicTrait && !fontFamilyDescriptor.supportsBoldItalicTrait)
    {
        italicToggleButton_.selected = NO;
    }
    
    if (boldToggleButton_.selected)
    {
        [textView_ styleTextRange:textView_.selectedTextRange withTarget:self selector:@selector(attributesByAddingBoldTraitToAttributes:)];
    }
    else
    {
        [textView_ styleTextRange:textView_.selectedTextRange withTarget:self selector:@selector(attributesByRemovingBoldTraitFromAttributes:)];
    }
    
    textView_.inputTextAttributes = [self currentCoreTextAttributes];
}

- (void)italicItemTapped:(id)sender
{
    NSString *familyName = fontPickerViewController_.selectedFontFamilyName;
    KBTFontFamilyDescriptor *fontFamilyDescriptor = [KBTFontFamilyDescriptor fontFamilyDescriptorWithFamilyName:familyName];
    
    // Deselect the bold button if the font family supports bold or italic traits exclusively
    if (fontFamilyDescriptor.supportsBoldTrait && !fontFamilyDescriptor.supportsBoldItalicTrait)
    {
        boldToggleButton_.selected = NO;
    }
    
    if (italicToggleButton_.selected)
    {
        [textView_ styleTextRange:textView_.selectedTextRange withTarget:self selector:@selector(attributesByAddingItalicTraitToAttributes:)];
    }
    else
    {
        [textView_ styleTextRange:textView_.selectedTextRange withTarget:self selector:@selector(attributesByRemovingItalicTraitFromAttributes:)];
    }
    
    textView_.inputTextAttributes = [self currentCoreTextAttributes];
}

- (void)underlineItemTapped:(id)sender
{
    if (underlineToggleButton_.selected)
    {
        [textView_ styleTextRange:textView_.selectedTextRange withTarget:self selector:@selector(attributesByAddingUnderlineToAttributes:)];
    }
    else
    {
        [textView_ styleTextRange:textView_.selectedTextRange withTarget:self selector:@selector(attributesByRemovingUnderlineFromAttributes:)];
    }
    
    textView_.inputTextAttributes = [self currentCoreTextAttributes];
}

#pragma mark -
#pragma mark Updating Views

- (void)configureForNonNilPageAnimated:(BOOL)animated
{
    textView_.hidden = NO;
    textView_.userInteractionEnabled = YES;
    rightEdgeView_.hidden = NO;
    leftEdgeView_.hidden = NO;
    leftEdgeShadowView_.hidden = NO;
    titleLabel_.text = @"";
    CGRect bounds = titleLabel_.bounds;
    bounds.size.width = 120.0;
    titleLabel_.bounds = bounds;
    [self updateToolbarAnimated:animated];
}

- (void)configureForNilPageAnimated:(BOOL)animated
{
    textView_.text = nil;
    textView_.hidden = YES;
    textView_.userInteractionEnabled = NO;
    rightEdgeView_.hidden = YES;
    leftEdgeView_.hidden = YES;
    leftEdgeShadowView_.hidden = YES;
    titleLabel_.text = @"No Notebook Selected";
    notebookItem_.title = @"Notebooks";
    CGRect bounds = titleLabel_.bounds;
    bounds.size.width = 300.0;
    titleLabel_.bounds = bounds;
    [self updateToolbarAnimated:animated];
}

- (void)updateToolbarAnimated:(BOOL)animated
{
    if (page_ != nil)
    {
        if (notebookPopoverController_ != nil)
        {
            NSArray *items = [NSArray arrayWithObjects:notebookItem_, actionItem_, spacerItem_, fontItem_, boldItem_, italicItem_, underlineItem_, nil];
            [toolbar_ setItems:items animated:animated];
        }
        else
        {
            NSArray *items = [NSArray arrayWithObjects:actionItem_, spacerItem_, fontItem_, boldItem_, italicItem_, underlineItem_, nil];
            [toolbar_ setItems:items animated:animated];
        }
    }
    else
    {
        if (notebookPopoverController_ != nil)
        {
            NSArray *items = [NSArray arrayWithObject:notebookItem_];
            [toolbar_ setItems:items animated:animated];
        }
        else
        {
            [toolbar_ setItems:nil animated:animated];
        }
    }
}

- (void)updatePageViews
{
    if (page_ == nil)
    {
        return;
    }
    
    // Text view needs to be updated first because title label update depends on it
    [self updateTextView];
    [self updateTitleLabel];
    [self updateNotebookItem];
    [self updateTextEditingItems];
}

- (void)updateTextView
{
    KBTAttributedStringIntermediate *intermediate = [KBTAttributedStringIntermediate attributedStringIntermediateWithString:page_.textString styleString:page_.textStyleString];
    textView_.text = [intermediate attributedString];
}

- (void)updateTitleLabel
{
    NSString *snippet = KUITrimmedSnippetFromString([textView_.text string], 50);
    
    if ([snippet length] == 0)
    {
        // PENDING: localization
        titleLabel_.text = @"Untitled";
    }
    else
    {
        titleLabel_.text = snippet;
    }
}

- (void)updateNotebookItem
{
    notebookItem_.title = page_.notebook.title;
}

- (void)updateTextEditingItems
{
    // PENDING: improve poor clarity of behavior    
    if ([textView_ isFirstResponder])
    {
        UITextRange *selectedTextRange = textView_.selectedTextRange;
        NSDictionary *inputTextAttributes = self.textView.inputTextAttributes;
        KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithCoreTextAttributes:inputTextAttributes];
        fontItem_.enabled = YES;
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
        fontItem_.enabled = NO;
        boldToggleButton_.enabled = NO;
        boldToggleButton_.selected = NO;
        italicToggleButton_.enabled = NO;
        italicToggleButton_.selected = NO;
        underlineToggleButton_.enabled = NO;
        underlineToggleButton_.selected = NO;
    }
    
    // Update the font item title regardless of editing state
    NSString *fontName = fontPickerViewController_.selectedFontFamilyName;
    
    if ([fontName length] > 14)
    {
        fontName = [fontName substringToIndex:10];
        fontName = [fontName stringByAppendingString:@"..."];
    }
    
    NSString *fontButtonTitle = [NSString stringWithFormat:@"%@ %d", fontName, fontPickerViewController_.selectedFontSize];
    fontItem_.title = fontButtonTitle;
}

#pragma mark -
#pragma mark Text View

- (NSDictionary *)defaultCoreTextAttributes
{
    KBTStyleDescriptor *styleDecriptor = [KBTStyleDescriptor styleDescriptorWithFontFamilyName:@"Helvetica Neue" fontSize:16.0 bold:NO italic:NO underlined:NO];
    return [styleDecriptor coreTextAttributes];
}

- (UIColor *)loupeFillColor
{
    // The loupe 
    return textView_.backgroundView.backgroundColor;
}

- (void)textViewDidBeginEditing:(NKTTextView *)textView
{
    [self registerForKeyboardEvents];
    [self updateTextEditingItems];
}

- (void)textViewDidEndEditing:(NKTTextView *)textView
{
    if (fontPopoverController_.popoverVisible)
    {
        [fontPopoverController_ dismissPopoverAnimated:YES];
    }
    
    [self updateTextEditingItems];
    [self savePendingChanges];
    [self unregisterForKeyboardEvents];
}

- (void)textViewDidChangeSelection:(NKTTextView *)textView
{
    [self updateTextEditingItems];
}

- (void)textViewDidChange:(NKTTextView *)textView
{
    if (notebookPopoverController_.popoverVisible)
    {
        [notebookPopoverController_ dismissPopoverAnimated:YES];
    }
    
    if (fontPopoverController_.popoverVisible)
    {
        [fontPopoverController_ dismissPopoverAnimated:YES];
    }
    
    if ([delegate_ respondsToSelector:@selector(pageViewController:textViewDidChange:)])
    {
        [delegate_ pageViewController:self textViewDidChange:textView_];
    }
    
    [self updateTitleLabel];
}

#pragma mark -
#pragma mark Text Editing

- (NSDictionary *)currentCoreTextAttributes
{
    NSString *familyName = fontPickerViewController_.selectedFontFamilyName;
    CGFloat fontSize = fontPickerViewController_.selectedFontSize;
    BOOL bold = boldToggleButton_.selected;
    BOOL italic = italicToggleButton_.selected;
    BOOL underlined = underlineToggleButton_.selected;
    KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithFontFamilyName:familyName fontSize:fontSize bold:bold italic:italic underlined:underlined];
    return [styleDescriptor coreTextAttributes];
}

// These methods are meant to be used as callbacks by the NKTTextView in its -styleTextRange:withTarget:selector: method.

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
#pragma mark Keyboard

- (void)registerForKeyboardEvents
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)unregisterForKeyboardEvents
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

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
