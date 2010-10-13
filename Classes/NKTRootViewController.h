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
    NKTNotebook *selectedNotebook_;
    
    // Control
    NKTNotebookViewController *notebookViewController_;
    NKTPageViewController *pageViewController_;
}

#pragma mark Core Data Stack

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;

#pragma mark Accessing the Selected Notebook

@property (nonatomic, retain) NKTNotebook *selectedNotebook;

#pragma mark Adding Notebooks

- (void)insertNotebook;

#pragma mark Accessing View Controllers

@property (nonatomic, retain) IBOutlet NKTNotebookViewController *notebookViewController;
@property (nonatomic, retain) IBOutlet NKTPageViewController *pageViewController;

#pragma mark Monitoring the Application

- (void)applicationDidFinishLaunching:(UIApplication *)application;
- (void)applicationWillTerminate:(UIApplication *)application;

@end
