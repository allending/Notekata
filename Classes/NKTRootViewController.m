//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTRootViewController.h"
#import "NKTEditNotebookViewController.h"
#import "NKTNotebook.h"
#import "NKTNotebookViewController.h"
#import "NKTPage.h"
#import "NKTPageViewController.h"

@interface NKTRootViewController()

@property (nonatomic, readwrite, retain) NKTNotebook *selectedNotebook;

@end

@implementation NKTRootViewController

@synthesize managedObjectContext = managedObjectContext_;
@synthesize fetchedResultsController = fetchedResultsController_;
@synthesize selectedNotebook = selectedNotebook_;

@synthesize notebookViewController = notebookViewController_;
@synthesize pageViewController = pageViewController_;
@synthesize editNotebookViewController = editNotebookViewController_;

@synthesize titleLabel = titleLabel_;
@synthesize addNotebookItem = addNotebookItem_;
@synthesize addNotebookActionSheet = addNotebookActionSheet_;

static NSString *SelectedNotebookIdKey = @"SelectedNotebookId";
static const NSUInteger AddNotebookButtonIndex = 0;

#pragma mark -
#pragma mark Memory

- (void)dealloc
{
    [managedObjectContext_ release];
    [fetchedResultsController_ release];
    [selectedNotebook_ release];
    
    [editNotebookViewController_ release];
    
    [notebookViewController_ release];
    [pageViewController_ release];
    
    [titleLabel_ release];
    [addNotebookItem_ release];
    [addNotebookActionSheet_ release];
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
    self.clearsSelectionOnViewWillAppear = YES;
    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // Create edit view controller
    editNotebookViewController_ = [[NKTEditNotebookViewController alloc] init];
    editNotebookViewController_.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    editNotebookViewController_.managedObjectContext = managedObjectContext_;
    editNotebookViewController_.delegate = self;
    
    // Create custom navigation title view
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 20.0)];
    label.text = @"Notebooks";
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = UITextAlignmentCenter;
    label.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0];
    label.textColor = [UIColor lightTextColor];
    self.navigationItem.titleView = label;
    [label release];
    
    // Create toolbar items
    addNotebookItem_ = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(handleAddNotebookItemTapped:)];
    self.toolbarItems = [NSArray arrayWithObjects:addNotebookItem_, nil];
    
    // Fetch
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error])
    {
        // PENDING: fix and log
        KBCLogWarning(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.editNotebookViewController = nil;
    self.titleLabel = nil;
    self.addNotebookItem = nil;
    self.addNotebookActionSheet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // There seems to be a bug in UIKit where the navigation controller navigation bar and toolbar may not respect
    // the set styles after rotation animations. As a workaround, we force the style.    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    self.navigationController.toolbar.barStyle = UIBarStyleBlackOpaque;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (selectedNotebook_ != nil)
    {
        [[NSUserDefaults standardUserDefaults] setObject:selectedNotebook_.notebookId forKey:SelectedNotebookIdKey];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // Stop editing when rotation occurs so the page view controller is always unfrozen after rotation
    [self setEditing:NO animated:NO];
    // Dismiss open modals and sheets
    [addNotebookActionSheet_ dismissWithClickedButtonIndex:-1 animated:NO];
    [self dismissModalViewControllerAnimated:NO];
}

#pragma mark -
#pragma mark Editing

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    // PENDING: find Core Animation bug workaround when this animated: parameter is YES
    [self.navigationItem setHidesBackButton:editing animated:NO];
    
    if (editing)
    {
        [self setToolbarItems:nil animated:YES];
        [pageViewController_.textView resignFirstResponder];
        [pageViewController_ freezeUserInteraction];
    }
    else
    {
        [self setToolbarItems:[NSArray arrayWithObjects:addNotebookItem_, nil] animated:YES];
        [pageViewController_ unfreezeUserInteraction];
    }
}

#pragma mark -
#pragma mark Notebooks

- (void)selectInitialNotebook
{
    if (![self isViewLoaded])
    {
        KBCLogWarning(@"This method can only be called after the view has been loaded. Returning.");
        return;
    }
    
    NSArray *notebooks = [self.fetchedResultsController fetchedObjects];
    
    if ([notebooks count] == 0)
    {
        KBCLogWarning(@"No notebooks exist. A notebook must exist prior to this method being called. Returning.");
        return;
    }
    
    NKTNotebook *notebook = nil;
    NSString *notebookId = [[NSUserDefaults standardUserDefaults] objectForKey:SelectedNotebookIdKey];
    
    if (notebookId != nil)
    {
        // Search for the notebook with the saved id
        for (NKTNotebook *currentNotebook in notebooks)
        {
            if ([notebookId isEqualToString:currentNotebook.notebookId])
            {
                notebook = currentNotebook;
                break;
            }
        }
    }
    
    // As a last resort, fallback to the first notebook
    if (notebook == nil)
    {
        notebook = [self notebookAtIndex:0];
    }
    
    self.selectedNotebook = notebook;
    [notebookViewController_ setNotebook:notebook restoreLastSelectedPage:YES];
    [self.navigationController pushViewController:notebookViewController_ animated:NO];
}

- (NSUInteger)numberOfNotebooks
{
    return [[[self.fetchedResultsController sections] objectAtIndex:0] numberOfObjects];
}

- (NKTNotebook *)notebookAtIndex:(NSUInteger)index
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    return [self.fetchedResultsController objectAtIndexPath:indexPath];
}

