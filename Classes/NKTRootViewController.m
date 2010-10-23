//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTRootViewController.h"
#import "NKTNotebookEditViewController.h"
#import "NKTNotebook.h"
#import "NKTNotebookViewController.h"
#import "NKTPage.h"
#import "NKTPageViewController.h"

@interface NKTRootViewController()

@property (nonatomic, readwrite, retain) NKTNotebook *selectedNotebook;

@end

@implementation NKTRootViewController

@synthesize selectedNotebook = selectedNotebook_;

@synthesize notebookViewController = notebookViewController_;
@synthesize pageViewController = pageViewController_;
@synthesize notebookEditViewController = notebookEditViewController_;

@synthesize notebookAddItem = notebookAddItem_;
@synthesize notebookDeleteIndexPath = notebookDeleteIndexPath_;

@synthesize managedObjectContext = managedObjectContext_;
@synthesize fetchedResultsController = fetchedResultsController_;

static NSString *SelectedNotebookIdKey = @"SelectedNotebookId";
static const NSUInteger AddNotebookButtonIndex = 0;

static const NSUInteger AddActionSheetTag = 0;
static const NSUInteger DeleteConfirmationActionSheetTag = 0;

#pragma mark -
#pragma mark Memory

- (void)dealloc
{
    [selectedNotebook_ release];
    
    [notebookEditViewController_ release];
    [notebookViewController_ release];
    [pageViewController_ release];
    
    [notebookAddItem_ release];
//    [notebookAddActionSheet_ release];
    [notebookDeleteIndexPath_ release];
    [deleteConfirmationActionSheet_ release];
    
    [managedObjectContext_ release];
    [fetchedResultsController_ release];
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
    notebookEditViewController_ = [[NKTNotebookEditViewController alloc] init];
    notebookEditViewController_.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    notebookEditViewController_.managedObjectContext = managedObjectContext_;
    notebookEditViewController_.delegate = self;
        
    // Create custom navigation title
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 20.0)];
    label.text = @"Notebooks";
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = UITextAlignmentCenter;
    label.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0];
    label.textColor = [UIColor whiteColor];
    self.navigationItem.titleView = label;
    [label release];
    
    // Create toolbar items
    notebookAddItem_ = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNotebookTapped:)];
    self.toolbarItems = [NSArray arrayWithObjects:notebookAddItem_, nil];
    
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
    self.notebookEditViewController = nil;
    self.notebookAddItem = nil;
    self.notebookDeleteIndexPath = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // There seems to be a bug in UIKit where the navigation controller navigation bar and toolbar may not respect
    // the set styles after rotation animations. As a workaround, we force the style.    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.toolbar.barStyle = UIBarStyleBlack;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    // Save last selected notebook id
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
    // Stop editing when rotation occurs so the page view controller is in an unfrozen state
    [self setEditing:NO animated:NO];
    // PENDING: is this really needed?
    // Dismiss open sheets
    [addActionSheet_ dismissWithClickedButtonIndex:addActionSheet_.cancelButtonIndex animated:NO];
    addActionSheet_ = nil;
    [deleteConfirmationActionSheet_ dismissWithClickedButtonIndex:deleteConfirmationActionSheet_.cancelButtonIndex animated:NO];
    deleteConfirmationActionSheet_ = nil;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    // PENDING: find Core Animation bug workaround when this is animated
    [self.navigationItem setHidesBackButton:editing animated:NO];
    
    if (editing)
    {
        [self setToolbarItems:nil animated:YES];
        [pageViewController_.textView resignFirstResponder];
        [pageViewController_ freeze];
    }
    else
    {
        [self setToolbarItems:[NSArray arrayWithObjects:notebookAddItem_, nil] animated:YES];
        [pageViewController_ unfreeze];
    }
}

#pragma mark -
#pragma mark Notebooks

