//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NotekataAppDelegate.h"
#import "NKTRootViewController.h"
#import "NKTPageViewController.h"

@implementation NotekataAppDelegate

@synthesize window = window_;
@synthesize splitViewController = splitViewController_;
@synthesize rootViewController = rootViewController_;
@synthesize pageViewController = pageViewController_;

//--------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Application Lifecycle

- (void)awakeFromNib
{
    // Pass the managed object context to the root view controller.
    rootViewController_.managedObjectContext = self.managedObjectContext; 
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after app launch.
    [rootViewController_ applicationDidFinishLaunching:application];
    
    // Add the split view controller's view to the window and display.
    [window_ addSubview:splitViewController_.view];
    [window_ makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive.
     */
}

// applicationWillTerminate: saves changes in the application's managed object context before the
// application terminates.
- (void)applicationWillTerminate:(UIApplication *)application
{
    [rootViewController_ applicationWillTerminate:application];
    
    NSError *error = nil;
    
    if (managedObjectContext_ != nil)
    {
        if ([managedObjectContext_ hasChanges] && ![managedObjectContext_ save:&error])
        {
            // Replace this implementation with code to handle the error appropriately.
            //
            // abort() causes the application to generate a crash log and terminate.
            // You should not use this function in a shipping application, although it may be
            // useful during development. If it is not possible to recover from the error,
            // display an alert panel that instructs the user to quit the application by pressing
            // the Home button.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

//--------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}

- (void)dealloc
{
    [window_ release];
    [splitViewController_ release];
    [rootViewController_ release];
    [pageViewController_ release];
    [managedObjectContext_ release];
    [managedObjectModel_ release];
    [persistentStoreCoordinator_ release];
    [super dealloc];
}

//--------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Core Data Stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator
// for the application.
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


// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (managedObjectModel_ != nil)
    {
        return managedObjectModel_;
    }
    
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"Notekata" ofType:@"mom"];
    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    managedObjectModel_ = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return managedObjectModel_;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to
// it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{ 
    if (persistentStoreCoordinator_ != nil)
    {
        return persistentStoreCoordinator_;
    }
    
    NSURL *storeURL = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"Notekata.sqlite"]];
    
    NSError *error = nil;
    persistentStoreCoordinator_ = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    if (![persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        
        // TODO: REMOVE AFTER DEVELOPMENT
        if ([error code] == NSPersistentStoreIncompatibleVersionHashError)
        {
            KBCLogWarning(@"core data error %@, deleting store and retrying", [error description]);
            
            [[NSFileManager defaultManager] removeItemAtPath:[storeURL path] error:nil];
            
            if ([persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
            {
                return persistentStoreCoordinator_;
            }
        }
        
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return persistentStoreCoordinator_;
}

//--------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Application's Documents Directory

//  Returns the path to the application's Documents directory.
- (NSString *)applicationDocumentsDirectory
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

@end
