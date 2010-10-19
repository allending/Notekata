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
    BOOL changeIsUserDriven_;
    
    NKTPageViewController *pageViewController_;
    
    UILabel *titleLabel_;
    UIBarButtonItem *addPageItem_;
    UIActionSheet *addPageActionSheet_;
}

#pragma mark Notebook

// Calling this also sets the page property of the page view controller.
- (void)setNotebook:(NKTNotebook *)notebook restoreLastSelectedPage:(BOOL)restoreLastSelectedPage;

#pragma mark Pages

@property (nonatomic, readonly, retain) NKTPage *selectedPage;

- (NKTPage *)pageAtIndex:(NSUInteger)index;
- (NKTPage *)addPage;

#pragma mark Actions

- (void)handleAddPageItemTapped:(UIBarButtonItem *)item;
- (void)addPageAndBeginEditing;

#pragma mark View Controllers

@property (nonatomic, retain) IBOutlet NKTPageViewController *pageViewController;

#pragma mark Views

@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UIBarButtonItem *addPageItem;
@property (nonatomic, retain) UIActionSheet *addPageActionSheet;

#pragma mark Table View

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

#pragma mark Fetched Results Controller

@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;

@end
