//
//  NKTNotebook.h
//  Notekata
//
//  Created by Allen Ding on 10/18/10.
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import <CoreData/CoreData.h>

@class NKTPage;

@interface NKTNotebook :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * notebookId;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * displayOrder;
@property (nonatomic, retain) NSSet* pages;

@end


@interface NKTNotebook (CoreDataGeneratedAccessors)
- (void)addPagesObject:(NKTPage *)value;
- (void)removePagesObject:(NKTPage *)value;
- (void)addPages:(NSSet *)value;
- (void)removePages:(NSSet *)value;

@end

