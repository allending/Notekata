//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTFontPickerViewController.h"
#import "NKTFontPickerView.h"

@interface NKTFontPickerViewController()

#pragma mark Accessing the Font Picker View

@property (nonatomic, readonly) NKTFontPickerView *fontPickerView;

#pragma mark Getting Font Family Names

@property (nonatomic, readonly) NSArray *fontFamilyNames;

#pragma mark Creating a Font Size Control

- (KUISegmentedControl *)fontSizeSegmentedControl;

#pragma mark Responding to Font Size Changes

- (void)fontSizeSegmentedControlTouchDown:(KUISegmentedControl *)segmentedControl;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------

@implementation NKTFontPickerViewController

@synthesize delegate = delegate_;
@synthesize availableFontSizes = availableFontSizes_;

static NSString * const CellIdentifier = @"CellIdentifier";

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
    {
        // Init with reasonable available font sizes
        availableFontSizes_ = [[NSArray arrayWithObjects:[NSNumber numberWithFloat:12.0],
                                                         [NSNumber numberWithFloat:16.0],
                                                         [NSNumber numberWithFloat:24.0],
                                                         [NSNumber numberWithFloat:32.0],
                                                         nil] retain];
        selectedFontSizeIndex_ = 0;
        selectedFontFamilyNameIndex_ = NSNotFound;
    }
    
    return self;
}

- (void)dealloc
{
    [availableFontSizes_ release];
    [fontFamilyNames_ release];
    [super dealloc];
}

//--------------------------------------------------------------------------------------------------

#pragma mark View Lifecycle and Memory Management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [fontFamilyNames_ release];
    fontFamilyNames_ = nil;
}

