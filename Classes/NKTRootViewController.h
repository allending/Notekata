//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KobaUI.h"
#import <CoreData/CoreData.h>

@class NKTNotebook;
@class NKTNotebookViewController;
@class NKTPageViewController;

// NKTNotebookViewController manages the editing of a library of NKTNotebooks.
@interface NKTRootViewController : UITableViewController <NSFetchedResultsControllerDelegate>
{
@private
    // Data
    NSManagedObjectContext *managedObjectContext_;
    NSFetchedResultsController *fetchedResultsController_;
    
    // Control
    NKTNotebookViewController *notebookViewController_;
    NKTPageViewController *pageViewController_;
}

#pragma mark Core Data Stack

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;

#pragma mark Accessing View Controllers

@property (nonatomic, retain) IBOutlet NKTNotebookViewController *notebookViewController;
@property (nonatomic, retain) IBOutlet NKTPageViewController *pageViewController;

@end
