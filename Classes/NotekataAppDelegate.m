//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "NotekataAppDelegate.h"
#import "NKTNotebook.h"
#import "NKTPage.h"
#import "NKTPageViewController.h"
#import "NKTRootViewController.h"

// NotekataAppDelegate private interface
@interface NotekataAppDelegate()

#pragma mark Creating a Default Notebook

- (void)ensureNotebookExists;

@end

#pragma mark -

@implementation NotekataAppDelegate

@synthesize splitViewController = splitViewController_;
@synthesize rootViewController = rootViewController_;
@synthesize pageViewController = pageViewController_;

@synthesize window = window_;

#pragma mark -
#pragma mark Memory management

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

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
}

#pragma mark -
#pragma mark Application Lifecycle

- (void)awakeFromNib
{
    rootViewController_.managedObjectContext = self.managedObjectContext; 
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self ensureNotebookExists];
    
    [window_ addSubview:splitViewController_.view];
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

- (void)applicationWillTerminate:(UIApplication *)application
{
    // HACK: force page view controller to save contents until I figure out what condition causes the page view not
    // to receive end text editing messages leading to a page text save
    KBCLogDebug(@"forcing page view controller to save edited page text");
    [pageViewController_ saveEditedPageText];
    
    // Save changes in the application's managed object context before the application terminates
    if (managedObjectContext_ != nil)
    {
        NSError *error = nil;
        
        if ([managedObjectContext_ hasChanges] && ![managedObjectContext_ save:&error])
        {
            // TODO: FIX and LOG
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark -
#pragma mark Core Data Stack

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
    
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"Notekata" ofType:@"mom"];
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
    
    NSString *storePath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"Notekata.sqlite"];
    NSURL *storeURL = [NSURL fileURLWithPath:storePath];
    persistentStoreCoordinator_ = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSError *error = nil;
    
    if (![persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:storeURL
                                                         options:nil
                                                           error:&error])
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
        
        // TODO: FIX, REMOVE AFTER DEVELOPMENT
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

#pragma mark -
#pragma mark Application's Documents Directory

- (NSString *)applicationDocumentsDirectory
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

#pragma mark -
#pragma mark Creating a Default Notebook

// If no notebooks exist in the managed object context, creates one with a default title and page.
- (void)ensureNotebookExists
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Notebook"
                                              inManagedObjectContext:managedObjectContext_];
    [fetchRequest setEntity:entity];
    
    NSError *error = nil;
    NSArray *notebooks = [managedObjectContext_ executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release];
    
    if (error != nil)
    {
        // TODO: FIX, LOG
        KBCLogWarning(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    if ([notebooks count] == 0)
    {
        NKTNotebook *notebook = [NSEntityDescription insertNewObjectForEntityForName:[entity name]
                                                              inManagedObjectContext:managedObjectContext_];
        notebook.title = @"My Notebook";
        notebook.notebookId = [NSNumber numberWithInteger:0];
        
        NKTPage *page = [NSEntityDescription insertNewObjectForEntityForName:@"Page"
                                                      inManagedObjectContext:managedObjectContext_];
        page.text = [[NSAttributedString alloc] initWithString:@""];
        [notebook addPagesObject:page];
        
        error = nil;
        
        if (![managedObjectContext_ save:&error])
        {
            // TODO: FIX, LOG
            KBCLogWarning(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end
