//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaUI.h"

@class NKTTextRange;

//--------------------------------------------------------------------------------------------------
// NKTTextPosition is a subclass of UITextPosition. It represents an indexed position into the 
// backing string of a text view.
//--------------------------------------------------------------------------------------------------

@interface NKTTextPosition : UITextPosition
{
@private
    NSUInteger location_;
}

#pragma mark Initializing

- (id)initWithLocation:(NSUInteger)location;

+ (id)textPositionWithLocation:(NSUInteger)location;

#pragma mark Accessing the Location

@property (nonatomic, readonly) NSUInteger location;

#pragma mark Creating Text Positions

- (NKTTextPosition *)previousTextPosition;
- (NKTTextPosition *)nextTextPosition;
- (NKTTextPosition *)textPositionByApplyingOffset:(NSInteger)offset;

#pragma mark Creating Text Ranges

- (NKTTextRange *)textRange;
- (NKTTextRange *)textRangeWithTextPosition:(NKTTextPosition *)textPosition;

#pragma mark Comparing Text Posiitons

- (BOOL)isEqualToTextPosition:(NKTTextPosition *)textPosition;

@end
