//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KobaUI.h"
#import <CoreData/CoreData.h>
#import "NKTNotebookEditViewController.h"

@class NKTNotebook;
@class NKTNotebookViewController;
@class NKTPageViewController;

// NKTNotebookViewController manages the editing of a library of NKTNotebooks.
@interface NKTRootViewController : UITableViewController <NSFetchedResultsControllerDelegate, UIActionSheetDelegate, NKTNotebookEditViewControllerDelegate>
{
@private
    NSManagedObjectContext *managedObjectContext_;
    NSFetchedResultsController *fetchedResultsController_;
    NKTNotebook *selectedNotebook_;
    BOOL modelChangeIsUserDriven_;
    
    NKTNotebookViewController *notebookViewController_;
    NKTPageViewController *pageViewController_;
    NKTNotebookEditViewController *notebookEditViewController_;
    
    UIBarButtonItem *notebookAddToolbarItem_;
    UIActionSheet *notebookAddActionSheet_;
    NSIndexPath *notebookDeleteIndexPath_;
    UIActionSheet *notebookDeleteConfirmationActionSheet_;
}

#pragma mark -
#pragma mark Notebooks

- (void)selectInitialNotebook;
- (NSUInteger)numberOfNotebooks;
- (NKTNotebook *)notebookAtIndex:(NSUInteger)index;
- (void)deleteNotebookAtIndexPath:(NSIndexPath *)indexPath;

#pragma mark -
#pragma mark Actions

- (void)notebookAddToolbarItemTapped:(UIBarButtonItem *)item;
- (void)presentNotebookAddView;
- (void)presentNotebookEditViewForNotebookAtIndexPath:(NSIndexPath *)indexPath;
- (void)presentNotebookDeleteConfirmationForNotebookAtIndexPath:(NSIndexPath *)indexPath;

#pragma mark -
#pragma mark View Controllers

@property (nonatomic, retain) IBOutlet NKTNotebookViewController *notebookViewController;
@property (nonatomic, retain) IBOutlet NKTPageViewController *pageViewController;
@property (nonatomic, retain) NKTNotebookEditViewController *notebookEditViewController;

#pragma mark -
#pragma mark Views

@property (nonatomic, retain) UIBarButtonItem *notebookAddToolbarItem;
@property (nonatomic, retain) NSIndexPath *notebookDeleteIndexPath;

#pragma mark -
#pragma mark Table View Data Source/Delegate

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

#pragma mark -
#pragma mark Core Data

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;

@end
