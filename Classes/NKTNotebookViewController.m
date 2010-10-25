//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTNotebookViewController.h"
#import "NKTNotebook+CustomAdditions.h"
#import "NKTPage+CustomAdditions.h"

@interface NKTNotebookViewController()

@property (nonatomic, readwrite,retain) NKTPage *selectedPage;

@end

@implementation NKTNotebookViewController

@synthesize fetchedResultsController = fetchedResultsController_;
@synthesize selectedPage = selectedPage_;

@synthesize pageViewController = pageViewController_;

@synthesize titleLabel = titleLabel_;
@synthesize pageAddItem = pageAddItem_;
@synthesize pageAddActionSheet = pageAddActionSheet_;
@synthesize pageDeleteIndexPath = pageDeleteIndexPath_;

static const NSUInteger TitleSnippetSourceLength = 50;
static NSString *LastViewedPageNumbersKey = @"LastViewedPageNumbers";

#pragma mark -
#pragma mark Memory

- (void)dealloc
{
    [fetchedResultsController_ release];
    [notebook_ release];
    [selectedPage_ release];
    
    [pageViewController_ release];
    
    [titleLabel_ release];
    [pageAddItem_ release];
    [pageAddActionSheet_ release];
    [pageDeleteIndexPath_ release];
    [pageDeleteConfirmationActionSheet_ release];
    [super dealloc];
}

#pragma mark -
#pragma mark View Controller

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = NO;
    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // Custom navigation title
    titleLabel_ = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 20.0)];
    titleLabel_.backgroundColor = [UIColor clearColor];
    titleLabel_.textAlignment = UITextAlignmentCenter;
    titleLabel_.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0];
    titleLabel_.textColor = [UIColor whiteColor];
    titleLabel_.text = notebook_.title;
    self.navigationItem.titleView = titleLabel_;
    
    // Toolbar items
    pageAddItem_ = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(pageAddToolbarItemTapped:)];
    self.toolbarItems = [NSArray arrayWithObjects:pageAddItem_, nil];
    
    // Page view controller
    pageViewController_.delegate = self;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.titleLabel = nil;
    self.pageAddItem = nil;
    self.pageAddActionSheet = nil;
    self.pageDeleteIndexPath = nil;
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
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionTop];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // HACK: figure out when we are are navigating away from this view controller
    if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound)
    {
        [pageViewController_.textView resignFirstResponder];
    }
    
    // Save last selected page of notebook
    if (notebook_ != nil && selectedPage_ != nil) 
    {
        NSMutableDictionary *dictionary = [[[NSUserDefaults standardUserDefaults] objectForKey:LastViewedPageNumbersKey] mutableCopy];
        
        if (dictionary == nil)
        {
            dictionary = [[NSMutableDictionary alloc] init];
        }
        
        [dictionary setObject:selectedPage_.pageNumber forKey:notebook_.notebookId];
        [[NSUserDefaults standardUserDefaults] setObject:dictionary forKey:LastViewedPageNumbersKey];
        [dictionary release];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self setEditing:NO animated:NO];
    [pageAddActionSheet_ dismissWithClickedButtonIndex:pageAddActionSheet_.cancelButtonIndex animated:NO];
    [pageDeleteConfirmationActionSheet_ dismissWithClickedButtonIndex:pageDeleteConfirmationActionSheet_.cancelButtonIndex animated:NO];
    pageDeleteConfirmationActionSheet_ = nil;
    self.pageDeleteIndexPath = nil;
}

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
        [self setToolbarItems:[NSArray arrayWithObjects:pageAddItem_, nil] animated:YES];
        // The table view selection state might be out of date
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
            NSDictionary *dictionary = [[NSUserDefaults standardUserDefaults] objectForKey:LastViewedPageNumbersKey];
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
    pageViewController_.page = page;
}

#pragma mark -
#pragma mark Pages

- (NKTPage *)pageAtIndex:(NSUInteger)index
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    return [self.fetchedResultsController objectAtIndexPath:indexPath];
}

