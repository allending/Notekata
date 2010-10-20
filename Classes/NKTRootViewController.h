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
    NKTNotebook *selectedNotebook_;
    BOOL changeIsUserDriven_;
    
    NKTNotebookViewController *notebookViewController_;
    NKTPageViewController *pageViewController_;
    NKTNotebookEditViewController *notebookEditViewController_;
    
    UILabel *titleLabel_;
    UIBarButtonItem *notebookAddItem_;
    UIActionSheet *notebookAddActionSheet_;
    NSIndexPath *notebookDeleteIndexPath_;
    UIActionSheet *notebookDeleteConfirmationActionSheet_;
    
    NSManagedObjectContext *managedObjectContext_;
    NSFetchedResultsController *fetchedResultsController_;
}

#pragma mark -
#pragma mark Notebooks

@property (nonatomic, readonly, retain) NKTNotebook *selectedNotebook;

- (void)selectInitialNotebook;
- (NSUInteger)numberOfNotebooks;
- (NKTNotebook *)notebookAtIndex:(NSUInteger)index;
- (void)deleteNotebookAtIndexPath:(NSIndexPath *)indexPath;

#pragma mark -
#pragma mark Actions

- (void)addNotebookTapped:(id)sender;
- (void)presentNotebookAddViewController;
- (void)presentNotebookEditViewControllerForNotebookAtIndexPath:(NSIndexPath *)indexPath;
- (void)presentNotebookDeleteConfirmationForNotebookAtIndexPath:(NSIndexPath *)indexPath;

#pragma mark -
#pragma mark View Controllers

@property (nonatomic, retain) IBOutlet NKTNotebookViewController *notebookViewController;
@property (nonatomic, retain) IBOutlet NKTPageViewController *pageViewController;
@property (nonatomic, retain) NKTNotebookEditViewController *notebookEditViewController;

#pragma mark -
#pragma mark Views

@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UIBarButtonItem *notebookAddItem;
@property (nonatomic, retain) UIActionSheet *notebookAddActionSheet;
@property (nonatomic, retain) NSIndexPath *notebookDeleteIndexPath;
@property (nonatomic, retain) UIActionSheet *notebookDeleteConfirmationActionSheet;

#pragma mark -
#pragma mark Table View

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

#pragma mark -
#pragma mark Core Data

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;

@end
