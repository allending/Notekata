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

#pragma mark Managing Toolbar Items

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
#pragma mark Initializing

- (void)awakeFromNib
{
    pageViewController_.delegate = self;
}

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
    
    NKTPage *page = [self selectedPageBeforeViewDisappeared];
    
    if (page == nil)
    {
        page = [self pageAtIndex:0];
    }
    
    // TODO: improve clarity?
    self.selectedPage = page;
    self.pageViewController.page = page;
    [self updateTitleLabel];
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark Managing Pages

- (void)addPage
{
    if (notebook_ == nil)
    {
        KBCLogWarning(@"notebook is nil, returning");
        return;
    }
    
    [pageViewController_.textView resignFirstResponder];
    
    NSManagedObjectContext *managedObjectContext = notebook_.managedObjectContext;
    NKTPage *page = [NSEntityDescription insertNewObjectForEntityForName:@"Page"
                                                  inManagedObjectContext:managedObjectContext];
    page.pageNumber = [NSNumber numberWithInteger:[[notebook_ pages] count]];
    page.textString = @"";
    page.textStyleString = @"";
    [notebook_ addPagesObject:page];
    
    NSError *error = nil;
    
    if (![managedObjectContext save:&error])
    {
        // TODO: FIX, LOG
        KBCLogWarning(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    self.selectedPage = page;
    NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:page];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    
    pageViewController_.page = page;
    [pageViewController_.textView becomeFirstResponder];
}

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
    NSIndexPath *indexPath = [fetchedResultsController_ indexPathForObject:selectedPage_];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    // TODO: refactor
    // Update cell with the live contents of the text view
    [self configureCell:cell withString:[textView.text string]];
}

#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = NO;
    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    
    [self initTitleLabel];
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
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
    [self styleNavigationBarAndToolbar];
    [self updateTitleLabel];
    
    // TODO: select and scroll selected page?
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
    [self setEditing:NO animated:NO];
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

- (void)configureCell:(UITableViewCell *)cell withString:(NSString *)string
{
    NSString *snippet = KUITrimmedSnippetFromString(string, 50);
    
    if ([snippet length] == 0)
    {
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
     if (editingStyle == UITableViewCellEditingStyleDelete)
     {
         NSManagedObjectContext *managedObjectContext = [self.fetchedResultsController managedObjectContext];
         
         NKTPage *deletedPage = [self.fetchedResultsController objectAtIndexPath:indexPath];
         NSUInteger deletedPageNumber = [deletedPage.pageNumber integerValue];
         NKTNotebook *notebook = deletedPage.notebook;
         
         // Renumber the pages first
         for (NSUInteger currentPageNumber = deletedPageNumber + 1;
              currentPageNumber < [[notebook pages] count];
              ++currentPageNumber)
         {
             NSIndexPath *currentIndexPath = [NSIndexPath indexPathForRow:currentPageNumber inSection:0];
             NKTPage *currentPage = [self.fetchedResultsController objectAtIndexPath:currentIndexPath];
             currentPage.pageNumber = [NSNumber numberWithInteger:currentPageNumber - 1];
         }
         
         // Delete the page
         [notebook removePagesObject:deletedPage];
         [managedObjectContext deleteObject:deletedPage];
         
         // Add a page if the deleted page was the last one
         if ([[notebook pages] count] == 0)
         {
             NKTPage *page = [NSEntityDescription insertNewObjectForEntityForName:@"Page"
                                                           inManagedObjectContext:managedObjectContext];
             page.pageNumber = [NSNumber numberWithInteger:0];
             page.textString = @"";
             page.textStyleString = @"";
             [notebook addPagesObject:page];
         }
         
         NSError *error = nil;
         
         if (![managedObjectContext save:&error])
         {
             // TODO: FIX, LOG
             KBCLogWarning(@"Unresolved error %@, %@", error, [error userInfo]);
             abort();
         }
         
         // Select new page if needed
         if (self.selectedPage == deletedPage)
         {
             if (deletedPageNumber < [[notebook pages] count])
             {
                 // Page at the index path is the one we want to select
                 NKTPage *page = [self.fetchedResultsController objectAtIndexPath:indexPath];
                 self.selectedPage = page;
                 // TODO: If saveEditedText is YES, this will crash!
                 [pageViewController_ setPage:page saveEditedText:NO];
             }
             else
             {
                 // Use the last page in the notebook as the new selected page
                 NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:[[notebook pages] count] - 1 inSection:0];
                 NKTPage *page = [self.fetchedResultsController objectAtIndexPath:newIndexPath];
                 self.selectedPage = page;
                 // TODO: If saveEditedText is YES, this will crash!
                 [pageViewController_ setPage:page saveEditedText:NO];
             }
         }
     }
     else if (editingStyle == UITableViewCellEditingStyleInsert)
     {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
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
    
    changeIsUserDriven_ = YES;
    
    // Get sorted pages in notebook
    NKTPage *movedPage = [self.fetchedResultsController objectAtIndexPath:fromIndexPath];
    movedPage.pageNumber = [NSNumber numberWithUnsignedInteger:toIndex];
    
    // Renumber pages
    NSUInteger updateRangeStart = 0;
    NSUInteger updateRangeEnd = 0;
    NSInteger indexAdjustment = 0;
    
    if (fromIndex < toIndex)
    {
        updateRangeStart = fromIndex + 1;
        updateRangeEnd = toIndex;
        indexAdjustment = -1;
    }
    else
    {
        updateRangeStart = toIndex;
        updateRangeEnd = fromIndex - 1;
        indexAdjustment = 1;
    }
    
    for (NSUInteger updateIndex = updateRangeStart; updateIndex <= updateRangeEnd; ++updateIndex)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:updateIndex inSection:0];
        NKTPage *pageToUpdate = [self.fetchedResultsController objectAtIndexPath:indexPath];
        NSUInteger currentPageNumber = [pageToUpdate.pageNumber unsignedIntegerValue];
        pageToUpdate.pageNumber = [NSNumber numberWithUnsignedInteger:currentPageNumber + indexAdjustment];
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
    NKTPage *page = [self.fetchedResultsController objectAtIndexPath:indexPath];
    self.selectedPage = page;
    pageViewController_.page = page;
}

#pragma mark -
#pragma mark Configuring a Navigation Interface

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    if (editing)
    {
        // TODO: bug
        // Hide navigation item
        [self.navigationItem setHidesBackButton:YES animated:NO];
        // Hide toolbar items
        [self setToolbarItems:nil animated:YES];
        // TODO: this needs to be more sophisticated
        [pageViewController_.textView resignFirstResponder];
        [pageViewController_ freezeUserInteraction];
    }
    else
    {
        // Restore navigation item
        [self.navigationItem setHidesBackButton:NO animated:NO];
        // Restore toolbar items
        [self setToolbarItems:[NSArray arrayWithObjects:addPageItem_, nil] animated:YES];
        // When editing ends, reselect the current page
        NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:selectedPage_];
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        [pageViewController_ unfreezeUserInteraction];
    }
}

@end
