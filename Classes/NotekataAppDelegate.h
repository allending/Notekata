//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@class NKTPageViewController;
@class NKTRootViewController;

// NotekataAppDelegate
@interface NotekataAppDelegate : NSObject <UIApplicationDelegate>
{
@private
    // Data
    NSManagedObjectContext *managedObjectContext_;
    NSManagedObjectModel *managedObjectModel_;
    NSPersistentStoreCoordinator *persistentStoreCoordinator_;
    
    // Control
    UISplitViewController *splitViewController_;
    NKTRootViewController *rootViewController_;
    NKTPageViewController *pageViewController_;    
    
    // UI
    UIWindow *window_;
}

#pragma mark Core Data Stack

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

#pragma mark Application's Documents Directory

- (NSString *)applicationDocumentsDirectory;

#pragma mark Accessing View Controllers

@property (nonatomic, retain) IBOutlet UISplitViewController *splitViewController;
@property (nonatomic, retain) IBOutlet NKTRootViewController *rootViewController;
@property (nonatomic, retain) IBOutlet NKTPageViewController *pageViewController;

#pragma mark Accessing the Window

@property (nonatomic, retain) IBOutlet UIWindow *window;

@end
