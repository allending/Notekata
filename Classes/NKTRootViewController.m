//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTRootViewController.h"
#import "NotekataAppDelegate.h"
#import "NKTNotebook.h"
#import "NKTNotebookViewController.h"
#import "NKTPage.h"
#import "NKTPageViewController.h"

// NKTRootViewController private interface
@interface NKTRootViewController()

#pragma mark Managing Notebooks

- (NKTNotebook *)selectedNotebookBeforeViewDisappeared;
- (NSUInteger)numberOfNotebooks;
- (NKTNotebook *)notebookAtIndex:(NSUInteger)index;

#pragma mark Managing the Navigation Item

- (void)initNavigationItem;

#pragma mark Styling The Navigation Bar

- (void)styleNavigationBarAndToolbar;

#pragma mark Table View Data Source

- (void)configureCell:(UITableViewCell *)cell withNotebook:(NKTNotebook *)notebook;

@end

#pragma mark -

@implementation NKTRootViewController

@synthesize managedObjectContext = managedObjectContext_;
@synthesize fetchedResultsController = fetchedResultsController_;

@synthesize notebookViewController = notebookViewController_;
@synthesize pageViewController = pageViewController_;

#pragma mark -
#pragma mark Memory Management

- (void)dealloc
{
    [managedObjectContext_ release];
    [fetchedResultsController_ release];
    
    [notebookViewController_ release];
    [pageViewController_ release];
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
    
    // Create the fetch request for the entity
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Set up the entity
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Notebook"
                                              inManagedObjectContext:managedObjectContext_];
    [fetchRequest setEntity:entity];
    
    // Sort notebooks by name
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"displayOrder" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    // Create the fetched results controller
    fetchedResultsController_ = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                    managedObjectContext:managedObjectContext_
                                                                      sectionNameKeyPath:nil
                                                                               cacheName:@"Root"];
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
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
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
    [self.tableView endUpdates];
}

#pragma mark -
#pragma mark Managing Notebooks

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

#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = YES;
    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    [self initNavigationItem];
    
    // Determine and set the selected notebook
    
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
    KBCLogWarning(@"view unloaded");

    // 
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // There seems to be a bug in UIKit where the navigation controller navigation bar and toolbar may not respect
    // the set styles after rotation animations. As a workaround, we force the style.    
    [self styleNavigationBarAndToolbar];
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
    return YES;
}

#pragma mark -
#pragma mark Managing the Navigation Item

- (void)initNavigationItem
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 20.0)];
    label.text = @"Notekata";
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = UITextAlignmentCenter;
    label.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0];
    label.textColor = [UIColor lightTextColor];
    self.navigationItem.titleView = label;
    [label release];
}

#pragma mark -
#pragma mark Styling The Navigation Bar

- (void)styleNavigationBarAndToolbar
{
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    self.navigationController.toolbar.barStyle = UIBarStyleBlackOpaque;
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
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NKTNotebook *notebook = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self configureCell:cell withNotebook:notebook];
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
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

@end
