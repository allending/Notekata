//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KobaUI.h"
#import <CoreData/CoreData.h>

@class NKTNotebook;

@protocol NKTEditNotebookViewControllerDelegate;

typedef enum
{
    NKTEditNotebookViewControllerModeAdd,
    NKTEditNotebookViewControllerModeEdit
} NKTEditNotebookViewControllerMode;

// NKTEditNotebookViewController
@interface NKTEditNotebookViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
@private
    // Data    
    NKTEditNotebookViewControllerMode mode_;
    NSManagedObjectContext *managedObjectContext_;
    
    // Delegate
    id <NKTEditNotebookViewControllerDelegate> delegate_;
    
    // UI
    UINavigationBar *navigationBar_;
    UIBarButtonItem *doneButton_;
    UIBarButtonItem *cancelButton_;
    UITableView *tableView_;
    UITableViewCell *titleCell_;
    UITextField *titleField_;
}

#pragma mark Core Data Stack

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

#pragma mark Accessing the Delegate

@property (nonatomic, assign) id <NKTEditNotebookViewControllerDelegate> delegate;

#pragma mark Accessing Views

@property (nonatomic, retain) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *doneButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *cancelButton;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UITableViewCell *titleCell;
@property (nonatomic, retain) IBOutlet UITextField *titleField;

#pragma mark Configuring the View Controller

- (void)configureToAddNotebook;

#pragma mark Responding to User Actions

- (IBAction)save;
- (IBAction)cancel;

@end

#pragma mark -

// NKTEditNotebookViewControllerDelegate is a protocol that allows clients to receive editing related messages from an
// NKTEditNotebookViewController.
@protocol NKTEditNotebookViewControllerDelegate <NSObject>

@optional

#pragma mark Responding to Edit Notebook View Controller Events

- (void)editNotebookViewController:(NKTEditNotebookViewController *)editNotebookViewController
                    didAddNotebook:(NKTNotebook *)notebook;

@end
