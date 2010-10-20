//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTNotebookViewController.h"
#import "NKTNotebook.h"
#import "NKTPage.h"

@interface NKTNotebookViewController()

@property (nonatomic, readwrite,retain) NKTPage *selectedPage;

@end

@implementation NKTNotebookViewController

@synthesize fetchedResultsController = fetchedResultsController_;
@synthesize selectedPage = selectedPage_;

@synthesize pageViewController = pageViewController_;

@synthesize titleLabel = titleLabel_;
@synthesize addPageItem = addPageItem_;
@synthesize addPageActionSheet = addPageActionSheet_;

static NSString *SelectedPageNumbersDictionaryKey = @"SelectedPageNumbersDictionary";
static const NSUInteger AddPageButtonIndex = 0;

#pragma mark -
#pragma mark Memory

- (void)dealloc
{
    [fetchedResultsController_ release];
    [notebook_ release];
    [selectedPage_ release];
    
    [pageViewController_ release];
    
    [titleLabel_ release];
    [addPageItem_ release];
    [addPageActionSheet_ release];
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
    self.clearsSelectionOnViewWillAppear = NO;
    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // Create custom navigation title view
    titleLabel_ = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 20.0)];
    titleLabel_.backgroundColor = [UIColor clearColor];
    titleLabel_.textAlignment = UITextAlignmentCenter;
    titleLabel_.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0];
    titleLabel_.textColor = [UIColor whiteColor];
    titleLabel_.text = notebook_.title;
    self.navigationItem.titleView = titleLabel_;

    // Create toolbar items
    addPageItem_ = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(handleAddPageItemTapped:)];
    self.toolbarItems = [NSArray arrayWithObjects:addPageItem_, nil];
    
    pageViewController_.delegate = self;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.titleLabel = nil;
    self.addPageItem = nil;
    self.addPageActionSheet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // There seems to be a bug in UIKit where the navigation controller navigation bar and toolbar
    // may not respect the set styles after rotation animations. As a workaround, we force the style.    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.toolbar.barStyle = UIBarStyleBlack;
    
    titleLabel_.text = notebook_.title;
    
    // Update table and selected page in table
    [self.tableView reloadData];
    
    if (selectedPage_ != nil)
    {
        NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:selectedPage_];
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // HACK: a bit of a hack to figure out when we are are navigating away from this view
    // controller
    if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound)
    {
        [pageViewController_.textView resignFirstResponder];
    }
    
    // Save last selected page of notebook
    if (notebook_ != nil && selectedPage_ != nil) 
    {
        NSMutableDictionary *dictionary = [[[NSUserDefaults standardUserDefaults] objectForKey:SelectedPageNumbersDictionaryKey] mutableCopy];
        
        if (dictionary == nil)
        {
            dictionary = [[NSMutableDictionary alloc] init];
        }
        
        [dictionary setObject:selectedPage_.pageNumber forKey:notebook_.notebookId];
        [[NSUserDefaults standardUserDefaults] setObject:dictionary forKey:SelectedPageNumbersDictionaryKey];
        [dictionary release];
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
        [pageViewController_ freeze];
    }
    else
    {
        // PENDING: find Core Animation bug workaround
        [self setToolbarItems:[NSArray arrayWithObjects:addPageItem_, nil] animated:YES];
        // The table view selection state is potentially out of date
        NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:selectedPage_];
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        [pageViewController_ unfreeze];
    }
}

#pragma mark -
#pragma mark Notebook

- (void)setNotebook:(NKTNotebook *)notebook restoreLastSelectedPage:(BOOL)restoreLastSelectedPage
{
    if (notebook_ == notebook)
    {
        return;
    }
    
    [notebook_ release];
    notebook_ = [notebook retain];
    
    // Invalidate previously fetched results
    self.fetchedResultsController = nil;
    
    // Load the last selected page, or fallback to the first page of the notebook
    NKTPage *page = nil;
    
    if (notebook_ != nil)
    {
        if (restoreLastSelectedPage)
        {
            NSDictionary *dictionary = [[NSUserDefaults standardUserDefaults] objectForKey:SelectedPageNumbersDictionaryKey];
            NSUInteger pageNumber = [[dictionary objectForKey:notebook.notebookId] unsignedIntegerValue];
            
            if (pageNumber < [[notebook_ pages] count])
            {
                page = [self pageAtIndex:pageNumber];
            }
        }
        
        if (page == nil)
        {
            page = [self pageAtIndex:0];
        }
    }
    
    self.selectedPage = page;
    // PENDING:
    // Common Issue: what if the page view controller's page is no longer valid?
    [pageViewController_ savePendingChanges];
    pageViewController_.page = page;
}

