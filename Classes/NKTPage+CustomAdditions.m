//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTPage+CustomAdditions.h"

@implementation NKTPage(CustomAdditions)

static NSString *PageEntityName = @"Page";

#pragma mark -
#pragma mark Initializing

+ (id)insertPageInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    NKTPage *page = [NSEntityDescription insertNewObjectForEntityForName:PageEntityName inManagedObjectContext:managedObjectContext];
    page.pageNumber = [NSNumber numberWithInteger:0];
    page.textString = @"";
    page.textStyleString = @"";
    return page;
}

@end
