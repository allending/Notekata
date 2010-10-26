//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTPageViewController.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "KobaText.h"
#import "NKTNotebook+CustomAdditions.h"
#import "NKTPage+CustomAdditions.h"

typedef struct NKTAttributedStringRangeInfo
{
    BOOL anyFontSupportsBold;
    BOOL anyFontIsBold;
    BOOL anyFontSupportsItalic;
    BOOL anyFontIsItalic;
    BOOL allFontsSupportsBoldOrItalicExclusively;
} NKTAttributedStringRangeInfo;

static NKTAttributedStringRangeInfo NKTInfoForAttributedStringRange(NSAttributedString *attributedString, NSRange range)
{
    NSArray *rangeAttributes = nil;
    KBTLightweightEnumerateAttributedStringAttributesInRange(attributedString, &rangeAttributes, range);
    NKTAttributedStringRangeInfo info;
    info.anyFontSupportsBold = NO;
    info.anyFontIsBold = NO;
    info.anyFontSupportsItalic = NO;
    info.anyFontIsItalic = NO;
    info.allFontsSupportsBoldOrItalicExclusively = YES;
    
    for (NSDictionary *coreTextAttributes in rangeAttributes)
    {
        KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithCoreTextAttributes:coreTextAttributes];
        info.anyFontSupportsBold |= styleDescriptor.fontFamilySupportsBoldTrait;
        info.anyFontIsBold |= styleDescriptor.fontIsBold;
        info.anyFontSupportsItalic |= styleDescriptor.fontFamilySupportsItalicTrait;
        info.anyFontIsItalic |= styleDescriptor.fontIsItalic;
        
        if (info.allFontsSupportsBoldOrItalicExclusively)
        {
            if (!styleDescriptor.fontFamilySupportsBoldTrait || !styleDescriptor.fontFamilySupportsItalicTrait || styleDescriptor.fontFamilySupportsBoldItalicTrait)
            {
                info.allFontsSupportsBoldOrItalicExclusively = NO;
            }
        }
        
        if (info.anyFontSupportsBold && info.anyFontIsBold && info.anyFontSupportsItalic && info.anyFontIsItalic && !info.allFontsSupportsBoldOrItalicExclusively)
        {
            break;
        }
    }
    
    return info;
}

@interface NKTPageViewController()

#pragma mark Undo

@property (nonatomic, readwrite, retain) NSUndoManager *undoManager;

@end

@implementation NKTPageViewController

@synthesize page = page_;
@synthesize undoManager = undoManager_;

@synthesize delegate = delegate_;
@synthesize fontPopoverController = fontPopoverController_;
@synthesize fontPickerViewController = fontPickerViewController_;

@synthesize textView = textView_;
@synthesize creamBackgroundView = creamBackgroundView_;
@synthesize plainBackgroundView = plainBackgroundView_;
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

const NSUInteger MaximumNumberOfUndoLevels = 200;
const NSUInteger SaveCheckpointChangeCountThreshold = 50;
const NSUInteger SaveCheckpointTotalTextLengthChangeThreshold = 50;
static const NSUInteger TitleSnippetSourceLength = 50;
static const CGFloat KeyboardOverlapTolerance = 1.0;
static NSString *CodedAttributedStringDataTypeIdentifier = @"com.allending.notekata.codedattributedstringdata";

#pragma mark -
#pragma mark Memory

- (void)dealloc
{
    [page_ release];
    [undoManager_ release];
    
    [notebookPopoverController_ release];
    [fontPopoverController_ release];
    [fontPickerViewController_ release];
    
    [textView_ release];
    [creamBackgroundView_ release];
    [plainBackgroundView_ release];
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
    [self purgeCachedResources];
    
    // Force the undo manager to clear a maximum of half of its undo history
    [self.undoManager setLevelsOfUndo:MaximumNumberOfUndoLevels / 2];
    // Restore undo history limit
    [self.undoManager setLevelsOfUndo:MaximumNumberOfUndoLevels];
}

- (void)purgeCachedResources
{
    [textView_ purgeCachedResources];
}

