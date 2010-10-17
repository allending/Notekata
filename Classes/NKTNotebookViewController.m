//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTNotebookViewController.h"
#import "NKTNotebook.h"
#import "NKTPage.h"

// NKTNotebookViewController private interface
@interface NKTNotebookViewController()

#pragma mark Accessing the Selected Page

@property (nonatomic, retain) NKTPage *selectedPage;

#pragma mark Core Data Stack

@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;

#pragma mark Managing Pages

- (NSUInteger)numberOfPages;
- (NKTPage *)pageAtIndex:(NSUInteger)index;
- (NKTPage *)selectedPageBeforeViewDisappeared;

#pragma mark Responding to Page View Controller Events

- (void)pageViewController:(NKTPageViewController *)pageViewController textViewDidChange:(NKTTextView *)textView;

#pragma mark Managing Navigation Controller Items

@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UIBarButtonItem *addPageItem;

#pragma mark Table View Data Source

- (void)configureCell:(UITableViewCell *)cell withString:(NSString *)string;

@end

#pragma mark -

@implementation NKTNotebookViewController

@synthesize fetchedResultsController = fetchedResultsController_;
@synthesize notebook = notebook_;
@synthesize selectedPage = selectedPage_;

@synthesize pageViewController = pageViewController_;

@synthesize titleLabel = titleLabel_;
@synthesize addPageItem = addPageItem_;

#pragma mark -
#pragma mark Memory Management

- (void)dealloc
{
    [fetchedResultsController_ release];
    [notebook_ release];
    [selectedPage_ release];
    
    [pageViewController_ release];
    
    [titleLabel_ release];
    [addPageItem_ release];
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
    
    // Create request for pages belonging to notebook sorted by pageNumber
    NSManagedObjectContext *managedObjectContext = notebook_.managedObjectContext;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Page"
                                              inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"notebook = %@", notebook_];
    [fetchRequest setPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"pageNumber" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    // Create the controller and fetch the data
    fetchedResultsController_ = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                    managedObjectContext:managedObjectContext
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
        [self.tableView beginUpdates];
    }
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
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
            [self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] withString:page.textString];
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
    if (!changeIsUserDriven_)
    {
        [self.tableView endUpdates];
    }
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
    
    // Find a page to treat as the selected page
    NKTPage *pageToSelect = [self selectedPageBeforeViewDisappeared];
    if (pageToSelect == nil)
    {
        pageToSelect = [self pageAtIndex:0];
    }
    
    // 
    self.selectedPage = pageToSelect;
    // TODO: is this right?
    [pageViewController_ setPage:pageToSelect saveEditedText:YES];
    titleLabel_.text = notebook_.title;
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark Managing Pages

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

- (NKTPage *)selectedPageBeforeViewDisappeared
{
    NSDictionary *lastSelectedPages = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastSelectedPages"];
    return [lastSelectedPages objectForKey:notebook_.notebookId];
}

- (void)addPage
{
    if (notebook_ == nil)
    {
        KBCLogWarning(@"notebook is nil, returning");
        return;
    }
    
    // Create a new page and add it to the notebook
    NKTPage *createdPage = [NSEntityDescription insertNewObjectForEntityForName:@"Page"
                                                         inManagedObjectContext:notebook_.managedObjectContext];
    createdPage.pageNumber = [NSNumber numberWithUnsignedInteger:[[notebook_ pages] count]];
    createdPage.textString = @"";
    createdPage.textStyleString = @"";
    [notebook_ addPagesObject:createdPage];
    
    NSError *error = nil;
    if (![notebook_.managedObjectContext save:&error])
    {
        // TODO: FIX, LOG
        KBCLogWarning(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    // Use newly created page the active page being edited
    self.selectedPage = createdPage;
    NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:createdPage];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    [pageViewController_ setPage:createdPage saveEditedText:YES];
    // Start editing page immediately
    [pageViewController_.textView becomeFirstResponder];
}

#pragma mark -
#pragma mark Responding to Page View Controller Events

- (void)pageViewController:(NKTPageViewController *)pageViewController textViewDidChange:(NKTTextView *)textView
{
    NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:selectedPage_];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    // TODO: can optimize if text position is given
    // Update cell with the contents of the text view as it changes
    [self configureCell:cell withString:[textView.text string]];
}

#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = NO;
    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    
    // UI elements need to be updated when changes occur in the page view controller
    pageViewController_.delegate = self;
    
    // Initialize custom navigation item title label
    titleLabel_ = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 20.0)];
    titleLabel_.backgroundColor = [UIColor clearColor];
    titleLabel_.textAlignment = UITextAlignmentCenter;
    titleLabel_.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0];
    titleLabel_.textColor = [UIColor lightTextColor];
    titleLabel_.text = notebook_.title;
    self.navigationItem.titleView = titleLabel_;
    
    // Expose an edit button on the navigation item
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // Place an add button on the toolbar
    addPageItem_ = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                        target:self
                                                                        action:@selector(addPage)];
    self.toolbarItems = [NSArray arrayWithObjects:addPageItem_, nil];
}

- (void)viewDidUnload
{
    self.titleLabel = nil;
    self.addPageItem = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // There seems to be a bug in UIKit where the navigation controller navigation bar and toolbar may not respect
    // the set styles after rotation animations. As a workaround, we force the style.    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    self.navigationController.toolbar.barStyle = UIBarStyleBlackOpaque;
    
    // Select and scroll to the selected page
    [self.tableView reloadData];
    NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:selectedPage_];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
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

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    // Stop editing when rotation occurs so the page view controller is always unfrozen after rotation
    [self setEditing:NO animated:NO];
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