#pragma mark -
#pragma mark Actions

- (void)handleAddNotebookItemTapped:(UIBarButtonItem *)item
{
    if (!addNotebookActionSheet_.visible)
    {
        [addNotebookActionSheet_ release];
        addNotebookActionSheet_ = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Add Notebook", nil];
        [addNotebookActionSheet_ showFromBarButtonItem:item animated:YES];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex)
    {
        case AddNotebookButtonIndex:
            [self presentAddNotebookViewController];
            break;
            
        default:
            break;
    }
    
    [addNotebookActionSheet_ autorelease];
    addNotebookActionSheet_ = nil;
}

- (void)presentAddNotebookViewController
{
    [editNotebookViewController_ configureToAddNotebook];
    [self presentModalViewController:editNotebookViewController_ animated:YES];
}

#pragma mark -
#pragma mark Edit Notebook View Controller

- (void)editNotebookViewController:(NKTEditNotebookViewController *)editNotebookViewController didAddNotebook:(NKTNotebook *)notebook
{
    // Set new notebook
    self.selectedNotebook = notebook;
    // Scroll to added notebook
    NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:notebook];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
    
    // Update notebook view controller
    [notebookViewController_ setNotebook:notebook restoreLastSelectedPage:NO];
    [self.navigationController pushViewController:notebookViewController_ animated:YES];    
    
    // Configure controllers to start editing notebook almost immediately. Dismiss the modal and
    // make the text view first responder following a short delay (this gets around some
    // undesirable keyboard behavior that occurs if performed immediately).
    [self dismissModalViewControllerAnimated:NO];
    [pageViewController_ dismissNavigationPopoverAnimated:YES];
    [pageViewController_.textView performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.1];
}

- (void)editNotebookViewController:(NKTEditNotebookViewController *)editNotebookViewController didEditNotebook:(NKTNotebook *)notebook
{
    [self dismissModalViewControllerAnimated:YES];    
}

