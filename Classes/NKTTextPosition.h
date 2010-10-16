//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KobaUI.h"

@class NKTTextRange;

// NKTTextPosition is a subclass of UITextPosition. It represents an indexed position into a text object.
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

#pragma mark Accessing the Text Position

@property (nonatomic, readonly) NSUInteger location;
@property (nonatomic, readonly) UITextStorageDirection affinity;

#pragma mark Creating Text Positions

- (NKTTextPosition *)textPositionByApplyingOffset:(NSInteger)offset;

#pragma mark Creating Text Ranges

- (NKTTextRange *)textRange;

#pragma mark Comparing Text Posiitons

- (NSComparisonResult)compare:(NKTTextPosition *)textPosition;
- (NSComparisonResult)compareIgnoringAffinity:(NKTTextPosition *)textPosition;

- (BOOL)isEqualToTextPosition:(NKTTextPosition *)textPosition;
- (BOOL)isEqualToTextPositionIgnoringAffinity:(NKTTextPosition *)textPosition;

@end
