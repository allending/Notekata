//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTRootViewController.h"
#import "NKTNotebook+CustomAdditions.h"
#import "NKTNotebookEditViewController.h"
#import "NKTNotebookViewController.h"
#import "NKTPageViewController.h"

@interface NKTRootViewController()

@property (nonatomic, readwrite, retain) NKTNotebook *selectedNotebook;

@end

@implementation NKTRootViewController

@synthesize selectedNotebook = selectedNotebook_;

@synthesize notebookViewController = notebookViewController_;
@synthesize pageViewController = pageViewController_;
@synthesize notebookEditViewController = notebookEditViewController_;

@synthesize notebookAddToolbarItem = notebookAddToolbarItem_;
@synthesize notebookDeleteIndexPath = notebookDeleteIndexPath_;

@synthesize managedObjectContext = managedObjectContext_;
@synthesize fetchedResultsController = fetchedResultsController_;

static NSString *LastViewedNotebookIdKey = @"LastViewedNotebookId";

#pragma mark -
#pragma mark Memory

- (void)dealloc
{
    [managedObjectContext_ release];
    [fetchedResultsController_ release];
    [selectedNotebook_ release];
    
    [notebookEditViewController_ release];
    [notebookViewController_ release];
    [pageViewController_ release];
    
    [notebookAddToolbarItem_ release];
    [notebookAddActionSheet_ release];
    [notebookDeleteIndexPath_ release];
    [notebookDeleteConfirmationActionSheet_ release];
    [super dealloc];
}

#pragma mark -
#pragma mark View Controller

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = YES;
    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // Notebook add/edit view controller
    notebookEditViewController_ = [[NKTNotebookEditViewController alloc] init];
    notebookEditViewController_.managedObjectContext = managedObjectContext_;
    notebookEditViewController_.delegate = self;
    
    // Custom navigation title
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 20.0)];
    label.text = @"Notebooks";
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = UITextAlignmentCenter;
    label.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0];
    label.textColor = [UIColor whiteColor];
    self.navigationItem.titleView = label;
    [label release];
    
    // Toolbar items
    notebookAddToolbarItem_ = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(notebookAddToolbarItemTapped:)];
    self.toolbarItems = [NSArray arrayWithObjects:notebookAddToolbarItem_, nil];
    
    // Perform fetch
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error])
    {
        KBCLogWarning(@"Failed to perform fetch: %@", [error localizedDescription]);
        KBCLogWarning(@"%@", KBCDetailedCoreDataErrorStringFromError(error));
        abort();
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.notebookEditViewController = nil;
    self.notebookAddToolbarItem = nil;
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
        [[NSUserDefaults standardUserDefaults] setObject:selectedNotebook_.notebookId forKey:LastViewedNotebookIdKey];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self setEditing:NO animated:NO];
    [notebookAddActionSheet_ dismissWithClickedButtonIndex:notebookAddActionSheet_.cancelButtonIndex animated:NO];
    notebookAddActionSheet_ = nil;
    [notebookDeleteConfirmationActionSheet_ dismissWithClickedButtonIndex:notebookDeleteConfirmationActionSheet_.cancelButtonIndex animated:NO];
    notebookDeleteConfirmationActionSheet_ = nil;
    self.notebookDeleteIndexPath = nil;
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
        [self setToolbarItems:[NSArray arrayWithObjects:notebookAddToolbarItem_, nil] animated:YES];
        [pageViewController_ unfreeze];
    }
}

#pragma mark -
#pragma mark Notebooks

