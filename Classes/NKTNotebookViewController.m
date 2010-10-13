//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTNotebookViewController.h"
#import "NKTNotebook.h"
#import "NKTPage.h"

// NKTNotebookViewController private interface
@interface NKTNotebookViewController()

#pragma mark Setting the Title

@property (nonatomic, retain) UILabel *titleLabel;

#pragma mark Core Data Stack

@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;

#pragma mark Managing Pages

- (NKTPage *)selectedPageBeforeViewDisappeared;
- (NSUInteger)numberOfPages;
- (NKTPage *)pageAtIndex:(NSUInteger)index;

#pragma mark Responding to Page View Controller Events

- (void)pageViewController:(NKTPageViewController *)pageViewController textViewDidChange:(NKTTextView *)textView;

#pragma mark Styling The Navigation Bar

- (void)styleNavigationBarAndToolbar;

#pragma mark Managing the Title

- (void)initTitleLabel;
- (void)updateTitleLabel;

#pragma mark Table View Data Source

- (void)configureCell:(UITableViewCell *)cell withText:(NSAttributedString *)text;

@end

#pragma mark -

@implementation NKTNotebookViewController

@synthesize notebook = notebook_;
@synthesize pageViewController = pageViewController_;
@synthesize fetchedResultsController = fetchedResultsController_;

@synthesize titleLabel = titleLabel_;

#pragma mark -
#pragma mark Initializing

- (void)awakeFromNib
{
    pageViewController_.delegate = self;
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc
{
    [notebook_ release];
    [fetchedResultsController_ release];
    
    [pageViewController_ release];
    
    [titleLabel_ release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Core Data Stack

// Fetched result controller for all pages for the current notebook sorted by page number.
- (NSFetchedResultsController *)fetchedResultsController
{
    if (notebook_ == nil)
    {
        KBCLogWarning(@"notebook property is nil, returning nil");
        return nil;
    }
    
    if (fetchedResultsController_ != nil)
    {
        return fetchedResultsController_;
    }
    
    NSManagedObjectContext *managedObjectContext = notebook_.managedObjectContext;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Page"
                                              inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"notebook = %@", notebook_];
    [fetchRequest setPredicate:predicate];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"pageNumber" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    // Create the fetched results controller
    fetchedResultsController_ = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                    managedObjectContext:managedObjectContext
                                                                      sectionNameKeyPath:nil
                                                                               cacheName:@"Notebooks"];
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
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
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
    NKTPage *page = anObject;
    
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] withText:page.text];
            break;
            
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

#pragma mark -
#pragma mark Accessing the Notebook

- (void)setNotebook:(NKTNotebook *)notebook
{
    if (notebook_ == notebook)
    {
        return;
    }
    
    [notebook_ release];
    notebook_ = [notebook retain];
    // Invalidate previously fetched results 
    self.fetchedResultsController = nil;
    
    NKTPage *page = [self selectedPageBeforeViewDisappeared];
    
    if (page == nil)
    {
        page = [self pageAtIndex:0];
    }
    
    // TODO: improve clarity?
    self.pageViewController.page = page;
    [self updateTitleLabel];
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark Managing Pages

- (NKTPage *)selectedPageBeforeViewDisappeared
{
    NSDictionary *lastSelectedPages = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastSelectedPages"];
    return [lastSelectedPages objectForKey:notebook_.notebookId];
}

- (NSUInteger)numberOfPages
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:0];
    return [sectionInfo numberOfObjects];
}

- (NKTPage *)pageAtIndex:(NSUInteger)index
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    return [self.fetchedResultsController objectAtIndexPath:indexPath];
}

#pragma mark -
#pragma mark Responding to Page View Controller Events

// TODO: optimize - be lazy
- (void)pageViewController:(NKTPageViewController *)pageViewController textViewDidChange:(NKTTextView *)textView
{
    // TODO: this should just use the selectedPage_?
    NSIndexPath *indexPath = [fetchedResultsController_ indexPathForObject:pageViewController.page];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    // TODO: refactor
    // Update cell with the live contents of the text view
    [self configureCell:cell withText:textView.text];
}

#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = NO;
    [self initTitleLabel];    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    self.titleLabel = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // There seems to be a bug in UIKit where the navigation controller navigation bar and toolbar may not respect
    // the set styles after rotation animations. As a workaround, we force the style.    
    [self styleNavigationBarAndToolbar];
    [self updateTitleLabel];
    // TODO: select and scroll selected page?
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // TODO: store last selected page
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
#pragma mark Styling The Navigation Bar

- (void)styleNavigationBarAndToolbar
{
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    self.navigationController.toolbar.barStyle = UIBarStyleBlackOpaque;
}

#pragma mark -
#pragma mark Managing the Title

- (void)initTitleLabel
{
    // Create and set the custom navigation title view
    titleLabel_ = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 20.0)];
    titleLabel_.backgroundColor = [UIColor clearColor];
    titleLabel_.textAlignment = UITextAlignmentCenter;
    titleLabel_.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0];
    titleLabel_.textColor = [UIColor lightTextColor];
    self.navigationItem.titleView = titleLabel_;
}

- (void)updateTitleLabel
{
    titleLabel_.text = notebook_.title;
}

#pragma mark -
#pragma mark Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (void)configureCell:(UITableViewCell *)cell withText:(NSAttributedString *)text
{
    NSString *snippet = KUITrimmedSnippetFromString([text string], 50);
    
    if ([snippet length] == 0)
    {
        cell.textLabel.text = @"Untitled Page";
    }
    else
    {
        cell.textLabel.text = snippet;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NKTPage *page = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self configureCell:cell withText:page.text];
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
}

@end
