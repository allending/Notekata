//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaUI.h"

@class NKTTextPosition;

//--------------------------------------------------------------------------------------------------
// NKTTextRange is a subclass of UITextRange that represents text position with instances of
// NKTTextPosition.
//--------------------------------------------------------------------------------------------------

@interface NKTTextRange : UITextRange
{
@private
    NSRange nsRange_;
}

#pragma mark Initializing

- (id)initWithNSRange:(NSRange)nsRange;

+ (id)textRangeWithNSRange:(NSRange)nsRange;

#pragma mark Accessing the Range

@property (nonatomic, readonly) NSRange nsRange;
@property (nonatomic, readonly) NSUInteger location;
@property (nonatomic, readonly) NSUInteger length;

#pragma mark Checking for Text Position Containment

- (BOOL)containsTextPosition:(NKTTextPosition *)textPosition;

#pragma mark Comparing Text Ranges

- (BOOL)isEqualToTextRange:(NKTTextRange *)textRange;
- (BOOL)isEqualToTextPosition:(NKTTextPosition *)textPosition;

#pragma mark Creating Text Ranges

- (NKTTextRange *)textRangeByGrowingLeft;
- (NKTTextRange *)textRangeByGrowingRight;
- (NKTTextRange *)textRangeByChangingLocation:(NSUInteger)location;
- (NKTTextRange *)textRangeByChangingLength:(NSUInteger)length;
- (NKTTextRange *)textRangeByClippingUntilTextPosition:(NKTTextPosition *)textPosition;
- (NKTTextRange *)textRangeByClippingFromTextPosition:(NKTTextPosition *)textPosition;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------

@interface NKTTextRange(PropertyRedeclarations)

@property (nonatomic, readonly) NKTTextPosition *start;
@property (nonatomic, readonly) NKTTextPosition *end;

@end
