//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaCore.h"

@class NKTTextRange;

//--------------------------------------------------------------------------------------------------
// NKTTextPosition is a subclass of UITextPosition. It represents an indexed position into the 
// backing string of a text view.
//--------------------------------------------------------------------------------------------------

@interface NKTTextPosition : UITextPosition
{
@private
    NSUInteger index;
}

#pragma mark Initializing

- (id)initWithIndex:(NSUInteger)index;

+ (id)textPositionWithIndex:(NSUInteger)index;

#pragma mark Accessing the Index

@property (nonatomic, readonly) NSUInteger index;

#pragma mark Creating Text Positions

- (NKTTextPosition *)previousTextPosition;
- (NKTTextPosition *)nextTextPosition;
- (NKTTextPosition *)textPositionByApplyingOffset:(NSInteger)offset;

#pragma mark Creating Text Ranges

- (NKTTextRange *)textRange;
- (NKTTextRange *)textRangeWithTextPosition:(NKTTextPosition *)textPosition;

@end