- (void)selectInitialNotebook
{
    // Should only be used after the view has been loaded, or there will be no fetched data
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

- (void)deleteNotebookAtIndexPath:(NSIndexPath *)indexPath
{
    NKTNotebook *notebookToDelete = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSUInteger numberOfNotebooks = [self numberOfNotebooks];
    BOOL deletingLastNotebook = (numberOfNotebooks == 1);
    
    // Need to inform everyone else if we are going to delete the selected notebook
    if (notebookToDelete == selectedNotebook_)
    {
        self.selectedNotebook = nil;
        [notebookViewController_ setNotebook:nil restoreLastSelectedPage:NO];
    }
    
    // Renumber the notebooks first by adjusting offsets of pages following the deleted page by -1
    NSUInteger renumberRangeStart = indexPath.row + 1;
    NSUInteger renumberRangeEnd = numberOfNotebooks;
    for (NSUInteger index = renumberRangeStart; index < renumberRangeEnd; ++index)
    {
        NSIndexPath *renumberIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
        NKTNotebook *notebookToRenumber = [self.fetchedResultsController objectAtIndexPath:renumberIndexPath];
        NSUInteger displayOrder = index - 1;
        notebookToRenumber.displayOrder = [NSNumber numberWithInteger:displayOrder];
    }
    
    // Delete the notebook
    [managedObjectContext_ deleteObject:notebookToDelete];
    
    // Create a default notebook if we just deleted the last one
    if (deletingLastNotebook)
    {
        // Create notebook
        NKTNotebook *notebook = [NSEntityDescription insertNewObjectForEntityForName:@"Notebook" inManagedObjectContext:managedObjectContext_];
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

#pragma mark -
#pragma mark Actions

- (void)addNotebookTapped:(id)sender
{
    if (addActionSheet_.visible)
    {
        [addActionSheet_ dismissWithClickedButtonIndex:addActionSheet_.cancelButtonIndex animated:YES];
        addActionSheet_ = nil;
        return;
    }
    
    addActionSheet_ = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Add Notebook", nil];
    [addActionSheet_ showFromBarButtonItem:notebookAddItem_ animated:YES];
    [addActionSheet_ release];
}

- (void)presentNotebookAddViewController
{
    [notebookEditViewController_ configureToAddNotebook];
    [self presentModalViewController:notebookEditViewController_ animated:YES];
}

- (void)presentNotebookEditViewControllerForNotebookAtIndexPath:(NSIndexPath *)indexPath
{
    NKTNotebook *notebook = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [notebookEditViewController_ configureToEditNotebook:notebook];
    [self presentModalViewController:notebookEditViewController_ animated:YES];
}

- (void)presentNotebookDeleteConfirmationForNotebookAtIndexPath:(NSIndexPath *)indexPath
{
    self.notebookDeleteIndexPath = indexPath;
    deleteConfirmationActionSheet_ = [[UIActionSheet alloc] initWithTitle:@"Are You Sure?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:nil];
    [deleteConfirmationActionSheet_ showInView:self.view];
    [deleteConfirmationActionSheet_ release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet == deleteConfirmationActionSheet_)
    {
        if (buttonIndex == actionSheet.destructiveButtonIndex)
        {
            [self deleteNotebookAtIndexPath:notebookDeleteIndexPath_];
        }
        
        self.notebookDeleteIndexPath = nil;
        deleteConfirmationActionSheet_ = nil;
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (actionSheet == addActionSheet_)
    {
        if (buttonIndex == addActionSheet_.firstOtherButtonIndex)
        {
            [self presentNotebookAddViewController];
        }
        
        addActionSheet_ = nil;
    }
}

#pragma mark -
#pragma mark Notebook Edit View Controller

- (void)notebookEditViewControllerDidCancel:(NKTNotebookEditViewController *)notebookEditViewController
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)notebookEditViewController:(NKTNotebookEditViewController *)notebookEditViewController didAddNotebook:(NKTNotebook *)notebook
{
    // Set new notebook
    self.selectedNotebook = notebook;
    
    // Scroll to added notebook
    NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:notebook];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
    
    // Update notebook view controller
    [notebookViewController_ setNotebook:notebook restoreLastSelectedPage:NO];
    [self.navigationController pushViewController:notebookViewController_ animated:YES];
    
    // NOTE: We dismiss the modal without animation and make the text view first responder
    // following a short delay to get around some undesirable keyboard behavior that occurs if
    // performed immediately.
    [pageViewController_ dismissNotebookPopoverAnimated:YES];
    [pageViewController_.textView performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.1];
    [self dismissModalViewControllerAnimated:NO];
}

- (void)notebookEditViewController:(NKTNotebookEditViewController *)notebookEditViewController didEditNotebook:(NKTNotebook *)notebook
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
    
    // Update text with title
    // HACK: the automatic width of the text label is different if set during editing vs. if it
    // was set prior to editing. This hack makes the presentation of the text label consistent.
    if (cell.editing)
    {
        [cell setEditing:NO animated:NO];
        cell.textLabel.text = notebook.title;
        [cell setEditing:YES animated:NO];
    }
    else
    {
        cell.textLabel.text = notebook.title;
    }
    
    // Update detail text with page count
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
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [self presentNotebookDeleteConfirmationForNotebookAtIndexPath:indexPath];
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
    [pageViewController_.textView resignFirstResponder];
    // Popover in page view controller not dismissed so the user can select a different page
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    [self presentNotebookEditViewControllerForNotebookAtIndexPath:indexPath];
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
    KBCLogWarning(@"This method should never be called");
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