#pragma mark -
#pragma mark Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return  [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[self.fetchedResultsController sections] objectAtIndex:section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        cell.showsReorderControl = YES;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.editingAccessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NKTNotebook *notebook = [self.fetchedResultsController objectAtIndexPath:indexPath];

    // HACK: the automatic width of the text label is different if set during editing vs. if it was
    // set prior to editing. This hack makes the presentation of the text label consistent no
    // matter what state it is in.
    BOOL wasEditing = cell.editing;
    [cell setEditing:NO animated:NO];
    cell.textLabel.text = notebook.title;
    [cell setEditing:wasEditing animated:NO];
    
    NSUInteger numberOfPages = [[notebook pages] count];
    if (numberOfPages > 1)
    {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%d pages", numberOfPages];
    }
    else
    {
        cell.detailTextLabel.text = @"1 page";
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle != UITableViewCellEditingStyleDelete)
    {
        KBCLogWarning(@"unexpected editing style commit, returning");
        return;
    }
    
    NKTNotebook *notebookToDelete = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSUInteger numberOfNotebooks = [self numberOfNotebooks];
    
    // Stop editing page if we are about to delete it
    if (notebookToDelete == selectedNotebook_)
    {
        self.selectedNotebook = nil;
        [notebookViewController_ setNotebook:nil restoreLastSelectedPage:NO];
    }
    
    // Renumber the notebooks first
    NSUInteger renumberRangeStart = indexPath.row + 1;
    NSUInteger renumberRangeEnd = numberOfNotebooks;
    for (NSUInteger index = renumberRangeStart; index < renumberRangeEnd; ++index)
    {
        NSIndexPath *renumberIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
        NKTNotebook *notebookToRenumber = [self.fetchedResultsController objectAtIndexPath:renumberIndexPath];
        //  Adjust offsets of pages following the deleted page by -1
        NSUInteger displayOrder = index - 1;
        notebookToRenumber.displayOrder = [NSNumber numberWithInteger:displayOrder];
    }
    
    // Delete the notebook
    [managedObjectContext_ deleteObject:notebookToDelete];
    
    // Add a page if the deleted page was the last one
    if (numberOfNotebooks == 1)
    {
        // Create notebook
        NKTNotebook *notebook = [NSEntityDescription insertNewObjectForEntityForName:@"Notebook" inManagedObjectContext:managedObjectContext_];
        // PENDING: localize
        notebook.title = @"My Notebook";
        
        // Generate random uuid as the notebook id
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);
        notebook.notebookId = (NSString *)uuidString;
        CFRelease(uuid);
        CFRelease(uuidString);
        
        // Default display order
        notebook.displayOrder = [NSNumber numberWithUnsignedInt:0];
        // Create first page
        NKTPage *page = [NSEntityDescription insertNewObjectForEntityForName:@"Page" inManagedObjectContext:managedObjectContext_];
        page.pageNumber = [NSNumber numberWithInteger:0];
        page.textString = @"";
        page.textStyleString = @"";
        [notebook addPagesObject:page];
    }
    
    NSError *error = nil;
    if (![managedObjectContext_ save:&error])
    {
        // PENDING: fix and log
        KBCLogWarning(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    NSUInteger fromIndex = fromIndexPath.row;
    NSUInteger toIndex = toIndexPath.row;
    
    if (fromIndex == toIndex)
    {
        return;
    }
    
    // Set flag so we know to ignore changes from the fetch results controller
    changeIsUserDriven_ = YES;
    
    // Set display order of moved notebook
    NKTNotebook *notebook = [self.fetchedResultsController objectAtIndexPath:fromIndexPath];
    notebook.displayOrder = [NSNumber numberWithUnsignedInteger:toIndex];
    
    // Renumber rest of the notebooks
    NSUInteger renumberRangeStart = 0;
    NSUInteger renumberRangeEnd = 0;
    NSInteger displayOrderAdjustment = 0;
    
    if (fromIndex < toIndex)
    {
        renumberRangeStart = fromIndex + 1;
        renumberRangeEnd = toIndex + 1;
        displayOrderAdjustment = -1;
    }
    else
    {
        renumberRangeStart = toIndex;
        renumberRangeEnd = fromIndex;
        displayOrderAdjustment = 1;
    }
    
    for (NSUInteger index = renumberRangeStart; index < renumberRangeEnd; ++index)
    {
        NSIndexPath *renumberIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
        NKTNotebook *notebookToRenumber = [self.fetchedResultsController objectAtIndexPath:renumberIndexPath];
        NSInteger displayOrder = [notebookToRenumber.displayOrder integerValue] + displayOrderAdjustment;
        notebookToRenumber.displayOrder = [NSNumber numberWithInteger:displayOrder];
    }
    
    NSError *error = nil;
    if (![managedObjectContext_ save:&error])
    {
        // PENDING: fix and log
        KBCLogWarning(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    changeIsUserDriven_ = NO;
}

#pragma mark -
#pragma mark Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NKTNotebook *notebook = [self.fetchedResultsController objectAtIndexPath:indexPath];
    self.selectedNotebook = notebook;
    [notebookViewController_ setNotebook:notebook restoreLastSelectedPage:YES];
    [self.navigationController pushViewController:notebookViewController_ animated:YES];
    // Popover in page view controller not dismissed - chances are the user will select different page
    [pageViewController_.textView resignFirstResponder];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    NKTNotebook *notebook = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [editNotebookViewController_ configureToEditNotebook:notebook];
    [self presentModalViewController:editNotebookViewController_ animated:YES];
}

#pragma mark -
#pragma mark Fetched Results Controller

- (NSFetchedResultsController *)fetchedResultsController
{    
    if (fetchedResultsController_ != nil)
    {
        return fetchedResultsController_;
    }
    
    // Create request for all notebooks sorted by display order
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Notebook" inManagedObjectContext:managedObjectContext_];
    [fetchRequest setEntity:entity];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"displayOrder" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    // Create the controller
    fetchedResultsController_ = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:managedObjectContext_ sectionNameKeyPath:nil cacheName:nil];
    fetchedResultsController_.delegate = self;
    
    [fetchRequest release];
    [sortDescriptor release];
    return fetchedResultsController_;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller 
{
    if (changeIsUserDriven_)
    {
        return;
    }
    
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    KBCLogWarning(@"this should never be called");
    
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    if (changeIsUserDriven_)
    {
        return;
    }
        
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if (changeIsUserDriven_)
    {
        return;
    }
    
    [self.tableView endUpdates];
}

@end
