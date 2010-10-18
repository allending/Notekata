//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTRootViewController.h"
#import "NotekataAppDelegate.h"
#import "NKTNotebook.h"
#import "NKTNotebookViewController.h"
#import "NKTPage.h"
#import "NKTPageViewController.h"

#import "NKTEditNotebookViewController.h"

// NKTRootViewController private interface
@interface NKTRootViewController()

#pragma mark Accessing Controllers

@property (nonatomic, retain) NKTEditNotebookViewController *editNotebookViewController;

#pragma mark Managing Notebooks

- (NSUInteger)numberOfNotebooks;
- (NKTNotebook *)notebookAtIndex:(NSUInteger)index;
- (NKTNotebook *)selectedNotebookBeforeViewDisappeared;

#pragma mark Table View Data Source

- (void)configureCell:(UITableViewCell *)cell withNotebook:(NKTNotebook *)notebook;

#pragma mark Managing Navigation Items

@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UIBarButtonItem *addNotebookItem;

#pragma mark Responding to User Actions

- (void)addItemTapped:(UIBarButtonItem *)item;
- (void)addNotebook;

@end

#pragma mark -

@implementation NKTRootViewController

@synthesize managedObjectContext = managedObjectContext_;
@synthesize fetchedResultsController = fetchedResultsController_;

@synthesize notebookViewController = notebookViewController_;
@synthesize pageViewController = pageViewController_;
@synthesize editNotebookViewController = editNotebookViewController_;

@synthesize titleLabel = titleLabel_;
@synthesize addNotebookItem = addItem_;

static const NSUInteger AddNotebookButtonIndex = 0;
static const NSUInteger AddPageButtonIndex = 1;

#pragma mark -
#pragma mark Memory Management

- (void)dealloc
{
    [managedObjectContext_ release];
    [fetchedResultsController_ release];
    [editNotebookViewController_ release];
    
    [notebookViewController_ release];
    [pageViewController_ release];
    
    [titleLabel_ release];
    [addItem_ release];
    [addActionSheet_ release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Core Data Stack

// Fetched result controller for all notebooks sorted by display order.
- (NSFetchedResultsController *)fetchedResultsController
{    
    if (fetchedResultsController_ != nil)
    {
        return fetchedResultsController_;
    }
    
    // Create request for all notebooks sorted by display order
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Notebook"
                                              inManagedObjectContext:managedObjectContext_];
    [fetchRequest setEntity:entity];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"displayOrder" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    // Create the controller and fetch the data
    fetchedResultsController_ = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                    managedObjectContext:managedObjectContext_
                                                                      sectionNameKeyPath:nil
                                                                               cacheName:nil];
    fetchedResultsController_.delegate = self;
    
    NSError *error = nil;
    if (![fetchedResultsController_ performFetch:&error])
    {
        // TODO: FIX and LOG
        KBCLogWarning(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
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

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    KBCLogWarning(@"this should never be called");
    
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    if (changeIsUserDriven_)
    {
        return;
    }
    
    UITableView *tableView = self.tableView;
    
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] withNotebook:anObject];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
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

#pragma mark -
#pragma mark Managing Notebooks

- (NSUInteger)numberOfNotebooks
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:0];
    return [sectionInfo numberOfObjects];
}

- (NKTNotebook *)notebookAtIndex:(NSUInteger)index
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    return [self.fetchedResultsController objectAtIndexPath:indexPath];
}

- (NKTNotebook *)selectedNotebookBeforeViewDisappeared
{
    NSNumber *lastNotebookId = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastSelectedNotebookId"];
    
    if (lastNotebookId == nil)
    {
        return nil;
    }
    
    NSUInteger numberOfNotebooks = [self numberOfNotebooks];
    
    for (NSUInteger index = 0; index < numberOfNotebooks; ++index)
    {
        NKTNotebook *notebook = [self notebookAtIndex:index];
        
        if ([lastNotebookId isEqualToNumber:notebook.notebookId ])
        {
            return notebook;
        }
    }
    
    return nil;
}

#pragma mark -
#pragma mark Responding to Edit Notebook View Controller Events

- (void)editNotebookViewController:(NKTEditNotebookViewController *)editNotebookViewController
                    didAddNotebook:(NKTNotebook *)notebook
{
    // The notebook will already have shown up in the table view because of fetch result controller updates
    NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:notebook];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    

    // TODO: design refactor
    // Principle: A VC only sets the text view contents in response to a user action, with the exception of the app
    // delegate in the beginnning!
    // Should control text view ourselves!
    // Change: text view only becomes first responder explicitly, and the page is set either by the
    // root or notebook vc
    
    // TODO set this does nothing
    notebookViewController_.notebook = notebook;
    [self.navigationController pushViewController:notebookViewController_ animated:YES];
    // when nvc appears, it does the good stuff
    
    [pageViewController_ dismissNavigationPopoverAnimated:YES];
    [pageViewController_.textView becomeFirstResponder];
}

