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
@interface NKTNotebookViewController : UITableViewController <NKTPageViewControllerDelegate,
                                                              NSFetchedResultsControllerDelegate>
{
@private
    // Data
    NSFetchedResultsController *fetchedResultsController_;
    NKTNotebook *notebook_;
    NKTPage *selectedPage_;
    BOOL changeIsUserDriven_;
    
    // Control
    NKTPageViewController *pageViewController_;
    
    // UI
    UILabel *titleLabel_;
    UIBarButtonItem *addPageItem_;
}

#pragma mark Accessing the Notebook

@property (nonatomic, retain) NKTNotebook *notebook;

#pragma mark Accessing View Controllers

@property (nonatomic, retain) IBOutlet NKTPageViewController *pageViewController;

@end