#pragma mark -
#pragma mark View Controller

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Toolbar
    toolbar_.barStyle = UIBarStyleBlack;
    
    // Background views
    creamBackgroundView_ = [[UIView alloc] init];
    creamBackgroundView_.opaque = YES;
    creamBackgroundView_.userInteractionEnabled = NO;
    creamBackgroundView_.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"CreamBackgroundPattern.png"]];
    plainBackgroundView_ = [[UIView alloc] init];
    plainBackgroundView_.opaque = YES;
    plainBackgroundView_.userInteractionEnabled = NO;
    plainBackgroundView_.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"PlainBackgroundPattern.png"]];
    
    // Right edge view
    rightEdgeView_.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"PageRightEdgeBackgroundPattern.png"]];
    
    // Left edge view
    UIImage *leftEdgeImage = [[UIImage imageNamed:@"PageLeftEdgeCap.png"] stretchableImageWithLeftCapWidth:6.0 topCapHeight:3.0];
    leftEdgeView_ = [[UIImageView alloc] initWithImage:leftEdgeImage];
    leftEdgeView_.userInteractionEnabled = NO;
    leftEdgeView_.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleBottomMargin;
    
    // Left edge shadow view
    leftEdgeShadowView_ = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"PageLeftEdgeShadow.png"]];
    leftEdgeShadowView_.userInteractionEnabled = NO;
    leftEdgeShadowView_.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleBottomMargin;
    leftEdgeShadowView_.frame = CGRectMake(5.0, 0.0, 10.0, 0.0);
    
    // Frozen overlay view
    frozenOverlayView_ = [[UIView alloc] initWithFrame:self.view.bounds];
    frozenOverlayView_.backgroundColor = [UIColor blackColor];
    frozenOverlayView_.userInteractionEnabled = NO;
    frozenOverlayView_.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    frozenOverlayView_.alpha = 0.0;
    [self.view addSubview:frozenOverlayView_];
    
    // Bold item
    boldToggleButton_ = [[KUIToggleButton alloc] initWithStyle:KUIToggleButtonStyleTextDark];
    [boldToggleButton_ addTarget:self action:@selector(boldItemTapped:) forControlEvents:UIControlEventValueChanged];
    [boldToggleButton_ setTitle:@"B" forState:UIControlStateNormal];
    boldToggleButton_.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0];
    boldToggleButton_.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
    boldItem_.customView = boldToggleButton_;

    // Italic item
    italicToggleButton_ = [[KUIToggleButton alloc] initWithStyle:KUIToggleButtonStyleTextDark];
    [italicToggleButton_ addTarget:self action:@selector(italicItemTapped:) forControlEvents:UIControlEventValueChanged];
    [italicToggleButton_ setTitle:@"I" forState:UIControlStateNormal];
    italicToggleButton_.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Italic" size:14.0];
    italicToggleButton_.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
    italicItem_.customView = italicToggleButton_;
    
    // Underline item
    underlineToggleButton_ = [[KUIToggleButton alloc] initWithStyle:KUIToggleButtonStyleTextDark];
    [underlineToggleButton_ addTarget:self action:@selector(underlineItemTapped:) forControlEvents:UIControlEventValueChanged];
    [underlineToggleButton_ setTitle:@"U" forState:UIControlStateNormal];
    underlineToggleButton_.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:14.0];
    underlineToggleButton_.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
    underlineItem_.customView = underlineToggleButton_;
    
    // Font picker view controller and popover
    fontPickerViewController_ = [[NKTFontPickerViewController alloc] init];
    fontPickerViewController_.delegate = self;
    fontPickerViewController_.selectedFontFamilyName = @"Helvetica Neue";
    fontPickerViewController_.selectedFontSize = 16;
    fontPopoverController_ = [[UIPopoverController alloc] initWithContentViewController:fontPickerViewController_];
    fontPopoverController_.popoverContentSize = CGSizeMake(320.0, 400.0);
    
    // Text view
    textView_.delegate = self;
    
    // Initial view configuration
    if (page_ != nil)
    {
        [self configureViewsForNonNilPageAnimated:NO];
    }
    else
    {
        [self configureViewsForNilPageAnimated:NO];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.fontPickerViewController = nil;
    self.fontPopoverController = nil;
    
    self.textView = nil;
    self.creamBackgroundView = nil;
    self.plainBackgroundView = nil;
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
    [self updatePageDependentViews];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self savePendingChanges];
    // PENDING: document why this is here
    menuEnabledForSelectedTextRange_ = NO;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    // The controller could have asked for first responder status when the text view recognized
    // gestures, so resign first responder status whenever the view dissapears
    [self resignFirstResponder];
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
        
        // Remove edge views
        [leftEdgeView_ removeFromSuperview];
        [leftEdgeShadowView_ removeFromSuperview];
    }
    
    [self updateMenuForTemporaryViewChangesOccuring];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self updateMenuForTemporaryViewChangesEnded];
}

#pragma mark -
#pragma mark Page