#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = YES;
    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    
    // Initialize the view controller used for adding/editing notebooks
    editNotebookViewController_ = [[NKTEditNotebookViewController alloc] init];
    editNotebookViewController_.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    editNotebookViewController_.managedObjectContext = managedObjectContext_;
    editNotebookViewController_.delegate = self;
    
    // Initialize custom navigation item title label
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 20.0)];
    label.text = @"Notekata";
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = UITextAlignmentCenter;
    label.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0];
    label.textColor = [UIColor lightTextColor];
    self.navigationItem.titleView = label;
    [label release];
    
    // Expose an edit button
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // Place an add button on the toolbar
    addItem_ = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                     target:self
                                                                     action:@selector(addItemTapped:)];
    self.toolbarItems = [NSArray arrayWithObjects:addItem_, nil];
    
    // Determine and set the selected notebook
    // TODO: this is in viewDidLoad because ....?
    NKTNotebook *notebook = [self selectedNotebookBeforeViewDisappeared];
    
    if (notebook == nil && [self numberOfNotebooks] != 0)
    {
        notebook = [self notebookAtIndex:0];
    }
    
    if (notebook != nil)
    {
        notebookViewController_.notebook = notebook;
        
        if (self.notebookViewController.navigationController == nil)
        {
            [self.navigationController pushViewController:self.notebookViewController animated:NO];
        }
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.editNotebookViewController = nil;
    self.titleLabel = nil;
    self.addNotebookItem = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // There seems to be a bug in UIKit where the navigation controller navigation bar and toolbar may not respect
    // the set styles after rotation animations. As a workaround, we force the style.    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    self.navigationController.toolbar.barStyle = UIBarStyleBlackOpaque;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // TODO: store last selected notebook
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

#pragma mark -
#pragma mark Handling Rotations

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Because of the split view controllers removing modal views during rotation, we disallow rotation if the modal
    // view controller is active
    /*
    if (self.modalViewController == editNotebookViewController_ && interfaceOrientation != self.interfaceOrientation)
    {
        return NO;
    }
    */
    
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    // Stop editing when rotation occurs so the page view controller is always unfrozen after rotation
    [self setEditing:NO animated:NO];
    // Dismiss any action sheets
    [addActionSheet_ dismissWithClickedButtonIndex:-1 animated:NO];
    [self dismissModalViewControllerAnimated:NO];
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

- (void)configureCell:(UITableViewCell *)cell withNotebook:(NKTNotebook *)notebook
{
    // Style Mockup
    cell.imageView.image = [UIImage imageNamed:@"DocumentIcon.png"];
    cell.textLabel.text = notebook.title;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d pages", [[notebook pages] count]];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.editingAccessoryType = UITableViewCellAccessoryDetailDisclosureButton;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                       reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NKTNotebook *notebook = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self configureCell:cell withNotebook:notebook];
    return cell;
}

/*
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}
*/

/*
- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        // Delete the row from the data source
        //[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
}
*/

/*
- (void)tableView:(UITableView *)tableView
moveRowAtIndexPath:(NSIndexPath *)fromIndexPath
      toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}
 */

#pragma mark -
#pragma mark Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    notebookViewController_.notebook = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self.navigationController pushViewController:notebookViewController_ animated:YES];
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
#pragma mark Configuring Edit State

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    if (editing)
    {
        // TODO: find Core Animation bug workaround
        [self.navigationItem setHidesBackButton:YES animated:NO];
        [self setToolbarItems:nil animated:YES];
        [pageViewController_.textView resignFirstResponder];
        [pageViewController_ freezeUserInteraction];
    }
    else
    {
        // TODO: find Core Animation bug workaround
        [self.navigationItem setHidesBackButton:NO animated:NO];
        [self setToolbarItems:[NSArray arrayWithObjects:addItem_, nil] animated:YES];
        [pageViewController_ unfreezeUserInteraction];
    }
}


#pragma mark -
#pragma mark Responding to User Actions

- (void)addItemTapped:(UIBarButtonItem *)item
{
    if (!addActionSheet_.visible)
    {
        [addActionSheet_ release];
        addActionSheet_ = [[UIActionSheet alloc] initWithTitle:nil
                                                      delegate:self
                                             cancelButtonTitle:@"Cancel"
                                        destructiveButtonTitle:nil
                                             otherButtonTitles:@"Add Notebook",
                                                               @"Add Page",
                                                               nil];
        [addActionSheet_ showFromBarButtonItem:item animated:YES];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex)
    {
        case AddNotebookButtonIndex:
            [self addNotebook];
            break;
    
        default:
            break;
    }
    
    [addActionSheet_ autorelease];
    addActionSheet_ = nil;
}

- (void)addNotebook
{
    [editNotebookViewController_ configureToAddNotebook];
    [self presentModalViewController:editNotebookViewController_ animated:YES];
}

@end
