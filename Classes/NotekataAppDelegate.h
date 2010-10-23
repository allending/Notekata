//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@class NKTPageViewController;
@class NKTRootViewController;

@interface NotekataAppDelegate : NSObject <UIApplicationDelegate>
{
@private
    NSManagedObjectContext *managedObjectContext_;
    NSManagedObjectModel *managedObjectModel_;
    NSPersistentStoreCoordinator *persistentStoreCoordinator_;
    
    UISplitViewController *splitViewController_;
    NKTRootViewController *rootViewController_;
    NKTPageViewController *pageViewController_;    
    
    UIWindow *window_;
}

#pragma mark -
#pragma mark Notebooks

- (void)primeNotebookData;

#pragma mark -
#pragma mark Directories

- (NSString *)applicationDocumentsDirectory;

#pragma mark -
#pragma mark View Controllers

@property (nonatomic, retain) IBOutlet UISplitViewController *splitViewController;
@property (nonatomic, retain) IBOutlet NKTRootViewController *rootViewController;
@property (nonatomic, retain) IBOutlet NKTPageViewController *pageViewController;

#pragma mark -
#pragma mark Views

@property (nonatomic, retain) IBOutlet UIWindow *window;

#pragma mark -
#pragma mark Core Data

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end