- (NKTPage *)addPageToNotebook
{
    if (notebook_ == nil)
    {
        KBCLogWarning(@"Notebook is nil. Returning nil.");
        return nil;
    }
    
    NKTPage *page = [NKTPage insertPageInManagedObjectContext:notebook_.managedObjectContext];
    page.pageNumber = [NSNumber numberWithUnsignedInteger:[[notebook_ pages] count]];
    [notebook_ addPagesObject:page];
    
    NSError *error = nil;
    if (![notebook_.managedObjectContext save:&error])
    {
        KBCLogWarning(@"Failed to save to data store: %@", [error localizedDescription]);
        KBCLogWarning(@"%@", KBCDetailedCoreDataErrorStringFromError(error));
        abort();
    }
    
    return page;
}

- (void)deletePageAtIndexPath:(NSIndexPath *)indexPath
{
    NKTPage *pageToDelete = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSUInteger numberOfPages = [[notebook_ pages] count];
    BOOL deletingSelectedPage = (pageToDelete == selectedPage_);
    BOOL deletingLastPage = (numberOfPages == 1);
    
    if (deletingSelectedPage)
    {
        pageViewController_.page = nil;
    }
    
    // Reorder the pages first
    NSUInteger reorderRangeStart = indexPath.row + 1;
    NSUInteger reorderRangeEnd = numberOfPages;
    for (NSUInteger index = reorderRangeStart; index < reorderRangeEnd; ++index)
    {
        NSIndexPath *reorderIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
        NKTPage *pageToReorder = [self.fetchedResultsController objectAtIndexPath:reorderIndexPath];
        pageToReorder.pageNumber = [NSNumber numberWithInteger:index - 1];
    }
    
    // Delete the page
    [notebook_ removePagesObject:pageToDelete];
    [notebook_.managedObjectContext deleteObject:pageToDelete];
    
    // Add a page if the deleted page was the last one
    if (deletingLastPage)
    {
        NKTPage *page = [NKTPage insertPageInManagedObjectContext:notebook_.managedObjectContext];
        [notebook_ addPagesObject:page];
    }
    
    NSError *error = nil;
    if (![notebook_.managedObjectContext save:&error])
    {
        KBCLogWarning(@"Failed to save to data store: %@", [error localizedDescription]);
        KBCLogWarning(@"%@", KBCDetailedCoreDataErrorStringFromError(error));
        abort();
    }
    
    // Select new page if the deleted page was the selected page
    if (deletingSelectedPage)
    {
        // Select the new page occupying the deleted page number's spot, or the last page of the notebook
        NKTPage *pageToSelect = nil;
        // Number of pages might have changed
        numberOfPages = [[notebook_ pages] count];
        
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

#pragma mark -
#pragma mark Actions

- (void)pageAddToolbarItemTapped:(UIBarButtonItem *)item
{
    if (pageAddActionSheet_.visible)
    {
        [pageAddActionSheet_ dismissWithClickedButtonIndex:pageAddActionSheet_.cancelButtonIndex animated:YES];
        pageAddActionSheet_ = nil;
    }
    else
    {
        pageAddActionSheet_ = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Add Page", nil];
        [pageAddActionSheet_ showFromBarButtonItem:item animated:YES];
        [pageAddActionSheet_ release];
    }
}

- (void)addPageAndBeginEditing
{
    NKTPage *page = [self addPageToNotebook];
    
    // Scroll to added page
    NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:page];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
    
    // Select added page
    self.selectedPage = page;
    pageViewController_.page = page;
    
    // Start editing immediately
    [pageViewController_ dismissNotebookPopoverAnimated:YES];
    [pageViewController_.textView becomeFirstResponder];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Present the next view after the sheet has been dismissed to prevent some animation
    // artifacts
    if (actionSheet == pageAddActionSheet_)
    {
        if (buttonIndex == pageAddActionSheet_.firstOtherButtonIndex)
        {
            [self addPageAndBeginEditing];
        }

        // Dismiss action sheet without animation to provide smoother transition
        [pageAddActionSheet_ dismissWithClickedButtonIndex:pageAddActionSheet_.firstOtherButtonIndex animated:NO];
        pageAddActionSheet_ = nil;
    }
    else if (actionSheet == pageDeleteConfirmationActionSheet_)
    {
        if (buttonIndex == pageDeleteConfirmationActionSheet_.destructiveButtonIndex)
        {
            [self deletePageAtIndexPath:pageDeleteIndexPath_];
        }
        
        self.pageDeleteIndexPath = nil;
        pageDeleteConfirmationActionSheet_ = nil;
    }
}

- (void)presentPageDeleteConfirmationForPageAtIndexPath:(NSIndexPath *)indexPath
{
    self.pageDeleteIndexPath = indexPath;
    pageDeleteConfirmationActionSheet_ = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete Page" otherButtonTitles:nil];
    [pageDeleteConfirmationActionSheet_ showInView:self.view];
    [pageDeleteConfirmationActionSheet_ release];
}

#pragma mark -
#pragma mark Page View Controller Delegate

- (void)pageViewController:(NKTPageViewController *)pageViewController textView:(NKTTextView *)textView didChangeFromTextPosition:(NKTTextPosition *)textPosition
{
    // Only update cell when change occurs in the range of text the cell text is generated from
    if (textPosition.location < TitleSnippetSourceLength)
    {
        NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:selectedPage_];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        [self configureCell:cell atIndexPath:indexPath];
    }
}