- (void)setPage:(NKTPage *)page
{
    // Make sure to save any pending changes
    [self savePendingChanges];
    
    if (page_ == page)
    {
        return;
    }
    
    // The controller might have asked for first responder status when the text view recognized
    // gestures, so resign first responder status whenever the page is set
    [self resignFirstResponder];
    
    // Dismiss font popover
    if ([fontPopoverController_ isPopoverVisible])
    {
        [fontPopoverController_ dismissPopoverAnimated:YES];
    }
    
    // Stop observing current page
    if (page_ != nil)
    {
        [page_.notebook removeObserver:self forKeyPath:@"title"];
        [page_.notebook removeObserver:self forKeyPath:@"notebookStyle"];
    }
    
    // Clear undo manager
    self.undoManager = nil;
    
    [page_ release];
    page_ = [page retain];
    
    // A different view setup is displayed if the page is nil
    if (page_ != nil)
    {
        // PENDING: make sure this is ok if notebook is deleted
        // Observe changes in notebook
        [page_.notebook addObserver:self forKeyPath:@"title" options:0 context:nil];
        [page_.notebook addObserver:self forKeyPath:@"notebookStyle" options:0 context:nil];
        
        [self configureViewsForNonNilPageAnimated:NO];
        [self applyNotebookStyle];
        [self updatePageDependentViews];
        
        // Reset save checkpoint variables
        changeCountSinceSave_ = 0;
        textLengthBeforeChange_ = [textView_.text length];
        totalTextLengthChangeSinceSave_ = 0;
        
        // Create undo manager
        NSUndoManager *undoManager = [[NSUndoManager alloc] init];
        // Assuming each undo command consumes a liberal 50KB of memory, we allow about 5MB of
        // undo history ... at least until we have more granular undo
        [undoManager setLevelsOfUndo:MaximumNumberOfUndoLevels];
        self.undoManager = undoManager;
        [undoManager release];
        allowUndoCheckpoint_ = YES;
        
        //KBCLogDebug(@"Page set with text of length %d.", [page_.textString length]);
    }
    else
    {
        [self configureViewsForNilPageAnimated:NO];
    }
}

- (void)enterSaveCheckpoint
{
    // We push changes in the text view periodically to the data model and persistent storage
    // depending on the number of changes that have occured
    ++changeCountSinceSave_;
    NSInteger textLength = (NSInteger)[textView_.text length];
    NSUInteger changeInLength = abs(textLength - (NSInteger)textLengthBeforeChange_);
    textLengthBeforeChange_ = textLength;
    totalTextLengthChangeSinceSave_ += changeInLength;
    
    if (changeCountSinceSave_ >= SaveCheckpointChangeCountThreshold || totalTextLengthChangeSinceSave_ >= SaveCheckpointTotalTextLengthChangeThreshold)
    {
        [self savePendingChanges];
    }
}

- (void)savePendingChanges
{
    if (page_ == nil)
    {
        //KBCLogDebug(@"Page is nil. Returning.");
        return;
    }
    
    if (changeCountSinceSave_ == 0)
    {
        //KBCLogDebug(@"No text changes since last save. Returning.");
        return;
    }
    
    NSAttributedString *text = textView_.text;
    // Must make a copy for core data or this will fail badly (the text property of the textview
    // returns the backing attributed string)!
    NSString *string = [[text string] copy];
    NSString *styleString = [KBTAttributedStringCodec styleStringForAttributedString:text];
    page_.textString = string;
    page_.textStyleString = styleString;
    page_.textModifiedDate = [NSDate date];
    
    NSError *error = nil;
    if (![page_.managedObjectContext save:&error])
    {
        KBCLogWarning(@"Failed to save to data store: %@", [error localizedDescription]);
        KBCLogWarning(@"%@", KBCDetailedCoreDataErrorStringFromError(error));
        abort();
    }
    
    // Update save checkpoint counters
    changeCountSinceSave_ = 0;
    totalTextLengthChangeSinceSave_ = 0;
    
    [string release];
}

#pragma mark -
#pragma mark Undo

- (void)registerUndoForCurrentState
{
    NSAttributedString *currentAttributedString = [[NSAttributedString alloc] initWithAttributedString:textView_.text];
    NKTTextRange *currentSelectedTextRange = (NKTTextRange *)textView_.selectedTextRange;
    
    if (currentSelectedTextRange == nil)
    {
        currentSelectedTextRange = (NKTTextRange *)[textView_ beginningOfDocument];
    }
    
    NSDictionary *currentUndoInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                     currentAttributedString, @"AttributedString",
                                     currentSelectedTextRange, @"SelectedTextRange",
                                     nil];
    [self.undoManager registerUndoWithTarget:self selector:@selector(applyUndoWithInfo:) object:currentUndoInfo];
    [currentAttributedString release];
}