#pragma mark -
#pragma mark Pages

- (NKTPage *)pageAtIndex:(NSUInteger)index
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    return [self.fetchedResultsController objectAtIndexPath:indexPath];
}

- (NKTPage *)addPage
{
    if (notebook_ == nil)
    {
        KBCLogWarning(@"notebook is nil, returning nil");
        return nil;
    }
    
    // Create a new page and add it to the notebook
    NKTPage *page = [NSEntityDescription insertNewObjectForEntityForName:@"Page" inManagedObjectContext:notebook_.managedObjectContext];
    page.pageNumber = [NSNumber numberWithUnsignedInteger:[[notebook_ pages] count]];
    page.textString = @"";
    page.textStyleString = @"";
    [notebook_ addPagesObject:page];
    
    NSError *error = nil;
    if (![notebook_.managedObjectContext save:&error])
    {
        // PENDING: fix and log
        KBCLogWarning(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return page;
}

#pragma mark -
#pragma mark Actions

- (void)handleAddPageItemTapped:(UIBarButtonItem *)item
{
    if (!addPageActionSheet_.visible)
    {
        [addPageActionSheet_ release];
        addPageActionSheet_ = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Add Page", nil];
        [addPageActionSheet_ showFromBarButtonItem:item animated:YES];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex)
    {
        case AddPageButtonIndex:
            [self addPageAndBeginEditing];
            break;
            
        default:
            break;
    }
    
    [addPageActionSheet_ autorelease];
    addPageActionSheet_ = nil;
}

- (void)addPageAndBeginEditing
{
    NKTPage *page = [self addPage];
    self.selectedPage = page;
    // Select and scroll to added page
    NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:page];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    // Start editing immediately
    [pageViewController_ savePendingChanges];
    pageViewController_.page = page;
    [pageViewController_ dismissNotebookPopoverAnimated:YES];
    [pageViewController_.textView becomeFirstResponder];
}

#pragma mark -
#pragma mark Page View Controller

- (void)pageViewController:(NKTPageViewController *)pageViewController textViewDidChange:(NKTTextView *)textView
{
    NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:selectedPage_];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    // PENDING: can optimize if text position is given
    [self configureCell:cell atIndexPath:indexPath];
}

