//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KobaUI.h"
#import "NKTPage.h"

@interface NKTPage(CustomAdditions)

#pragma mark Initializing

+ (id)insertPageInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end
