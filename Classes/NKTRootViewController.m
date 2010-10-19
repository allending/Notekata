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

#pragma mark -
#pragma mark Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return  [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
{
    // PENDING: Styling
    NKTNotebook *notebook = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.showsReorderControl = YES;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.editingAccessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    cell.textLabel.text = notebook.title;
    
    NSUInteger numberOfPages = [[notebook pages] count];
    
    // PENDING: LOCALIZATION
    if (numberOfPages > 1)
    {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%d pages", numberOfPages];
    }
    else
    {
        cell.detailTextLabel.text = @"1 page";
    }
}

/*
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}
*/

/*
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        // Delete the row from the data source
        //[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
}
*/

/*
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

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

/*
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    NKTEditNotebookViewController *vc = [[NKTEditNotebookViewController alloc] init];
    vc.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentModalViewController:vc animated:YES];
}
*/

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
    if (!changeIsUserDriven_)
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
    
    UITableView *tableView = self.tableView;
    
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
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