- (void)configureCell:(UITableViewCell *)cell withString:(NSString *)string
{
    NSString *snippet = KUITrimmedSnippetFromString(string, 50);
    
    if ([snippet length] == 0)
    {
        // TODO: localization
        cell.textLabel.text = @"Untitled";
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
        // No fancy styling, just a simple cell with text
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:CellIdentifier] autorelease];
        cell.showsReorderControl = YES;
    }
    
    NKTPage *page = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self configureCell:cell withString:page.textString];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle != UITableViewCellEditingStyleDelete)
    {
        KBCLogWarning(@"unexpected editing style commit, returning");
        return;
    }
    
    NKTPage *pageToDelete = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // Renumber the pages first
    NSUInteger updateRangeStart = indexPath.row + 1;
    NSUInteger updateRangeEnd = [self numberOfPages];
    for (NSUInteger updateIndex = updateRangeStart; updateIndex < updateRangeEnd; ++updateIndex)
    {
        NSIndexPath *updateIndexPath = [NSIndexPath indexPathForRow:updateIndex inSection:0];
        NKTPage *pageToUpdate = [self.fetchedResultsController objectAtIndexPath:updateIndexPath];
        //  Adjust offsets of pages following the deleted page by -1
        pageToUpdate.pageNumber = [NSNumber numberWithInteger:updateIndex - 1];
    }
    
    // Delete the page
    [notebook_ removePagesObject:pageToDelete];
    [notebook_.managedObjectContext deleteObject:pageToDelete];

    // Add a page if the deleted page was the last one
    if ([[notebook_ pages] count] == 0)
    {
        NKTPage *newFirstPage = [NSEntityDescription insertNewObjectForEntityForName:@"Page"
                                                              inManagedObjectContext:notebook_.managedObjectContext];
        newFirstPage.pageNumber = [NSNumber numberWithInteger:0];
        newFirstPage.textString = @"";
        newFirstPage.textStyleString = @"";
        [notebook_ addPagesObject:newFirstPage];
    }

    NSError *error = nil;
    if (![notebook_.managedObjectContext save:&error])
    {
        // TODO: FIX, LOG
        KBCLogWarning(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    // Select new page if the deleted page was the selected page
    if (self.selectedPage == pageToDelete)
    {
        NKTPage *pageToSelect = nil;

        // Page at the index path is the one we want to select
        if (indexPath.row < [[notebook_ pages] count])
        {
            pageToSelect = [self.fetchedResultsController objectAtIndexPath:indexPath];
        }
        // Use the last page in the notebook as the new selected page
        else
        {
            NSIndexPath *selectionIndexPath = [NSIndexPath indexPathForRow:[[notebook_ pages] count] - 1 inSection:0];
            pageToSelect = [self.fetchedResultsController objectAtIndexPath:selectionIndexPath];
        }
        
        self.selectedPage = pageToSelect;
        [pageViewController_ setPage:pageToSelect saveEditedText:NO];
    }
}

- (void)tableView:(UITableView *)tableView
moveRowAtIndexPath:(NSIndexPath *)fromIndexPath
      toIndexPath:(NSIndexPath *)toIndexPath
{
    NSUInteger fromIndex = fromIndexPath.row;
    NSUInteger toIndex = toIndexPath.row;
    
    if (fromIndex == toIndex)
    {
        return;
    }
    
    // Set flag so we know to ignore changes from fetch controller since the changes are coming from the UI
    changeIsUserDriven_ = YES;
    
    // Set page number of moved page
    NKTPage *movedPage = [self.fetchedResultsController objectAtIndexPath:fromIndexPath];
    movedPage.pageNumber = [NSNumber numberWithUnsignedInteger:toIndex];
    
    // Renumber rest of the pages
    NSUInteger updateRangeStart = 0;
    NSUInteger updateRangeEnd = 0;
    NSInteger pageNumberAdjustment = 0;

    if (fromIndex < toIndex)
    {
        updateRangeStart = fromIndex + 1;
        updateRangeEnd = toIndex;
        pageNumberAdjustment = -1;
    }
    else
    {
        updateRangeStart = toIndex;
        updateRangeEnd = fromIndex - 1;
        pageNumberAdjustment = 1;
    }
    
    for (NSUInteger updateIndex = updateRangeStart; updateIndex <= updateRangeEnd; ++updateIndex)
    {
        NSIndexPath *updateIndexPath = [NSIndexPath indexPathForRow:updateIndex inSection:0];
        NKTPage *pageToUpdate = [self.fetchedResultsController objectAtIndexPath:updateIndexPath];
        NSUInteger existingPageNumber = [pageToUpdate.pageNumber unsignedIntegerValue];
        pageToUpdate.pageNumber = [NSNumber numberWithUnsignedInteger:existingPageNumber + pageNumberAdjustment];
    }
    
    NSError *error = nil;
    if (![notebook_.managedObjectContext save:&error])
    {
        // TODO: FIX, LOG
        KBCLogWarning(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    changeIsUserDriven_ = NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

#pragma mark -
#pragma mark Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [pageViewController_.textView resignFirstResponder];
    NKTPage *pageToSelect = [self.fetchedResultsController objectAtIndexPath:indexPath];
    self.selectedPage = pageToSelect;
    [pageViewController_ setPage:pageToSelect saveEditedText:YES];
}

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
        [self setToolbarItems:[NSArray arrayWithObjects:addPageItem_, nil] animated:YES];
        // The table view selection state may be dirty following edits, so reselect the selected page cell
        NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:selectedPage_];
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        [pageViewController_ unfreezeUserInteraction];
    }
}

@end