- (void)applyUndoWithInfo:(NSDictionary *)undoInfo
{
    [self registerUndoForCurrentState];
    
    // Apply changes
    NSAttributedString *attributedString = [undoInfo objectForKey:@"AttributedString"];
    NKTTextRange *selectedTextRange = [undoInfo objectForKey:@"SelectedTextRange"];
    CGPoint contentOffset = textView_.contentOffset;
    textView_.text = attributedString;
    textView_.contentOffset = contentOffset;
    [textView_ setSelectedTextRange:selectedTextRange notifyInputDelegate:YES];
    [textView_ updateSelectionDisplay];
    [textView_ scrollTextRangeToVisible:selectedTextRange animated:YES];
    allowUndoCheckpoint_ = YES;
    // This is considered a change so we need to enter the save checkpoint!
    [self enterSaveCheckpoint];
}

#pragma mark -
#pragma mark Notebook

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == page_.notebook)
    {
        if ([keyPath isEqualToString:@"title"])
        {
            [self updateNotebookItem];
        }
        else if ([keyPath isEqualToString:@"notebookStyle"])
        {
            [self applyNotebookStyle];
        }
    }
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
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Email Page", nil];
    [actionSheet showFromBarButtonItem:actionItem_ animated:YES];
    [actionSheet release];
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
    if (boldToggleButton_.selected)
    {
        [textView_ styleTextRange:textView_.selectedTextRange withTarget:self selector:@selector(attributesByAddingBoldTraitToAttributes:)];
    }
    else
    {
        [textView_ styleTextRange:textView_.selectedTextRange withTarget:self selector:@selector(attributesByRemovingBoldTraitFromAttributes:)];
    }
    
    NSString *familyName = fontPickerViewController_.selectedFontFamilyName;
    NKTTextRange *selectedTextRange = (NKTTextRange *)textView_.selectedTextRange;
    
    if (selectedTextRange != nil && !selectedTextRange.empty)
    {
        NKTAttributedStringRangeInfo info = NKTInfoForAttributedStringRange(textView_.text, selectedTextRange.nsRange);
        
        // Deselect the italic button if the font family supports bold or italic traits exclusively
        if (!info.anyFontIsItalic || info.allFontsSupportsBoldOrItalicExclusively)
        {
            italicToggleButton_.selected = NO;
        }
    }
    else
    {
        KBTFontFamilyDescriptor *fontFamilyDescriptor = [KBTFontFamilyDescriptor fontFamilyDescriptorWithFamilyName:familyName];
        
        // Deselect the bold button if the font family supports bold or italic traits exclusively
        if (fontFamilyDescriptor.supportsItalicTrait && !fontFamilyDescriptor.supportsBoldItalicTrait)
        {
            italicToggleButton_.selected = NO;
        }
    }
    
    textView_.inputTextAttributes = [self currentCoreTextAttributes];
}

