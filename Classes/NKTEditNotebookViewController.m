//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTEditNotebookViewController.h"
#import "NKTNotebook.h"
#import "NKTPage.h"

@implementation NKTEditNotebookViewController

@synthesize managedObjectContext = managedObjectContext_;

@synthesize delegate = delegate_;

@synthesize navigationBar = navigationBar_;
@synthesize doneButton = doneButton_;
@synthesize cancelButton = cancelButton_;
@synthesize tableView = tableView_;
@synthesize titleCell = titleCell_;
@synthesize titleField = titleField_;

#pragma mark -
#pragma mark Initializing

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
    {
        self.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    return self;
}

#pragma mark -
#pragma mark Memory Mangement

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Accessing Notebooks

- (NSArray *)sortedNotebooks
{
    // Create request for all notebooks sorted by display order
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Notebook"
                                              inManagedObjectContext:managedObjectContext_];
    [fetchRequest setEntity:entity];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"displayOrder" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    NSError *error = nil;
    NSArray *sortedNotebooks = [managedObjectContext_ executeFetchRequest:fetchRequest error:&error];
    if (error != nil)
    {
        // TODO: FIX, LOG
        KBCLogWarning(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    [fetchRequest release];
    [sortDescriptor release];
    return sortedNotebooks;
}

#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    tableView_.dataSource = self;
    tableView_.delegate = self;
    [self configureToAddNotebook];
}

- (void)dealloc
{
    [managedObjectContext_ release];
    
    [navigationBar_ release];
    [doneButton_  release];
    [cancelButton_ release];
    [tableView_ release];
    [titleCell_ release];
    [titleField_ release];
    [super dealloc];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.navigationBar = nil;
    self.doneButton = nil;
    self.cancelButton = nil;
    self.tableView = nil;
    self.titleCell = nil;
    self.titleField = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [titleField_ becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

#pragma mark Handling Rotations

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark -
#pragma mark Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return titleCell_;
}

#pragma mark -
#pragma mark Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{}

#pragma mark Configuring the View Controller

- (void)configureToAddNotebook
{
    mode_ = NKTEditNotebookViewControllerModeAdd;
    navigationBar_.topItem.title = @"Add Notebook";
    doneButton_.title = @"Add";
}

#pragma mark -
#pragma mark Responding to User Actions


- (void)cancel
{
    [self.titleField resignFirstResponder];
    [self.parentViewController dismissModalViewControllerAnimated:YES];
}

- (void)save
{
    [self.titleField resignFirstResponder];
    
    if (managedObjectContext_ == nil)
    {
        KBCLogWarning(@"managed object context is nil, returning");
        [self.parentViewController dismissModalViewControllerAnimated:YES];
        return;
    }
    
    // Get the last notebook that exists
    NSArray *sortedNotebooks = [self sortedNotebooks];
    NKTNotebook *lastNotebook = nil;
    if ([sortedNotebooks count] > 0)
    {
        lastNotebook = [sortedNotebooks objectAtIndex:[sortedNotebooks count] - 1];
    }
    
    // Create notebook
    NKTNotebook *addedNotebook = [NSEntityDescription insertNewObjectForEntityForName:@"Notebook"
                                                               inManagedObjectContext:managedObjectContext_];
    addedNotebook.title = [titleField_.text length] == 0 ? @"Untitled" : titleField_.text;
    addedNotebook.notebookId = [NSNumber numberWithInteger:0];
    NSInteger displayOrder = [lastNotebook.displayOrder integerValue] + 1;
    addedNotebook.displayOrder = [NSNumber numberWithInteger:displayOrder];
    // Create first page
    NKTPage *page = [NSEntityDescription insertNewObjectForEntityForName:@"Page"
                                                  inManagedObjectContext:managedObjectContext_];
    page.pageNumber = [NSNumber numberWithInteger:0];
    page.textString = @"";
    page.textStyleString = @"";
    [addedNotebook addPagesObject:page];
    
    NSError *error = nil;
    if (![managedObjectContext_ save:&error])
    {
        // TODO: FIX, LOG
        KBCLogWarning(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    if ([delegate_ respondsToSelector:@selector(editNotebookViewController:didAddNotebook:)])
    {
        [delegate_ editNotebookViewController:self didAddNotebook:addedNotebook];
    }
    
    [self.parentViewController dismissModalViewControllerAnimated:YES];
}

@end
