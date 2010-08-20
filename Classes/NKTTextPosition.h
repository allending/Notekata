//===================================================================================================
//
// Copyright 2010 Allen Ding. All rights reserved.
//
//===================================================================================================

#import <UIKit/UIKit.h>

@class NKTTextRange;

//===================================================================================================
// NKTTextPosition is a subclass of UITextPosition. It represents an indexed position into the 
// backing string of a text view.
//===================================================================================================

@interface NKTTextPosition : UITextPosition {
@private
    NSUInteger index;
}

#pragma mark -
#pragma mark Initializing

- (id)initWithIndex:(NSUInteger)index;

+ (id)textPositionWithIndex:(NSUInteger)index;

#pragma mark -
#pragma mark Accessing the Index

@property (nonatomic, readonly) NSUInteger index;

#pragma mark -
#pragma mark Creating Text Ranges

- (NKTTextRange *)emptyTextRange;

@end
