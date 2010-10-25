//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "NotekataAppDelegate.h"
#import "NKTNotebook+CustomAdditions.h"
#import "NKTPage+CustomAdditions.h"
#import "NKTPageViewController.h"
#import "NKTRootViewController.h"

@implementation NotekataAppDelegate

@synthesize splitViewController = splitViewController_;
@synthesize rootViewController = rootViewController_;
@synthesize pageViewController = pageViewController_;

@synthesize window = window_;

static NSString *StorePath = @"Notekata.sqlite";
static NSString *ModelResource = @"Notekata";
static NSString *ModelType = @"mom";

#pragma mark -
#pragma mark Memory

- (void)dealloc
{
    [managedObjectContext_ release];
    [managedObjectModel_ release];
    [persistentStoreCoordinator_ release];
    
    [splitViewController_ release];
    [rootViewController_ release];
    [pageViewController_ release];
    
    [window_ release];
    [super dealloc];
}

#pragma mark -
#pragma mark Application

- (void)awakeFromNib
{
    rootViewController_.managedObjectContext = self.managedObjectContext; 
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self primeNotebookData];
    [window_ addSubview:splitViewController_.view];
    [rootViewController_ selectInitialNotebook];
    [window_ makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of
     temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and
     it begins the transition to the background state.
     
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use
     this method to pause the game.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    if (managedObjectContext_ != nil)
    {
        // Final chance for page view controller to save changes
        [pageViewController_ savePendingChanges];
        [pageViewController_ purgeCachedResources];
        
        NSError *error = nil;
        if ([managedObjectContext_ hasChanges] && ![managedObjectContext_ save:&error])
        {
            KBCLogWarning(@"Failed to save to data store: %@", [error localizedDescription]);
            KBCLogWarning(@"%@", KBCDetailedCoreDataErrorStringFromError(error));
            abort();
        }
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    if (managedObjectContext_ != nil)
    {
        // Final chance for page view controller to save changes
        [pageViewController_ savePendingChanges];
        
        NSError *error = nil;
        if ([managedObjectContext_ hasChanges] && ![managedObjectContext_ save:&error])
        {
            KBCLogWarning(@"Failed to save to data store: %@", [error localizedDescription]);
            KBCLogWarning(@"%@", KBCDetailedCoreDataErrorStringFromError(error));
            abort();
        }
    }
}

#pragma mark -
#pragma mark Notebooks

- (void)primeNotebookData
{
    // Check to make sure a notebook exists
    NSError *error = nil;
    NSArray *notebooks = [NKTNotebook fetchNotebooksInManagedObjectContext:managedObjectContext_ fetchLimit:1 error:&error];
    if (error != nil)
    {
        KBCLogWarning(@"Failed to perform fetch: %@", [error localizedDescription]);
        KBCLogWarning(@"%@", KBCDetailedCoreDataErrorStringFromError(error));
        abort();
    }
    
    // Create default notebook if none exist
    if ([notebooks count] == 0)
    {
        [NKTNotebook insertNotebookInManagedObjectContext:managedObjectContext_];
        error = nil;
        if (![managedObjectContext_ save:&error])
        {
            KBCLogWarning(@"Failed to save to data store: %@", [error localizedDescription]);
            KBCLogWarning(@"%@", KBCDetailedCoreDataErrorStringFromError(error));
            abort();
        }
    }
}

#pragma mark -
#pragma mark Directories

- (NSString *)applicationDocumentsDirectory
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

#pragma mark -
#pragma mark Core Data

- (NSManagedObjectContext *)managedObjectContext
{    
    if (managedObjectContext_ != nil)
    {
        return managedObjectContext_;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    
    if (coordinator != nil)
    {
        managedObjectContext_ = [[NSManagedObjectContext alloc] init];
        [managedObjectContext_ setPersistentStoreCoordinator:coordinator];
    }
    
    return managedObjectContext_;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (managedObjectModel_ != nil)
    {
        return managedObjectModel_;
    }
    
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:ModelResource ofType:ModelType];
    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    managedObjectModel_ = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return managedObjectModel_;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{ 
    if (persistentStoreCoordinator_ != nil)
    {
        return persistentStoreCoordinator_;
    }
    
    NSString *storePath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:StorePath];
    NSURL *storeURL = [NSURL fileURLWithPath:storePath];
    persistentStoreCoordinator_ = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    NSError *error = nil;
    if (![persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a
         shipping application, although it may be useful during development. If it is not possible to recover from the
         error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file
         URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],NSMigratePersistentStoresAutomaticallyOption,
         [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
         nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning
         and Data Migration Programming Guide" for details.
         
         */
        
        // PENDING: fix and log
        KBCLogWarning(@"Failed to create persistent store: %@", [error localizedDescription]);
        KBCLogWarning(@"%@", KBCDetailedCoreDataErrorStringFromError(error));
        abort();
    }
    
    return persistentStoreCoordinator_;
}

@end