- (void)italicItemTapped:(id)sender
{        
    if (italicToggleButton_.selected)
    {
        [textView_ styleTextRange:textView_.selectedTextRange withTarget:self selector:@selector(attributesByAddingItalicTraitToAttributes:)];
    }
    else
    {
        [textView_ styleTextRange:textView_.selectedTextRange withTarget:self selector:@selector(attributesByRemovingItalicTraitFromAttributes:)];
    }
    
    NSString *familyName = fontPickerViewController_.selectedFontFamilyName;
    NKTTextRange *selectedTextRange = (NKTTextRange *)textView_.selectedTextRange;
    
    if (selectedTextRange != nil && !selectedTextRange.empty)
    {
        NKTAttributedStringRangeInfo info = NKTInfoForAttributedStringRange(textView_.text, selectedTextRange.nsRange);
        
        // Deselect the italic button if the font family supports bold or italic traits exclusively
        if (!info.anyFontIsBold || info.allFontsSupportsBoldOrItalicExclusively)
        {
            boldToggleButton_.selected = NO;
        }
    }
    else
    {
        KBTFontFamilyDescriptor *fontFamilyDescriptor = [KBTFontFamilyDescriptor fontFamilyDescriptorWithFamilyName:familyName];
        
        // Deselect the bold button if the font family supports bold or italic traits exclusively
        if (fontFamilyDescriptor.supportsBoldTrait && !fontFamilyDescriptor.supportsBoldItalicTrait)
        {
            boldToggleButton_.selected = NO;
        }
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

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.firstOtherButtonIndex)
    {
        MFMailComposeViewController *mailComposeViewController = [[MFMailComposeViewController alloc] init];
        mailComposeViewController.mailComposeDelegate = self;
        NSString *subjectSnippet = KUITrimmedSnippetFromString([textView_.text string], 100);
        NSString *subject = [NSString stringWithFormat:@"%@ - %@", page_.notebook.title, subjectSnippet];
        [mailComposeViewController setSubject:subject];
        [mailComposeViewController setMessageBody:[textView_.text string] isHTML:NO];
        [textView_ resignFirstResponder];
        [self presentModalViewController:mailComposeViewController animated:YES];
        [mailComposeViewController release];
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
#pragma mark Notebook Popover

- (void)dismissNotebookPopoverAnimated:(BOOL)animated
{
    if (notebookPopoverController_.popoverVisible)
    {
        [notebookPopoverController_ dismissPopoverAnimated:animated];
    }
}

#pragma mark -
#pragma mark Split View Controller Delegate

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
#pragma mark Notebook Popover Controller Delegate

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
#pragma mark Font Picker View Controller Delegate

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
#pragma mark Mail Compose View Controller Delegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Updating Views

- (void)configureViewsForNonNilPageAnimated:(BOOL)animated
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

- (void)configureViewsForNilPageAnimated:(BOOL)animated
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

- (void)applyNotebookStyle
{
    if (page_ == nil)
    {
        return;
    }
    
    NSUInteger notebookStyle = [page_.notebook.notebookStyle unsignedIntegerValue];
    
    switch (notebookStyle)
    {
        case NKTNotebookStylePlain:
            self.textView.backgroundView = plainBackgroundView_;
            self.textView.margins = UIEdgeInsetsMake(60.0, 60.0, 60.0, 60.0);
            self.textView.horizontalRulesEnabled = NO;
            self.textView.verticalMarginEnabled = NO;
            break;
            
        case NKTNotebookStyleCollege:
            self.textView.backgroundView = plainBackgroundView_;
            self.textView.margins = UIEdgeInsetsMake(60.0, 80.0, 60.0, 60.0);
            self.textView.horizontalRulesEnabled = YES;
            self.textView.horizontalRuleColor = [UIColor colorWithRed:0.72 green:0.75 blue:0.9 alpha:0.5];
            self.textView.verticalMarginEnabled = YES;
            self.textView.verticalMarginColor = [UIColor colorWithRed:0.8 green:0.45 blue:0.49 alpha:0.5];
            self.textView.verticalMarginInset = 60.0;
            break;
            
        case NKTNotebookStyleElegant:
            self.textView.backgroundView = creamBackgroundView_;
            self.textView.margins = UIEdgeInsetsMake(60.0, 80.0, 60.0, 60.0);
            self.textView.horizontalRulesEnabled = YES;
            self.textView.horizontalRuleColor = [UIColor colorWithRed:0.69 green:0.69 blue:0.63 alpha:0.5];
            self.textView.verticalMarginEnabled = YES;
            self.textView.verticalMarginColor = [UIColor colorWithRed:0.8 green:0.5 blue:0.49 alpha:0.5];
            self.textView.verticalMarginInset = 60.0;
            break;
            
        default:
            KBCLogWarning(@"unknown page style, ignoring");
            break;
    }
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

- (void)updatePageDependentViews
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
    NSAttributedString *attributedString = [KBTAttributedStringCodec attributedStringWithString:page_.textString styleString:page_.textStyleString];
    textView_.text = attributedString;
}

- (void)updateTitleLabel
{
    NSString *snippet = KUITrimmedSnippetFromString([textView_.text string], TitleSnippetSourceLength);
    
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
        NKTTextRange *selectedTextRange = (NKTTextRange *)textView_.selectedTextRange;
        NSDictionary *inputTextAttributes = self.textView.inputTextAttributes;
        KBTStyleDescriptor *inputStyleDescriptor = [KBTStyleDescriptor styleDescriptorWithCoreTextAttributes:inputTextAttributes];
        fontItem_.enabled = YES;
        fontPickerViewController_.selectedFontFamilyName = inputStyleDescriptor.fontFamilyName;
        fontPickerViewController_.selectedFontSize = inputStyleDescriptor.fontSize;
        
        // Update bold and italic items
        if (selectedTextRange == nil || selectedTextRange.empty)
        {
            boldToggleButton_.enabled = inputStyleDescriptor.fontFamilySupportsBoldTrait;
            boldToggleButton_.selected = inputStyleDescriptor.fontIsBold;
            italicToggleButton_.enabled = inputStyleDescriptor.fontFamilySupportsItalicTrait;
            italicToggleButton_.selected = inputStyleDescriptor.fontIsItalic;
        }
        else
        {
            NKTAttributedStringRangeInfo info = NKTInfoForAttributedStringRange(textView_.text, selectedTextRange.nsRange);
            boldToggleButton_.enabled = info.anyFontSupportsBold;
            boldToggleButton_.selected = info.anyFontIsBold;
            italicToggleButton_.enabled = info.anyFontSupportsItalic;
            italicToggleButton_.selected = info.anyFontIsItalic;
        }
    
        underlineToggleButton_.enabled = YES;
        underlineToggleButton_.selected = inputStyleDescriptor.textIsUnderlined; 
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
#pragma mark Text Editing

- (NSDictionary *)currentCoreTextAttributes
{
    NSString *familyName = fontPickerViewController_.selectedFontFamilyName;
    CGFloat fontSize = fontPickerViewController_.selectedFontSize;
    KBTFontFamilyDescriptor *familyDescriptor = [KBTFontFamilyDescriptor fontFamilyDescriptorWithFamilyName:familyName];
    BOOL bold = boldToggleButton_.selected && familyDescriptor.supportsBoldTrait;
    BOOL italic = italicToggleButton_.selected && familyDescriptor.supportsItalicTrait;
    BOOL underlined = underlineToggleButton_.selected;
    KBTStyleDescriptor *styleDescriptor = [KBTStyleDescriptor styleDescriptorWithFontFamilyName:familyName fontSize:fontSize bold:bold italic:italic underlined:underlined];
    return [styleDescriptor coreTextAttributes];
}

// These methods are meant to be used as callbacks by the text view in its
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
#pragma mark Text View Delegate

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
    allowUndoCheckpoint_ = YES;
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
    
    menuEnabledForSelectedTextRange_ = NO;
    [self dismissMenu];
    
    allowUndoCheckpoint_ = YES;
}

- (void)textViewDidChangeSelection:(NKTTextView *)textView
{
    [self updateTextEditingItems];

    menuEnabledForSelectedTextRange_ = NO;
    [self dismissMenu];
}

- (void)textView:(NKTTextView *)textView willChangeTextFromTextPosition:(NKTTextPosition *)textPosition
{    
    if (!allowUndoCheckpoint_)
    {
        return;
    }
    
    [self registerUndoForCurrentState];
    
    // Disallow more undos until checkpoint allowing change occurs
    allowUndoCheckpoint_ = NO;
}

- (void)textView:(NKTTextView *)textView didChangeTextFromTextPosition:(NKTTextPosition *)textPosition
{
    // Text view changes are saved at a certain frequency depending on the number and size of
    // changes
    [self enterSaveCheckpoint];
    
    if (notebookPopoverController_.popoverVisible)
    {
        [notebookPopoverController_ dismissPopoverAnimated:YES];
    }
    
    if (fontPopoverController_.popoverVisible)
    {
        [fontPopoverController_ dismissPopoverAnimated:YES];
    }
    
    // Only update title label when change occurs in the range of text the title is generated from
    if (textPosition.location < TitleSnippetSourceLength)
    {
        [self updateTitleLabel];
    }
    
    menuEnabledForSelectedTextRange_ = NO;
    [self dismissMenu];
    
    // Delegate might care about this too
    if ([delegate_ respondsToSelector:@selector(pageViewController:textView:didChangeFromTextPosition:)])
    {
        [delegate_ pageViewController:self textView:textView_ didChangeFromTextPosition:textPosition];
    }
}

- (void)textView:(NKTTextView *)textView willChangeStyleFromTextPosition:(NKTTextPosition *)textPosition
{
    [self registerUndoForCurrentState];
}

- (void)textView:(NKTTextView *)textView didChangeStyleFromTextPosition:(NKTTextPosition *)textPosition
{
    [self enterSaveCheckpoint];
    
    menuEnabledForSelectedTextRange_ = NO;
    [self dismissMenu];
}

#pragma mark -
#pragma mark Text View Gestures

- (void)textViewDidRecognizeTap:(NKTTextView *)textView previousSelectedTextRange:(NKTTextRange *)previousSelectedTextRange
{
    menuEnabledForSelectedTextRange_ = NO;
        
    if (previousSelectedTextRange != nil && [previousSelectedTextRange isEqualToTextRange:(NKTTextRange *)textView.selectedTextRange])
    {
        menuEnabledForSelectedTextRange_ = YES;
        [self presentMenu];
    }
    else
    {
        menuEnabledForSelectedTextRange_ = NO;
        [self dismissMenu];
    }
    
    allowUndoCheckpoint_ = YES;
}

- (void)textViewContinuousGestureDidBegin
{
    menuEnabledForSelectedTextRange_ = NO;
    [self dismissMenu];
    
    if (![textView_ isFirstResponder])
    {
        [self becomeFirstResponder];
    }
}

- (void)textViewContinuousGestureDidEnd
{
    menuEnabledForSelectedTextRange_ = YES;
    [self presentMenu];
    
    allowUndoCheckpoint_ = YES;
}

- (void)textViewLongPressDidBegin:(NKTTextView *)textView
{
    [self textViewContinuousGestureDidBegin];
}

- (void)textViewLongPressDidEnd:(NKTTextView *)textView
{
    [self textViewContinuousGestureDidEnd];
}

- (void)textViewDoubleTapDragDidBegin:(NKTTextView *)textView
{
    [self textViewContinuousGestureDidBegin];
}

- (void)textViewDoubleTapDragDidEnd:(NKTTextView *)textView
{
    [self textViewContinuousGestureDidEnd];
}

- (void)textViewDragBackwardDidBegin:(NKTTextView *)textView
{
    [self textViewContinuousGestureDidBegin];
}

- (void)textViewDragBackwardDidEnd:(NKTTextView *)textView
{
    [self textViewContinuousGestureDidEnd];
}

- (void)textViewDragForwardDidBegin:(NKTTextView *)textView
{
    [self textViewContinuousGestureDidBegin];
}

- (void)textViewDragForwardDidEnd:(NKTTextView *)textView
{
    [self textViewContinuousGestureDidEnd];
}

#pragma mark -
#pragma mark Scroll View Delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self updateMenuForTemporaryViewChangesOccuring];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
    {
        [self updateMenuForTemporaryViewChangesEnded];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self updateMenuForTemporaryViewChangesEnded];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self updateMenuForTemporaryViewChangesOccuring];
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView
{
    [self updateMenuForTemporaryViewChangesOccuring];
    return YES;
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView
{
    [self updateMenuForTemporaryViewChangesEnded];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self updateMenuForTemporaryViewChangesEnded];
}

#pragma mark -
#pragma mark Menu

- (void)presentMenu
{
    if (!menuEnabledForSelectedTextRange_ || menuDisabledForKeyboard_)
    {
        return;
    }
    
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    
    if (!menuController.menuVisible)
    {
        NKTTextRange *selectedTextRange = (NKTTextRange *)textView_.selectedTextRange;
        
        if (textView_.selectedTextRange == nil)
        {
            return;
        }
        
        CGRect firstRect = [textView_ firstRectForTextRange:selectedTextRange];
        CGRect lastRect = [textView_ lastRectForTextRange:selectedTextRange];
        CGRect textRangeRect = CGRectUnion(firstRect, lastRect);
        
        if (CGRectIsNull(textRangeRect))
        {
            return;
        }
        
        CGRect textViewBounds = textView_.bounds;
        // The target rect is the intersection between the text range rect and the text view bounds
        CGRect targetRect = CGRectIntersection(textRangeRect, textViewBounds);
        
        if (CGRectIsNull(targetRect))
        {
            return;
        }
        
        // Position menu arrow
        if (targetRect.origin.y > textViewBounds.origin.y)
        {
            menuController.arrowDirection = UIMenuControllerArrowDown;
        }
        else
        {
            menuController.arrowDirection = UIMenuControllerArrowUp;
        }
        
        [menuController setTargetRect:targetRect inView:textView_];
        [menuController setMenuVisible:YES animated:YES];
    }
}

- (void)dismissMenu
{
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    
    if (menuController.menuVisible)
    {
        [menuController setTargetRect:CGRectNull inView:textView_];
        [menuController setMenuVisible:NO animated:YES];
    }
}

- (void)updateMenuForTemporaryViewChangesOccuring
{    
    if ([self isFirstResponder] || [textView_ isFirstResponder])
    {
        [self dismissMenu];
    }
    
    // When the text view selection is empty and it isn't in editing more, the menu is not shown
    // because it would be visually confusing
    
    NKTTextRange *textRange = (NKTTextRange *)textView_.selectedTextRange;
    
    if (textRange == nil || (textRange.empty && !textView_.editing))
    {
        menuEnabledForSelectedTextRange_ = NO;
    }
}

- (void)updateMenuForTemporaryViewChangesEnded
{    
    if ([self isFirstResponder] || [textView_ isFirstResponder])
    {        
        UIMenuController *menuController = [UIMenuController sharedMenuController];
        
        if (!menuController.menuVisible)
        {
            [self presentMenu];
        }
    }
}

#pragma mark -
#pragma mark Cut/Copy/Paste

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    NKTTextRange *textRange = (NKTTextRange *)textView_.selectedTextRange;
    
    if (@selector(copy:) == action)
    {
        return !textRange.empty;
    }
    else if (@selector(cut:) == action)
    {
        return textView_.editing && !textRange.empty;
    }
    else if (@selector(paste:) == action)
    {
        UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
        NSArray *supportedPasteboardTypes = [NSArray arrayWithObjects:CodedAttributedStringDataTypeIdentifier, kUTTypeUTF8PlainText, nil];
        return textView_.editing && [pasteBoard containsPasteboardTypes:supportedPasteboardTypes];
    }
    else if (@selector(select:) == action)
    {
        return textRange.empty && [textView_ hasText];
    }
    else if (@selector(selectAll:) == action)
    {
        return textRange.empty && [textView_ hasText];
    }
    
    return NO;
}

