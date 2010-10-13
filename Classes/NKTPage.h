//
//  NKTPage.h
//  Notekata
//
//  Created by Allen Ding on 10/11/10.
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import <CoreData/CoreData.h>

@class NKTNotebook;

@interface NKTPage :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * pageNumber;
@property (nonatomic, retain) NSNumber * pageId;
@property (nonatomic, retain) id text;
@property (nonatomic, retain) NKTNotebook * notebook;

@end
