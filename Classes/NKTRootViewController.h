//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KobaUI.h"
#import <CoreData/CoreData.h>
#import "NKTEditNotebookViewController.h"

@class NKTNotebook;
@class NKTNotebookViewController;
@class NKTPageViewController;

// NKTNotebookViewController manages the editing of a library of NKTNotebooks.
@interface NKTRootViewController : UITableViewController <NSFetchedResultsControllerDelegate, UIActionSheetDelegate, NKTEditNotebookViewControllerDelegate>
{
@private
    NSManagedObjectContext *managedObjectContext_;
    NSFetchedResultsController *fetchedResultsController_;
    NKTNotebook *selectedNotebook_;
    BOOL changeIsUserDriven_;
    
    NKTNotebookViewController *notebookViewController_;
    NKTPageViewController *pageViewController_;
    NKTEditNotebookViewController *editNotebookViewController_;
    
    UILabel *titleLabel_;
    UIBarButtonItem *addNotebookItem_;
    UIActionSheet *addNotebookActionSheet_;
}

#pragma mark Notebooks

@property (nonatomic, readonly, retain) NKTNotebook *selectedNotebook;

- (void)selectInitialNotebook;

- (NKTNotebook *)notebookAtIndex:(NSUInteger)index;

#pragma mark View Controllers

@property (nonatomic, retain) IBOutlet NKTNotebookViewController *notebookViewController;
@property (nonatomic, retain) IBOutlet NKTPageViewController *pageViewController;
@property (nonatomic, retain) NKTEditNotebookViewController *editNotebookViewController;

#pragma mark Views

@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UIBarButtonItem *addNotebookItem;
@property (nonatomic, retain) UIActionSheet *addNotebookActionSheet;

#pragma mark Actions

- (void)handleAddNotebookItemTapped:(UIBarButtonItem *)item;
- (void)presentAddNotebookViewController;

#pragma mark Table View

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

#pragma mark Core Data

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;

@end