- (void)cut:(id)sender
{
    if (!textView_.editing)
    {
        KBCLogWarning(@"Text view is not in editing mode. Ignoring");
        return;
    }
    
    [self copy:sender];
    [textView_ replaceRange:(NKTTextRange *)textView_.selectedTextRange withText:@"" notifyInputDelegate:YES];
    [textView_ updateSelectionDisplay];
    [textView_ scrollTextRangeToVisible:textView_.selectedTextRange animated:YES];
}

- (void)copy:(id)sender
{
    NKTTextRange *textRange = (NKTTextRange *)textView_.selectedTextRange;
    NSAttributedString *text = [textView_ text];
    NSAttributedString *attributedString = [text attributedSubstringFromRange:textRange.nsRange];
    
    if ([attributedString length] == 0)
    {
        return;
    }
    
    NSData *data = [KBTAttributedStringCodec dataWithAttributedString:attributedString];
    NSDictionary *representations = [NSDictionary dictionaryWithObjectsAndKeys:
        data , CodedAttributedStringDataTypeIdentifier,
        [attributedString string], kUTTypeUTF8PlainText,
        nil];
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.items = [NSArray arrayWithObject:representations];
}

- (void)paste:(id)sender
{    
    if (!textView_.editing)
    {
        KBCLogWarning(@"Text view is not in editing mode. Ignoring");
        return;
    }
    
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    NSArray *pasteboardTypes = [pasteboard pasteboardTypes];
    
    // Handle internally coded attributed string
    if ([pasteboardTypes containsObject:CodedAttributedStringDataTypeIdentifier])
    {
        NSData *data = [pasteboard dataForPasteboardType:CodedAttributedStringDataTypeIdentifier];
        NSAttributedString *attributedString = [KBTAttributedStringCodec attributedStringWithData:data];
        [textView_ replaceRange:(NKTTextRange *)textView_.selectedTextRange withAttributedString:attributedString notifyInputDelegate:YES];
        [textView_ updateSelectionDisplay];
        [textView_ scrollTextRangeToVisible:textView_.selectedTextRange animated:YES];
    }
    // Handle plain text
    else if ([pasteboardTypes containsObject:(id)kUTTypeUTF8PlainText])
    {
        NSString *string = [pasteboard valueForPasteboardType:(id)kUTTypeUTF8PlainText];
        [textView_ replaceRange:(NKTTextRange *)textView_.selectedTextRange withText:string notifyInputDelegate:YES];
        [textView_ updateSelectionDisplay];
        [textView_ scrollTextRangeToVisible:textView_.selectedTextRange animated:YES];        
    }
    else
    {
        KBCLogWarning(@"Pasting unsupported type. Ignoring");
    }
}

