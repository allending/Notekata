//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTNotebookEditViewController.h"
#import "NKTNotebook+CustomAdditions.h"
#import "NKTPage+CustomAdditions.h"
#import "NKTPageViewController.h"

@implementation NKTNotebookEditViewController

@synthesize managedObjectContext = managedObjectContext_;
@synthesize notebook = notebook_;

@synthesize delegate = delegate_;

@synthesize navigationBar = navigationBar_;
@synthesize doneButton = doneButton_;
@synthesize cancelButton = cancelButton_;
@synthesize tableView = tableView_;
@synthesize titleCell = titleCell_;
@synthesize titleField = titleField_;

static const NSUInteger TitleSection = 0;
static const NSUInteger NotebookStyleSection = 1;

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
    [managedObjectContext_ release];
    [notebook_ release];
    
    [navigationBar_ release];
    [doneButton_ release];
    [cancelButton_ release];
    [tableView_ release];
    [titleCell_ release];
    [titleField_ release];
    [super dealloc];
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
    
    // Update UI elements
    if (mode_ == NKTNotebookEditViewControllerModeAdd)
    {
        titleField_.text = nil;
        navigationBar_.topItem.title = @"Add Notebook";
        doneButton_.title = @"Add";
    }
    else
    {
        titleField_.text = notebook_.title;
        navigationBar_.topItem.title = @"Edit Notebook";
        doneButton_.title = @"Save";
    }
    
    // Reload table data
    [tableView_ reloadData];
    
    if (mode_ == NKTNotebookEditViewControllerModeAdd)
    {
        [titleField_ becomeFirstResponder];
    }
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

- (void)configureForAddingNotebook
{
    mode_ = NKTNotebookEditViewControllerModeAdd;
    self.notebook = nil;
    selectedNotebookStyleIndex_ = 0;
}

- (void)configureForEditingNotebook:(NKTNotebook *)notebook
{
    mode_ = NKTNotebookEditViewControllerModeEdit;
    self.notebook = notebook;
    selectedNotebookStyleIndex_ = [notebook.notebookStyle integerValue];
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
    [self.titleField resignFirstResponder];
    
    // Get the last notebook that exists
    NSArray *sortedNotebooks = [self sortedNotebooks];
    NKTNotebook *lastNotebook = nil;
    if ([sortedNotebooks count] > 0)
    {
        lastNotebook = [sortedNotebooks objectAtIndex:[sortedNotebooks count] - 1];
    }
    
    // Create notebook and configure
    NKTNotebook *addedNotebook = [NKTNotebook insertNotebookInManagedObjectContext:managedObjectContext_];
    addedNotebook.title = [titleField_.text length] == 0 ? @"Untitled Notebook" : titleField_.text;
    addedNotebook.notebookStyle = [NSNumber numberWithUnsignedInteger:selectedNotebookStyleIndex_];
    NSInteger displayOrder = [lastNotebook.displayOrder integerValue] + 1;
    addedNotebook.displayOrder = [NSNumber numberWithInteger:displayOrder];
    
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
    
    // Update notebook
    notebook_.title = titleField_.text;
    notebook_.notebookStyle = [NSNumber numberWithUnsignedInteger:selectedNotebookStyleIndex_];
    
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
#pragma mark Text Field Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    [self save];
    return YES;
}

#pragma mark -
#pragma mark Table View Data Source/Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case TitleSection:
            return 1;
            break;
            
        case NotebookStyleSection:
            return 3;
            break;
            
        default:
            break;
    }
    
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == NotebookStyleSection)
    {
        return @"Notebook Style";
    }
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == TitleSection)
    {
        return titleCell_;
    }
    else
    {
        static NSString *CellIdentifier = @"Cell";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil)
        {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        }
        
        [self configureNotebookStyleCell:cell atIndexPath:indexPath];
        return cell;
    }
}

- (void)configureNotebookStyleCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row)
    {
        case NKTNotebookStyleElegant:
            cell.textLabel.text = @"Elegant";
            break;
            
        case NKTNotebookStyleCollegeRuled:
            cell.textLabel.text = @"College Ruled";
            break;
            
        case NKTNotebookStylePlain:
            cell.textLabel.text = @"Plain";
            break;
            
        default:
            break;
    }
    
    if (indexPath.row == selectedNotebookStyleIndex_)
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != NotebookStyleSection)
    {
        return;
    }
    
    [titleField_ resignFirstResponder];
    
    // Uncheck old notebook style cell
    if (selectedNotebookStyleIndex_ != indexPath.row)
    {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedNotebookStyleIndex_ inSection:1]];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    selectedNotebookStyleIndex_ = indexPath.row;
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
