//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaUI.h"

@class NKTTextRange;

// NKTTextPosition is a subclass of UITextPosition. It represents an indexed position into the 
// backing string of a text view.
@interface NKTTextPosition : UITextPosition
{
@private
    NSUInteger location_;
    UITextStorageDirection affinity_;
}

#pragma mark Initializing

- (id)initWithLocation:(NSUInteger)location;
- (id)initWithLocation:(NSUInteger)location affinity:(UITextStorageDirection)affinity;

+ (id)textPositionWithLocation:(NSUInteger)location;
+ (id)textPositionWithLocation:(NSUInteger)location affinity:(UITextStorageDirection)affinity;

#pragma mark Accessing the Location

@property (nonatomic, readonly) NSUInteger location;

#pragma mark Accessing the Affinity

@property (nonatomic, readonly) UITextStorageDirection affinity;

#pragma mark Creating Text Positions

- (NKTTextPosition *)previousTextPosition;
- (NKTTextPosition *)nextTextPosition;
- (NKTTextPosition *)textPositionByApplyingOffset:(NSInteger)offset;

#pragma mark Creating Text Ranges

- (NKTTextRange *)textRange;

#pragma mark Comparing Text Posiitons

- (NSComparisonResult)compare:(NKTTextPosition *)textPosition;
- (BOOL)isBeforeTextPosition:(NKTTextPosition *)textPosition;
- (BOOL)isAfterTextPosition:(NKTTextPosition *)textPosition;
- (BOOL)isEqualToTextPosition:(NKTTextPosition *)textPosition;

@end