#pragma mark -
#pragma mark Table View Data Source/Delegate

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
    // Assign a snippet to the text label based on the page text
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
    
    NSString *snippet = KUITrimmedSnippetFromString(snippetSource, TitleSnippetSourceLength);
    
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
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [self presentPageDeleteConfirmationForPageAtIndexPath:indexPath];
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
    
    // Set page number of moved page
    NKTPage *page = [self.fetchedResultsController objectAtIndexPath:fromIndexPath];
    page.pageNumber = [NSNumber numberWithUnsignedInteger:toIndex];
    
    // Reorder other pages
    NSUInteger reorderRangeStart = 0;
    NSUInteger reorderRangeEnd = 0;
    NSInteger pageNumberAdjustment = 0;
    if (fromIndex < toIndex)
    {
        reorderRangeStart = fromIndex + 1;
        reorderRangeEnd = toIndex + 1;
        pageNumberAdjustment = -1;
    }
    else
    {
        reorderRangeStart = toIndex;
        reorderRangeEnd = fromIndex;
        pageNumberAdjustment = 1;
    }
    
    for (NSUInteger index = reorderRangeStart; index < reorderRangeEnd; ++index)
    {
        NSIndexPath *reorderIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
        NKTPage *pageToReorder = [self.fetchedResultsController objectAtIndexPath:reorderIndexPath];
        NSInteger pageNumber = [pageToReorder.pageNumber integerValue] + pageNumberAdjustment;
        pageToReorder.pageNumber = [NSNumber numberWithInteger:pageNumber];
    }
    
    NSError *error = nil;
    if (![notebook_.managedObjectContext save:&error])
    {
        KBCLogWarning(@"Failed to save to data store: %@", [error localizedDescription]);
        KBCLogWarning(@"%@", KBCDetailedCoreDataErrorStringFromError(error));
        abort();
    }
    
    modelChangeIsUserDriven_ = NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [pageViewController_.textView resignFirstResponder];
    NKTPage *page = [self.fetchedResultsController objectAtIndexPath:indexPath];
    self.selectedPage = page;
    pageViewController_.page = page;
    [pageViewController_ dismissNotebookPopoverAnimated:YES];
}

#pragma mark -
#pragma mark Fetched Results Controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (notebook_ == nil)
    {
        KBCLogWarning(@"Notebook is nil. Returning nil.");
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
        KBCLogWarning(@"Failed to perform fetch: %@", [error localizedDescription]);
        KBCLogWarning(@"%@", KBCDetailedCoreDataErrorStringFromError(error));
        abort();
    }
    
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
