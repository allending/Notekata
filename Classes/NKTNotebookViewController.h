//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KobaUI.h"
#import <CoreData/CoreData.h>
#import "NKTPageViewController.h"

@class NKTNotebook;
@class NKTPage;
@class NKTPageViewController;

// NKTNotebookViewController manages the editing of an NKTNotebook.
@interface NKTNotebookViewController : UITableViewController <NKTPageViewControllerDelegate, UIActionSheetDelegate, NSFetchedResultsControllerDelegate>
{
@private
    NSFetchedResultsController *fetchedResultsController_;
    NKTNotebook *notebook_;
    NKTPage *selectedPage_;
    BOOL modelChangeIsUserDriven_;
    
    NKTPageViewController *pageViewController_;
    
    UILabel *titleLabel_;
    UIBarButtonItem *pageAddItem_;
    UIActionSheet *pageAddActionSheet_;
    NSIndexPath *pageDeleteIndexPath_;
    UIActionSheet *pageDeleteConfirmationActionSheet_;
}

#pragma mark -
#pragma mark Notebook

// Calling this also sets the page property of the page view controller.
- (void)setNotebook:(NKTNotebook *)notebook restoreLastSelectedPage:(BOOL)restoreLastSelectedPage;

#pragma mark -
#pragma mark Pages

- (NKTPage *)pageAtIndex:(NSUInteger)index;
- (NKTPage *)addPageToNotebook;
- (void)presentPageDeleteConfirmationForPageAtIndexPath:(NSIndexPath *)indexPath;

#pragma mark -
#pragma mark Actions

- (void)pageAddToolbarItemTapped:(UIBarButtonItem *)item;
- (void)addPageAndBeginEditing;

#pragma mark -
#pragma mark View Controllers

@property (nonatomic, retain) IBOutlet NKTPageViewController *pageViewController;

#pragma mark -
#pragma mark Views

@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UIBarButtonItem *pageAddItem;
@property (nonatomic, retain) UIActionSheet *pageAddActionSheet;
@property (nonatomic, retain) NSIndexPath *pageDeleteIndexPath;

#pragma mark -
#pragma mark Table View Data Source/Delegate

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

#pragma mark -
#pragma mark Core Data

@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;

@end