- (void)selectInitialNotebook
{
    // Should only be used after the view has been loaded, since the fetch occurs in -viewDidLoad
    if (![self isViewLoaded])
    {
        KBCLogWarning(@"This method must only be called after the view has been loaded. Returning.");
        return;
    }
    
    NSArray *notebooks = [self.fetchedResultsController fetchedObjects];
    if ([notebooks count] == 0)
    {
        KBCLogWarning(@"No notebooks exist. A notebook must exist before this method is called. Returning.");
        return;
    }
    
    // Search for the previously viewed notebook
    NKTNotebook *notebook = nil;
    NSString *notebookId = [[NSUserDefaults standardUserDefaults] objectForKey:LastViewedNotebookIdKey];
    
    if (notebookId != nil)
    {
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
    
    if (notebookToDelete == selectedNotebook_)
    {
        self.selectedNotebook = nil;
        [notebookViewController_ setNotebook:nil restoreLastSelectedPage:NO];
    }
    
    // Reorder the notebooks first
    NSUInteger reorderRangeBegin = indexPath.row + 1;
    NSUInteger reorderRangeEnd = numberOfNotebooks;
    for (NSUInteger index = reorderRangeBegin; index < reorderRangeEnd; ++index)
    {
        NSIndexPath *reorderIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
        NKTNotebook *notebookToReorder = [self.fetchedResultsController objectAtIndexPath:reorderIndexPath];
        notebookToReorder.displayOrder = [NSNumber numberWithInteger:index - 1];
    }
    
    // Delete the notebook
    [managedObjectContext_ deleteObject:notebookToDelete];

    // Create a default notebook if we just deleted the last one
    if (deletingLastNotebook)
    {
        [NKTNotebook insertNotebookInManagedObjectContext:managedObjectContext_];
    }
    
    NSError *error = nil;
    if (![managedObjectContext_ save:&error])
    {
        KBCLogWarning(@"Failed to save to data store: %@", [error localizedDescription]);
        KBCLogWarning(@"%@", KBCDetailedCoreDataErrorStringFromError(error));
        abort();
    }
}

#pragma mark -
#pragma mark Actions

- (void)notebookAddToolbarItemTapped:(UIBarButtonItem *)item
{
    if (notebookAddActionSheet_.visible)
    {
        [notebookAddActionSheet_ dismissWithClickedButtonIndex:notebookAddActionSheet_.cancelButtonIndex animated:YES];
        notebookAddActionSheet_ = nil;
    }
    else
    {
        notebookAddActionSheet_ = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Add Notebook", nil];
        [notebookAddActionSheet_ showFromBarButtonItem:notebookAddToolbarItem_ animated:YES];
        [notebookAddActionSheet_ release];
    }
}

- (void)presentNotebookAddView
{
    [notebookEditViewController_ configureForAddingNotebook];
    [self presentModalViewController:notebookEditViewController_ animated:YES];
}

- (void)presentNotebookEditViewForNotebookAtIndexPath:(NSIndexPath *)indexPath
{
    NKTNotebook *notebook = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [notebookEditViewController_ configureForEditingNotebook:notebook];
    [self presentModalViewController:notebookEditViewController_ animated:YES];
}

- (void)presentNotebookDeleteConfirmationForNotebookAtIndexPath:(NSIndexPath *)indexPath
{
    self.notebookDeleteIndexPath = indexPath;
    notebookDeleteConfirmationActionSheet_ = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete Notebook" otherButtonTitles:nil];
    [notebookDeleteConfirmationActionSheet_ showInView:self.view];
    [notebookDeleteConfirmationActionSheet_ release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet == notebookDeleteConfirmationActionSheet_)
    {
        if (buttonIndex == notebookDeleteConfirmationActionSheet_.destructiveButtonIndex)
        {
            [self deleteNotebookAtIndexPath:notebookDeleteIndexPath_];
        }
        
        self.notebookDeleteIndexPath = nil;
        notebookDeleteConfirmationActionSheet_ = nil;
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // Present the next view after the sheet has been dismissed to prevent some animation
    // artifacts
    if (actionSheet == notebookAddActionSheet_)
    {
        if (buttonIndex == notebookAddActionSheet_.firstOtherButtonIndex)
        {
            [self presentNotebookAddView];
        }
        
        notebookAddActionSheet_ = nil;
    }
}

#pragma mark -
#pragma mark Notebook Edit View Controller Delegate

- (void)notebookEditViewControllerDidCancel:(NKTNotebookEditViewController *)notebookEditViewController
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)notebookEditViewController:(NKTNotebookEditViewController *)notebookEditViewController didAddNotebook:(NKTNotebook *)notebook
{
    // Scroll to added notebook
    NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:notebook];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
    
    // Update notebook view controller
    self.selectedNotebook = notebook;
    [notebookViewController_ setNotebook:notebook restoreLastSelectedPage:NO];
    [self.navigationController pushViewController:notebookViewController_ animated:YES];
    
    // Dismiss the modal without animation and make the text view first responder after a short
    // delay to get around some weird keyboard behavior that occurs if the text view is made first
    // responder immediately
    [pageViewController_ dismissNotebookPopoverAnimated:YES];
    [pageViewController_.textView performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.1];
    [self dismissModalViewControllerAnimated:NO];
}

- (void)notebookEditViewController:(NKTNotebookEditViewController *)notebookEditViewController didEditNotebook:(NKTNotebook *)notebook
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Table View Data Source/Delegate

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
    
    // Update cell text with notebook title
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
    
    // Set flag so we know to ignore fetch results controller updates
    modelChangeIsUserDriven_ = YES;
        
    // Set display order of moved notebook
    NKTNotebook *notebook = [self.fetchedResultsController objectAtIndexPath:fromIndexPath];
    notebook.displayOrder = [NSNumber numberWithUnsignedInteger:toIndex];
    
    // Renumber other notebooks
    NSUInteger reorderRangeStart = 0;
    NSUInteger reorderRangeEnd = 0;
    NSInteger displayOrderAdjustment = 0;
    if (fromIndex < toIndex)
    {
        reorderRangeStart = fromIndex + 1;
        reorderRangeEnd = toIndex + 1;
        displayOrderAdjustment = -1;
    }
    else
    {
        reorderRangeStart = toIndex;
        reorderRangeEnd = fromIndex;
        displayOrderAdjustment = 1;
    }
    
    for (NSUInteger index = reorderRangeStart; index < reorderRangeEnd; ++index)
    {
        NSIndexPath *renumberIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
        NKTNotebook *notebookToReorder = [self.fetchedResultsController objectAtIndexPath:renumberIndexPath];
        NSInteger displayOrder = [notebookToReorder.displayOrder integerValue] + displayOrderAdjustment;
        notebookToReorder.displayOrder = [NSNumber numberWithInteger:displayOrder];
    }
    
    NSError *error = nil;
    if (![managedObjectContext_ save:&error])
    {
        KBCLogWarning(@"Failed to save to data store: %@", [error localizedDescription]);
        KBCLogWarning(@"%@", KBCDetailedCoreDataErrorStringFromError(error));
        abort();
    }
    
    modelChangeIsUserDriven_ = NO;
}

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
    [self presentNotebookEditViewForNotebookAtIndexPath:indexPath];
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
    if (modelChangeIsUserDriven_)
    {
        return;
    }
    
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    KBCLogWarning(@"This method should never be called. Ignoring.");
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    if (modelChangeIsUserDriven_)
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
    if (modelChangeIsUserDriven_)
    {
        return;
    }
    
    [self.tableView endUpdates];
}

@end