- (void)loadView
{
    // Create the font picker view which contains a font size control and font family table
    NKTFontPickerView *fontPickerView = [[NKTFontPickerView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // Create and hook up to the font size control
    fontPickerView.fontSizeSegmentedControl = [self fontSizeSegmentedControl];
    
    if (selectedFontSizeIndex_ != NSNotFound)
    {
        fontPickerView.fontSizeSegmentedControl.selectedSegmentIndex = selectedFontSizeIndex_;
    }
    
    // Hook up to the font family table view
    fontPickerView.fontFamilyTableView.dataSource = self;
    fontPickerView.fontFamilyTableView.delegate = self;
    
    self.view = fontPickerView;
    [fontPickerView release];    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (selectedFontFamilyNameIndex_ != NSNotFound)
    {
        [self.fontPickerView.fontFamilyTableView reloadData];
        // Force font picker view layout if needed because we are going to ask it to scroll
        // before it has had a change to layout its subviews
        [self.fontPickerView layoutIfNeeded];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:selectedFontFamilyNameIndex_ inSection:0];
        [self.fontPickerView.fontFamilyTableView scrollToRowAtIndexPath:indexPath
                                                       atScrollPosition:UITableViewScrollPositionMiddle
                                                               animated:NO];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Accessing the Font Picker View

- (NKTFontPickerView *)fontPickerView
{
    if ([self isViewLoaded])
    {
        return (NKTFontPickerView *)self.view;
    }
    else
    {
        return nil;
    }
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Font Family Names

- (NSArray *)fontFamilyNames
{
    if (fontFamilyNames_ == nil)
    {
        fontFamilyNames_ = [[NSArray alloc] initWithObjects:
//                            "Academy Engraved LET",
                            @"American Typewriter",
//                            AppleGothic,
//                            Arial,
//                            "Arial Hebrew",
//                            "Arial Rounded MT Bold",
                            @"Baskerville",
//                            "Bodoni 72",
//                            "Bodoni 72 Oldstyle",
//                            "Bodoni 72 Smallcaps",
//                            "Bodoni Ornaments",
//                            @"Bradley Hand",
//                            Chalkduster,
                            @"Cochin",
                            @"Copperplate",
                            @"Courier",
//                            "Courier New",
//                            "DB LCD Temp",
                            @"Didot",
                            @"Futura",
//                            "Geeza Pro",
                            @"Georgia",
                            @"Gill Sans",
//                            "Heiti J",
//                            "Heiti K",
//                            "Heiti SC",
//                            "Heiti TC",
                            @"Helvetica",
                            @"Helvetica Neue",
//                            "Hiragino Kaku Gothic ProN",
//                            "Hiragino Mincho ProN",
                            @"Hoefler Text",
                            @"Marker Felt",
                            @"Optima",
                            @"Palatino",
                            @"Papyrus",
//                            "Party LET",
                            @"Snell Roundhand",
//                            Thonburi,
                            @"Times New Roman",
//                            "Trebuchet MS",
                            @"Verdana",
//                            "Zapf Dingbats",
                            @"Zapfino",
                            nil];
    }
    
    return fontFamilyNames_;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Creating a Font Size Control

- (KUISegmentedControl *)fontSizeSegmentedControl
{
    // Create an array of titles with the new available font sizes
    NSMutableArray *fontSizeTitles = [NSMutableArray array];
    
    // The titles have the form "12 pt"
    for (NSNumber *fontSizeNumber in availableFontSizes_)
    {
        NSString *fontSizeTitle = [NSString stringWithFormat:@"%d pt", [fontSizeNumber unsignedIntegerValue]];
        [fontSizeTitles addObject:fontSizeTitle];
    }
    
    KUISegmentedControl *fontSizeSegmentedControl = [[[KUISegmentedControl alloc] initWithItems:fontSizeTitles] autorelease];
    [fontSizeSegmentedControl addTarget:self
                                 action:@selector(fontSizeSegmentedControlTouchDown:)
                       forControlEvents:UIControlEventTouchDown];
    return fontSizeSegmentedControl;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Configuring the Font Size

- (void)setAvailableFontSizes:(NSArray *)availableFontSizes
{
    // Reset the selected font size index when the available font sizes are being set
    selectedFontSizeIndex_ = NSNotFound;
    
    if (availableFontSizes_ == availableFontSizes)
    {
        return;
    }
    
    [availableFontSizes_ release];
    availableFontSizes_ = [availableFontSizes copy];
    
    // Recreate the font size segmented control if view is currently loaded, else it will be done in -loadView
    if ([self isViewLoaded])
    {
        self.fontPickerView.fontSizeSegmentedControl = [self fontSizeSegmentedControl];
    }
}

- (NSUInteger)selectedFontSize
{
    if (selectedFontSizeIndex_ == NSNotFound)
    {
        KBCLogWarning(@"selected font size index is NSNotFound, returning 0.0");
        return 0.0;
    }
    
    NSNumber *fontSizeNumber = [availableFontSizes_ objectAtIndex:selectedFontSizeIndex_];
    return [fontSizeNumber unsignedIntegerValue];
}

- (void)setSelectedFontSize:(NSUInteger)selectedFontSize
{
    NSUInteger index = [availableFontSizes_ indexOfObject:[NSNumber numberWithUnsignedInt:selectedFontSize]];
    
    if (index == NSNotFound)
    {
        KBCLogWarning(@"%d is not an available font size, ignoring", selectedFontSize);
        return;
    }
    
    if (selectedFontSizeIndex_ == index)
    {
        return;
    }
    
    selectedFontSizeIndex_ = index;
    
    // We are done if this is called when the view is not visible
    if (![self isViewLoaded])
    {
        return;
    }

    self.fontPickerView.fontSizeSegmentedControl.selectedSegmentIndex = selectedFontSizeIndex_;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Responding to Font Size Changes

- (void)fontSizeSegmentedControlTouchDown:(KUISegmentedControl *)segmentedControl
{
    selectedFontSizeIndex_ = segmentedControl.selectedSegmentIndex;
    
    if ([delegate_ respondsToSelector:@selector(fontPickerViewController:didSelectFontSize:)])
    {
        [delegate_ fontPickerViewController:self didSelectFontSize:self.selectedFontSize];
    }
}

//--------------------------------------------------------------------------------------------------

#pragma mark Configuring Font Family Names

- (NSString *)selectedFontFamilyName
{
    if (selectedFontFamilyNameIndex_ != NSNotFound)
    {
        return [self.fontFamilyNames objectAtIndex:selectedFontFamilyNameIndex_];
    }
    else
    {
        return nil;
    }
}

- (void)setSelectedFontFamilyName:(NSString *)selectedFontFamilyName
{
    NSUInteger index = [self.fontFamilyNames indexOfObject:selectedFontFamilyName];
    
    if (index == NSNotFound)
    {
        KBCLogWarning(@"'%@' is not an available font family name, ignoring", selectedFontFamilyName);
        return;
    }
    
    if (selectedFontFamilyNameIndex_ == index)
    {
        return;
    }
    
    selectedFontFamilyNameIndex_ = index;
    
    // We are done if this is called when the view is not visible
    if (![self isViewLoaded])
    {
        return;
    }
    
    // Make sure the table data has been created if the view has been loaded
    [self.fontPickerView.fontFamilyTableView reloadData];
    
    // Deselect the previous row if possible
    NSIndexPath *previousIndexPath = [self.fontPickerView.fontFamilyTableView indexPathForSelectedRow];
    
    if (previousIndexPath != nil)
    {
        [self.fontPickerView.fontFamilyTableView deselectRowAtIndexPath:previousIndexPath animated:NO];
    }
    
    // Select the new row
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:selectedFontFamilyNameIndex_ inSection:0];
    [self.fontPickerView.fontFamilyTableView selectRowAtIndexPath:indexPath
                                                         animated:NO
                                                   scrollPosition:UITableViewScrollPositionMiddle];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.fontFamilyNames count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Set up the cell to show the font family name using the font itself
    NSString *fontFamilyName = [self.fontFamilyNames objectAtIndex:indexPath.row];
    cell.textLabel.text = fontFamilyName;
    cell.textLabel.font = [UIFont fontWithName:fontFamilyName size:16.0];
    
    if (indexPath.row == selectedFontFamilyNameIndex_)
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Uncheck previously selected cell
    if (selectedFontFamilyNameIndex_ != NSNotFound)
    {
        NSIndexPath *previousIndexPath = [NSIndexPath indexPathForRow:selectedFontFamilyNameIndex_ inSection:0];
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:previousIndexPath];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    selectedFontFamilyNameIndex_ = indexPath.row;
    
    // Apply checkmark to selected cell
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    // Deselect just selected row to make the highlight go away (we have already store the
    // selection index and updated the accessory)
    [self.fontPickerView.fontFamilyTableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ([delegate_ respondsToSelector:@selector(fontPickerViewController:didSelectFontFamilyName:)])
    {
        [delegate_ fontPickerViewController:self didSelectFontFamilyName:self.selectedFontFamilyName];
    }
}

@end
