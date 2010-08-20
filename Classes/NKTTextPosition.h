//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NKTTextRange;

@interface NKTTextPosition : UITextPosition {
@private
    NSUInteger index;
}

#pragma mark -
#pragma mark Initializing

- (id)initWithIndex:(NSUInteger)position;

+ (id)textPositionWithIndex:(NSUInteger)position;

#pragma mark -
#pragma mark Accessing the Index

@property (nonatomic, readonly) NSUInteger index;

#pragma mark -
#pragma mark Creating Text Ranges

- (NKTTextRange *)emptyTextRange;

@end
