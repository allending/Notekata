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

// NKTNotebookEditViewController
@interface NKTNotebookEditViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
{
@private
    // Data    
    NKTNotebookEditViewControllerMode mode_;
    NKTNotebook *notebook_;
    NSManagedObjectContext *managedObjectContext_;
    
    // Delegate
    id <NKTNotebookEditViewControllerDelegate> delegate_;
    
    // UI
    UINavigationBar *navigationBar_;
    UIBarButtonItem *doneButton_;
    UIBarButtonItem *cancelButton_;
    UITableView *tableView_;
    UITableViewCell *titleCell_;
    UITextField *titleField_;
}

#pragma mark Delegate

@property (nonatomic, assign) id <NKTNotebookEditViewControllerDelegate> delegate;

#pragma mark Notebooks

@property (nonatomic, retain) NKTNotebook *notebook;

- (NSArray *)sortedNotebooks;
- (void)configureToAddNotebook;
- (void)configureToEditNotebook:(NKTNotebook *)notebook;

#pragma mark Views

@property (nonatomic, retain) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *doneButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *cancelButton;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UITableViewCell *titleCell;
@property (nonatomic, retain) IBOutlet UITextField *titleField;

#pragma mark Actions

- (IBAction)save;
- (IBAction)cancel;
- (void)addNotebook;
- (void)editNotebook;

#pragma mark Core Data

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@end

// NKTNotebookEditViewControllerDelegate is a protocol that allows clients to receive editing related messages from an
// NKTNotebookEditViewController.
@protocol NKTNotebookEditViewControllerDelegate <NSObject>

@optional

#pragma mark Responding to Notebook Edit View Controller Events

- (void)notebookEditViewControllerDidCancel:(NKTNotebookEditViewController *)notebookEditViewController;
- (void)notebookEditViewController:(NKTNotebookEditViewController *)notebookEditViewController didAddNotebook:(NKTNotebook *)notebook;
- (void)notebookEditViewController:(NKTNotebookEditViewController *)notebookEditViewController didEditNotebook:(NKTNotebook *)notebook;

@end
