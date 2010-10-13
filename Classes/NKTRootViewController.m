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

#pragma mark Table View Data Source

- (void)configureCell:(UITableViewCell *)cell withNotebook:(NKTNotebook *)notebook;

@end

#pragma mark -

@implementation NKTRootViewController

@synthesize managedObjectContext = managedObjectContext_;
@synthesize fetchedResultsController = fetchedResultsController_;
@synthesize selectedNotebook = selectedNotebook_;

@synthesize notebookViewController = notebookViewController_;
@synthesize pageViewController = pageViewController_;

#pragma mark -
#pragma mark Monitoring the Application

- (void)createDefaultNotebookIfNeeded
{
    // Want to make sure that a notebook always exists
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Notebook"
                                              inManagedObjectContext:managedObjectContext_];
    [fetchRequest setEntity:entity];
    NSError *error = nil;
    NSArray *notebooks = [managedObjectContext_ executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    
    if (error != nil)
    {
        KBCLogWarning(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    // Create notebook if one does not exist
    if ([notebooks count] == 0)
    {
        NKTNotebook *notebook = [NSEntityDescription insertNewObjectForEntityForName:[entity name]
                                                              inManagedObjectContext:managedObjectContext_];
        notebook.title = @"My Notebook";
        notebook.notebookId = [NSNumber numberWithInteger:0];
        NKTPage *page = [NSEntityDescription insertNewObjectForEntityForName:@"Page"
                                                      inManagedObjectContext:managedObjectContext_];
        page.text = [[NSAttributedString alloc] initWithString:@""];
        [notebook addPagesObject:page];
        
        NSError *error = nil;
        
        if (![managedObjectContext_ save:&error])
        {
            KBCLogWarning(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (NSArray *)sortedPagesForNotebook:(NKTNotebook *)notebook
{
    NSSortDescriptor *pagesSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"pageNumber" ascending:YES] autorelease];
    return [[notebook.pages allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:pagesSortDescriptor]];
}

- (NSArray *)sortedNotebooks
{
    NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Notebook"
                                              inManagedObjectContext:managedObjectContext_];
    [fetchRequest setEntity:entity];
    NSError *error = nil;
    NSArray *notebooks = [managedObjectContext_ executeFetchRequest:fetchRequest error:&error];
    
    if (error != nil)
    {
        KBCLogWarning(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    NSSortDescriptor *notebookSortDescriptor = [[[NSSortDescriptor alloc]initWithKey:@"displayOrder" ascending:NO] autorelease];
    return [notebooks sortedArrayUsingDescriptors:[NSArray arrayWithObject:notebookSortDescriptor]];
}

- (NKTPage *)pageWithPageId:(NSNumber *)pageId
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Page"
                                              inManagedObjectContext:managedObjectContext_];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pageId = %@", pageId];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *pages = [managedObjectContext_ executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    
    if (error != nil)
    {
        KBCLogWarning(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    // assert that there is only 1 result
    return [pages objectAtIndex:0];
}

- (NKTPage *)initialPage
{
    NKTPage *page = nil;
    NSNumber *lastPageId = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastPageId"];
    
    // If there is no stored initial page id, just get the first page of the first notebook
    if (lastPageId != nil)
    {
        // Get the page with id
        page = [self pageWithPageId:lastPageId];
    }

    if (page == nil)
    {
        NKTNotebook *firstNotebook = [[self sortedNotebooks] objectAtIndex:0];
        page = [[self sortedPagesForNotebook:firstNotebook] objectAtIndex:0];
    }

    return page;
}

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    [self createDefaultNotebookIfNeeded];
    NKTPage *initialPage = [self initialPage];    
    // Set up initial states for view controllers
    selectedNotebook_ = initialPage.notebook;
    
    // TODO: or maybe this causes the notebook view to tell the page view to do its thing?
    notebookViewController_.notebook = selectedNotebook_;
    
    // TODO: move this to the page view controller itself?
    // it is gonna have to do this anyway?
    //
    // when page view finishes, it should inform its delegate that it is about to dissapear
    // maybe having the notebookvc do it makes sense
    //
    // when the notebookvc sets the selected page on the text view, it also stores last viewed page for the particular
    // notebook?
    //
    // when the root view contoller is done ..
    //
    // ok think about this more
    pageViewController_.page = initialPage;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

#pragma mark -
#pragma mark Initializing

- (void)awakeFromNib
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
#pragma mark Memory Management

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)dealloc
{
    [notebookViewController_ release];
    [pageViewController_ release];
    [fetchedResultsController_ release];
    [managedObjectContext_ release];
    [super dealloc];
}


#pragma mark -
#pragma mark Fetched Results Controller

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
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    // Create the fetched results controller
    fetchedResultsController_ = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                    managedObjectContext:managedObjectContext_
                                                                      sectionNameKeyPath:nil
                                                                               cacheName:@"Root"];
    fetchedResultsController_.delegate = self;
    [fetchRequest release];
    [sortDescriptor release];
    return fetchedResultsController_;
}

#pragma mark -
#pragma mark Fetched Results Controller Delegate

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
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
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
#pragma mark Adding Notebooks

- (void)insertNotebook
{
    NSIndexPath *currentSelection = [self.tableView indexPathForSelectedRow];
    
    if (currentSelection != nil)
    {
        [self.tableView deselectRowAtIndexPath:currentSelection animated:NO];
    }
    
    // Create a new instance of the entity managed by the fetched results controller.
    NSManagedObjectContext *context = [fetchedResultsController_ managedObjectContext];
    NSEntityDescription *entity = [[fetchedResultsController_ fetchRequest] entity];
    NKTNotebook *notebook = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
    
    // If appropriate, configure the new managed object.
    notebook.title = @"My Notebook";
    
    // Add a single empty page
    NKTPage *page = [NSEntityDescription insertNewObjectForEntityForName:@"Page" inManagedObjectContext:context];
    page.text = @"";
    [notebook addPagesObject:page];
    
    // Save the context.
    NSError *error = nil;
    
    if (![context save:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate.
         
         You should not use this function in a shipping application, although it may be useful
         during development. If it is not possible to recover from the error, display an alert
         panel that instructs the user to quit the application by pressing the Home button.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    //    NSIndexPath *insertionPath = [fetchedResultsController_ indexPathForObject:notebook];
    //    [self.tableView selectRowAtIndexPath:insertionPath animated:YES scrollPosition:UITableViewScrollPositionTop];
    //    textViewController_.detailItem = newManagedObject;
}

#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = YES;
    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    
//    UIView *backgroundView = [[UIView alloc] init];
//    backgroundView.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
//    self.tableView.separatorColor = [UIColor darkTextColor];
//    self.tableView.backgroundView = backgroundView;
//    [backgroundView release];
//    self.tableView.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
    
    // Set toolbar items so they show up in navigation controller
    UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                             target:nil
                                                                             action:nil];
    self.toolbarItems = [NSArray arrayWithObject:addItem];
    [addItem release];
    
    NSError *error = nil;
    
    if (![self.fetchedResultsController performFetch:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         */
        KBCLogWarning(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    // Restore view to previous state
    [self.navigationController pushViewController:self.notebookViewController animated:NO];
}

- (void)viewDidUnload
{
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // HACK: bug in UIKit?
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
    cell.detailTextLabel.text = @"12 pages, modified 3 days ago";
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
    self.notebookViewController.notebook = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self.navigationController pushViewController:self.notebookViewController animated:YES];
}

@end
