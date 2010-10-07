//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaUI.h"

@class NKTTextPosition;

// NKTTextRange is a subclass of UITextRange that represents text position with instances of
// NKTTextPosition.
//
@interface NKTTextRange : UITextRange
{
@private
    NSRange range_;
    UITextStorageDirection affinity_;
}

#pragma mark Initializing

//- (id)initWithRange:(NSRange)range;
- (id)initWithRange:(NSRange)range affinity:(UITextStorageDirection)affinity;

//+ (id)textRangeWithRange:(NSRange)range;
+ (id)textRangeWithRange:(NSRange)range affinity:(UITextStorageDirection)affinity;
+ (id)textRangeWithTextPosition:(NKTTextPosition *)firstTextPosition
                   textPosition:(NKTTextPosition *)secondTextPosition;

#pragma mark Accessing the Range

@property (nonatomic, readonly) NSRange range;
@property (nonatomic, readonly) NSUInteger location;
@property (nonatomic, readonly) NSUInteger length;

#pragma mark Accessing the Affinity

@property (nonatomic, readonly) UITextStorageDirection affinity;

#pragma mark Checking for Text Position Containment

- (BOOL)enclosesTextPosition:(NKTTextPosition *)textPosition;

#pragma mark Creating Text Ranges

- (NKTTextRange *)textRangeByGrowingLeft;
- (NKTTextRange *)textRangeByGrowingRight;
- (NKTTextRange *)textRangeByChangingLocation:(NSUInteger)location;
- (NKTTextRange *)textRangeByChangingLength:(NSUInteger)length;
- (NKTTextRange *)textRangeByClippingUntilTextPosition:(NKTTextPosition *)textPosition;
- (NKTTextRange *)textRangeByClippingFromTextPosition:(NKTTextPosition *)textPosition;

#pragma mark Comparing Text Ranges

- (BOOL)isEqualToTextRange:(NKTTextRange *)textRange;
- (BOOL)isEqualToTextPosition:(NKTTextPosition *)textPosition;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------

@interface NKTTextRange(PropertyRedeclarations)

@property (nonatomic, readonly) NKTTextPosition *start;
@property (nonatomic, readonly) NKTTextPosition *end;

@end