- (void)select:(id)sender
{
    NKTTextRange *textRange = [textView_ guessedTextRangeAtTextPosition:(NKTTextPosition *)textView_.selectedTextRange.start wordRange:NULL];
    
    if (textRange == nil)
    {
        return;
    }
    
    [textView_ setSelectedTextRange:textRange notifyInputDelegate:YES];
    [textView_ updateSelectionDisplay];
    menuEnabledForSelectedTextRange_ = YES;
    [self presentMenu];
}

- (void)selectAll:(id)sender
{
    NKTTextPosition *start = (NKTTextPosition *)[textView_ beginningOfDocument];
    NKTTextPosition *end = (NKTTextPosition *)[textView_ endOfDocument];
    NKTTextRange *textRange = [NKTTextRange textRangeWithTextPosition:start textPosition:end];
    [textView_ setSelectedTextRange:textRange notifyInputDelegate:YES];
    [textView_ updateSelectionDisplay];
    menuEnabledForSelectedTextRange_ = YES;
    [self presentMenu];
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

- (BOOL)keyboardFrameFromNotificationOverlapsTextView:(NSNotification *)notification
{
    CGRect textViewFrame = textView_.frame;
    CGRect keyboardFrame = [self keyboardFrameFromNotification:notification];
    CGFloat heightOverlap = CGRectGetMaxY(textViewFrame) - CGRectGetMinY(keyboardFrame);
    return heightOverlap > KeyboardOverlapTolerance;
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    [self growTextViewToAccomodateKeyboardFrameFromNotification:notification];

    if ([self keyboardFrameFromNotificationOverlapsTextView:notification])
    {
        menuDisabledForKeyboard_ = YES;
        [self updateMenuForTemporaryViewChangesOccuring];
    }
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    [self shrinkTextViewToAccomodateKeyboardFrameFromNotification:notification];
    menuDisabledForKeyboard_ = NO;
    [self updateMenuForTemporaryViewChangesEnded];
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
