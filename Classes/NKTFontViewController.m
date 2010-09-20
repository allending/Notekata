//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTFontViewController.h"

@interface NKTFontViewController()

#pragma mark Getting Font Family Names

@property (nonatomic, readonly) NSArray *familyNames;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------

@implementation NKTFontViewController

@synthesize delegate = delegate_;

#pragma mark Initialization

- (id)initWithStyle:(UITableViewStyle)style
{
    if ((self = [super initWithStyle:style]))
    {
        selectionIndex_ = NSNotFound;
    }
    
    return self;
}

- (void)dealloc
{
    [familyNames_ release];
    [super dealloc];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Memory management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [familyNames_ release];
    familyNames_ = nil;
}

- (void)viewDidUnload
{
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}

//--------------------------------------------------------------------------------------------------

#pragma mark View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Preserve selection between presentations.
     self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (selectionIndex_ != NSNotFound)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:selectionIndex_ inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Font Family Names

- (NSArray *)familyNames
{
    if (familyNames_ == nil)
    {
        familyNames_ = [[[UIFont familyNames] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] copy];
    }
    
    return familyNames_;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Setting the Selected Family Name

- (NSString *)selectedFamilyName
{
    if (selectionIndex_ != NSNotFound)
    {
        return [self.familyNames objectAtIndex:selectionIndex_];
    }
    else
    {
        return nil;
    }
}

- (void)setSelectedFamilyName:(NSString *)selectedFamilyName
{
    NSUInteger newSelectionIndex = [self.familyNames indexOfObject:selectedFamilyName];
    
    if (newSelectionIndex == NSNotFound)
    {
        KBCLogWarning(@"'%@' is not an available family name", selectedFamilyName);
        return;
    }
    
    if (selectionIndex_ == newSelectionIndex)
    {
        return;
    }

    selectionIndex_ = newSelectionIndex;
    
    if (![self isViewLoaded])
    {
        return;
    }
    
    // Make sure the table data has been created
    [self.tableView reloadData];
    
    // Deselect previous row
    NSIndexPath *existingIndexPath = [self.tableView indexPathForSelectedRow];
    
    if (existingIndexPath != nil)
    {
        [self.tableView deselectRowAtIndexPath:existingIndexPath animated:NO];
    }
    
    // Select new row
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:newSelectionIndex inSection:0];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.familyNames count];
}

static NSString *NKTFontViewControllerCellIdentifier = @"NKTFontViewControllerCellIdentifier";

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NKTFontViewControllerCellIdentifier];
    
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:NKTFontViewControllerCellIdentifier] autorelease];
    }
    
    NSString *familyName = [self.familyNames objectAtIndex:indexPath.row];
    cell.textLabel.font = [UIFont fontWithName:familyName size:18.0];
    cell.textLabel.text = familyName;
    
    if (indexPath.row == selectionIndex_)
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
    if (selectionIndex_ == indexPath.row)
    {
        return;
    }
    
    if (selectionIndex_ != NSNotFound)
    {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectionIndex_ inSection:0]];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    selectionIndex_ = indexPath.row;
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    if ([delegate_ respondsToSelector:@selector(fontViewController:didSelectFamilyName:)])
    {
        [delegate_ fontViewController:self didSelectFamilyName:self.selectedFamilyName];
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
