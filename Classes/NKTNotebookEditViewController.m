//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTNotebookEditViewController.h"
#import "NKTNotebook.h"
#import "NKTPage.h"

@implementation NKTNotebookEditViewController

@synthesize notebook = notebook_;
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
#pragma mark Memory

- (void)dealloc
{
    [notebook_ release];
    [managedObjectContext_ release];
    
    [navigationBar_ release];
    [doneButton_ release];
    [cancelButton_ release];
    [tableView_ release];
    [titleCell_ release];
    [titleField_ release];
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
    tableView_.dataSource = self;
    tableView_.delegate = self;
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
    
    // PENDING: localize
    if (mode_ == NKTNotebookEditViewControllerModeAdd)
    {
        titleField_.text = nil;
        navigationBar_.topItem.title = @"Add Notebook";
        doneButton_.title = @"Add";
    }
    else
    {
        titleField_.text = notebook_.title;
        navigationBar_.topItem.title = ([notebook_.title length] != 0) ? notebook_.title : @"Notebook";
        doneButton_.title = @"Save";
    }
    
    [titleField_ becomeFirstResponder];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark -
#pragma mark Notebooks

- (NSArray *)sortedNotebooks
{
    // Create request for all notebooks sorted by display order
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Notebook" inManagedObjectContext:managedObjectContext_];
    [fetchRequest setEntity:entity];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"displayOrder" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    NSError *error = nil;
    NSArray *notebooks = [managedObjectContext_ executeFetchRequest:fetchRequest error:&error];
    if (error != nil)
    {
        // PENDING: fix and log
        KBCLogWarning(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    [fetchRequest release];
    [sortDescriptor release];
    return notebooks;
}

- (void)configureToAddNotebook
{
    mode_ = NKTNotebookEditViewControllerModeAdd;
    self.notebook = nil;
}

- (void)configureToEditNotebook:(NKTNotebook *)notebook
{
    mode_ = NKTNotebookEditViewControllerModeEdit;
    self.notebook = notebook;
}

#pragma mark -
#pragma mark Actions

- (void)cancel
{
    [self.titleField resignFirstResponder];
    
    if ([delegate_ respondsToSelector:@selector(notebookEditViewControllerDidCancel:)])
    {
        [delegate_ notebookEditViewControllerDidCancel:self];
    }
}

- (void)save
{
    if (mode_ == NKTNotebookEditViewControllerModeAdd)
    {
        [self addNotebook];
    }
    else
    {
        [self editNotebook];
    }
}

- (void)addNotebook
{
    if (managedObjectContext_ == nil)
    {
        KBCLogWarning(@"managed object context is nil, returning");
        [self.parentViewController dismissModalViewControllerAnimated:YES];
        return;
    }
    
    [self.titleField resignFirstResponder];
    
    // Get the last notebook that exists
    NSArray *sortedNotebooks = [self sortedNotebooks];
    NKTNotebook *lastNotebook = nil;
    if ([sortedNotebooks count] > 0)
    {
        lastNotebook = [sortedNotebooks objectAtIndex:[sortedNotebooks count] - 1];
    }
    
    // Create notebook
    NKTNotebook *addedNotebook = [NSEntityDescription insertNewObjectForEntityForName:@"Notebook" inManagedObjectContext:managedObjectContext_];
    addedNotebook.title = [titleField_.text length] == 0 ? @"Untitled Notebook" : titleField_.text;
    
    // Generate random uuid as the notebook id
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);
    addedNotebook.notebookId = (NSString *)uuidString;
    CFRelease(uuid);
    CFRelease(uuidString);
    
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
        // PENDING: fix and log
        KBCLogWarning(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    if ([delegate_ respondsToSelector:@selector(notebookEditViewController:didAddNotebook:)])
    {
        [delegate_ notebookEditViewController:self didAddNotebook:addedNotebook];
    }
}

- (void)editNotebook
{
    [self.titleField resignFirstResponder];
    notebook_.title = titleField_.text;
    
    NSError *error = nil;
    if (![managedObjectContext_ save:&error])
    {
        // PENDING: fix and log
        KBCLogWarning(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    if ([delegate_ respondsToSelector:@selector(notebookEditViewController:didEditNotebook:)])
    {
        [delegate_ notebookEditViewController:self didEditNotebook:notebook_];
    }
    
    self.notebook = nil;
}

#pragma mark -
#pragma mark Text Field

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    [self save];
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

@end
