//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KobaUI.h"
#import <CoreData/CoreData.h>

@class NKTNotebook;

@protocol NKTNotebookEditViewControllerDelegate;

typedef enum
{
    NKTNotebookEditViewControllerModeAdd,
    NKTNotebookEditViewControllerModeEdit
} NKTNotebookEditViewControllerMode;

// NKTNotebookEditViewController displays a modal interface for adding or editing a notebook.
@interface NKTNotebookEditViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
{
@private
    NSManagedObjectContext *managedObjectContext_;
    NKTNotebookEditViewControllerMode mode_;
    NKTNotebook *notebook_;
    NSUInteger selectedNotebookStyleIndex_;
    
    id <NKTNotebookEditViewControllerDelegate> delegate_;
    
    UINavigationBar *navigationBar_;
    UIBarButtonItem *doneButton_;
    UIBarButtonItem *cancelButton_;
    UITableView *tableView_;
    UITableViewCell *titleCell_;
    UITextField *titleField_;
}

#pragma mark -
#pragma mark Delegate

@property (nonatomic, assign) id <NKTNotebookEditViewControllerDelegate> delegate;

#pragma mark -
#pragma mark Notebooks

@property (nonatomic, retain) NKTNotebook *notebook;

- (NSArray *)sortedNotebooks;
- (void)configureForAddingNotebook;
- (void)configureForEditingNotebook:(NKTNotebook *)notebook;

#pragma mark -
#pragma mark Actions

- (IBAction)save;
- (IBAction)cancel;
- (void)addNotebook;
- (void)editNotebook;

#pragma mark -
#pragma mark Views

@property (nonatomic, retain) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *doneButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *cancelButton;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UITableViewCell *titleCell;
@property (nonatomic, retain) IBOutlet UITextField *titleField;

#pragma mark -
#pragma mark Table View Data Source/Delegate

- (void)configureNotebookStyleCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

#pragma mark -
#pragma mark Core Data

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@end

// NKTNotebookEditViewControllerDelegate
@protocol NKTNotebookEditViewControllerDelegate <NSObject>

@optional

#pragma mark -
#pragma mark Responding to Notebook Edit View Controller Events

- (void)notebookEditViewControllerDidCancel:(NKTNotebookEditViewController *)notebookEditViewController;
- (void)notebookEditViewController:(NKTNotebookEditViewController *)notebookEditViewController didAddNotebook:(NKTNotebook *)notebook;
- (void)notebookEditViewController:(NKTNotebookEditViewController *)notebookEditViewController didEditNotebook:(NKTNotebook *)notebook;

@end
