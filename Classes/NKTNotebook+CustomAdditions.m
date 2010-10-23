//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTNotebook+CustomAdditions.h"
#import "NKTPage+CustomAdditions.h"

@implementation NKTNotebook(CustomAdditions)

static NSString *NotebookEntityName = @"Notebook";
static NSString *DefaultNotebookTitle = @"My Notebook";

#pragma mark -
#pragma mark Initializing

+ (id)insertNotebookInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    NKTNotebook *notebook = [NSEntityDescription insertNewObjectForEntityForName:NotebookEntityName inManagedObjectContext:managedObjectContext];
    notebook.notebookStyle = [NSNumber numberWithInteger:0];
    notebook.title = DefaultNotebookTitle;
    notebook.displayOrder = [NSNumber numberWithUnsignedInt:0];
    notebook.notebookId = KBCUUIDString();
    // Add empty page
    NKTPage *page = [NKTPage insertPageInManagedObjectContext:managedObjectContext];
    [notebook addPagesObject:page];
    return notebook;
}

#pragma mark -
#pragma mark Fetching

+ (NSArray *)fetchNotebooksInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext fetchLimit:(NSUInteger)fetchLimit error:(NSError **)error
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:NotebookEntityName inManagedObjectContext:managedObjectContext];
    [request setEntity:entity];
    [request setFetchLimit:fetchLimit];
    NSArray *notebooks = [managedObjectContext executeFetchRequest:request error:error];
    [request release];
    return notebooks;
}

@end
