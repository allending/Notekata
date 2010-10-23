//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KobaUI.h"
#import "NKTNotebook.h"

@interface NKTNotebook(CustomAdditions)

#pragma mark Initializing

+ (id)insertNotebookInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

#pragma mark Fetching

+ (NSArray *)fetchNotebooksInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext fetchLimit:(NSUInteger)fetchLimit error:(NSError **)error;

@end
