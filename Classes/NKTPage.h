//
//  NKTPage.h
//  Notekata
//
//  Created by Allen Ding on 10/25/10.
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import <CoreData/CoreData.h>

@class NKTNotebook;

@interface NKTPage :  NSManagedObject  
{
}

@property (nonatomic, retain) NSDate * creationDate;
@property (nonatomic, retain) NSNumber * pageNumber;
@property (nonatomic, retain) NSString * textString;
@property (nonatomic, retain) NSDate * textModifiedDate;
@property (nonatomic, retain) NSString * textStyleString;
@property (nonatomic, retain) NKTNotebook * notebook;

@end