#pragma mark -
#pragma mark Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
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
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    // Assign a snippet to the text label based on the page's text
    NKTPage *page = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.showsReorderControl = YES;
    
    NSString *snippetSource = nil;
    
    // If the cell is for the selected page, the cell uses the string directly from the text view
    if (page == selectedPage_)
    {
        snippetSource = [[pageViewController_.textView text] string];
    }
    else
    {
        snippetSource = page.textString;
    }
    
    NSString *snippet = KUITrimmedSnippetFromString(snippetSource, 50);
    
    if ([snippet length] == 0)
    {
        // PENDING: localization
        cell.textLabel.text = @"Untitled";
    }
    else
    {
        cell.textLabel.text = snippet;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle != UITableViewCellEditingStyleDelete)
    {
        KBCLogWarning(@"unexpected editing style commit, returning");
        return;
    }
    
    NKTPage *pageToDelete = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // Stop editing page if we are about to delete it
    if (pageToDelete == selectedPage_)
    {
        pageViewController_.page = nil;
    }
    
    // Renumber the pages first
    NSUInteger renumberRangeStart = indexPath.row + 1;
    NSUInteger renumberRangeEnd = [[notebook_ pages] count];
    for (NSUInteger index = renumberRangeStart; index < renumberRangeEnd; ++index)
    {
        NSIndexPath *renumberIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
        NKTPage *pageToRenumber = [self.fetchedResultsController objectAtIndexPath:renumberIndexPath];
        //  Adjust offsets of pages following the deleted page by -1
        NSUInteger pageNumber = index - 1;
        pageToRenumber.pageNumber = [NSNumber numberWithInteger:pageNumber];
    }
    
    // Delete the page
    [notebook_ removePagesObject:pageToDelete];
    [notebook_.managedObjectContext deleteObject:pageToDelete];
    
    // Add a page if the deleted page was the last one
    if ([[notebook_ pages] count] == 0)
    {
        NKTPage *pageToAdd = [NSEntityDescription insertNewObjectForEntityForName:@"Page" inManagedObjectContext:notebook_.managedObjectContext];
        pageToAdd.pageNumber = [NSNumber numberWithInteger:0];
        pageToAdd.textString = @"";
        pageToAdd.textStyleString = @"";
        [notebook_ addPagesObject:pageToAdd];
    }
    
    NSError *error = nil;
    if (![notebook_.managedObjectContext save:&error])
    {
        // PENDING: fix and log
        KBCLogWarning(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    // Select new page if the deleted page was the selected page
    if (pageToDelete == selectedPage_)
    {
        // Select the new page occupying the deleted page number's spot, or the last page of the notebook
        NKTPage *pageToSelect = nil;
        NSUInteger numberOfPages = [[notebook_ pages] count];
        
        if (indexPath.row < numberOfPages)
        {
            pageToSelect = [self.fetchedResultsController objectAtIndexPath:indexPath];
        }
        else
        {
            NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:numberOfPages - 1 inSection:0];
            pageToSelect = [self.fetchedResultsController objectAtIndexPath:newIndexPath];
        }
        
        self.selectedPage = pageToSelect;
        pageViewController_.page = pageToSelect;
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
    
    // Set page number of moved page
    NKTPage *page = [self.fetchedResultsController objectAtIndexPath:fromIndexPath];
    page.pageNumber = [NSNumber numberWithUnsignedInteger:toIndex];
    
    // Renumber rest of the pages
    NSUInteger renumberRangeStart = 0;
    NSUInteger renumberRangeEnd = 0;
    NSInteger pageNumberAdjustment = 0;
    
    if (fromIndex < toIndex)
    {
        renumberRangeStart = fromIndex + 1;
        renumberRangeEnd = toIndex + 1;
        pageNumberAdjustment = -1;
    }
    else
    {
        renumberRangeStart = toIndex;
        renumberRangeEnd = fromIndex;
        pageNumberAdjustment = 1;
    }
    
    for (NSUInteger index = renumberRangeStart; index < renumberRangeEnd; ++index)
    {
        NSIndexPath *renumberIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
        NKTPage *pageToRenumber = [self.fetchedResultsController objectAtIndexPath:renumberIndexPath];
        NSInteger pageNumber = [pageToRenumber.pageNumber integerValue] + pageNumberAdjustment;
        pageToRenumber.pageNumber = [NSNumber numberWithInteger:pageNumber];
    }
    
    NSError *error = nil;
    if (![notebook_.managedObjectContext save:&error])
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
    [pageViewController_.textView resignFirstResponder];
    NKTPage *page = [self.fetchedResultsController objectAtIndexPath:indexPath];
    self.selectedPage = page;
    [pageViewController_ savePendingChanges];
    pageViewController_.page = page;
    [pageViewController_ dismissNotebookPopoverAnimated:YES];
}

#pragma mark -
#pragma mark Fetched Results Controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (notebook_ == nil)
    {
        KBCLogWarning(@"notebook is nil, returning nil");
        return nil;
    }
    
    if (fetchedResultsController_ != nil)
    {
        return fetchedResultsController_;
    }
    
    // Create request for pages of notebook sorted by pageNumber
    NSManagedObjectContext *managedObjectContext = notebook_.managedObjectContext;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Page" inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"notebook = %@", notebook_];
    [fetchRequest setPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"pageNumber" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    // Create the controller
    fetchedResultsController_ = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    fetchedResultsController_.delegate = self;
    
    // Fetch
    NSError *error = nil;
    if (![fetchedResultsController_ performFetch:&error])
    {
        // PENDING: fix and log
        KBCLogWarning(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
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
