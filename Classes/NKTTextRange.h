//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaCore.h"

@class NKTTextPosition;

//--------------------------------------------------------------------------------------------------
// NKTTextRange is a subclass of UITextRange that creates NKTTextPosition objects to represent its
// text positions.
//--------------------------------------------------------------------------------------------------

@interface NKTTextRange : UITextRange
{
@private
    NKTTextPosition *start;
    NSUInteger length;
}

#pragma mark Initializing

- (id)initWithTextPosition:(NKTTextPosition *)textPosition length:(NSUInteger)length;
- (id)initWithIndex:(NSUInteger)index length:(NSUInteger)length;

+ (id)textRangeWithTextPosition:(NKTTextPosition *)textPosition length:(NSUInteger)length;
+ (id)textRangeWithIndex:(NSUInteger)index length:(NSUInteger)length;

#pragma mark Getting Range Lengths

@property (nonatomic, readonly) NSUInteger length;

#pragma mark Getting NSRanges

- (NSRange)nsRange;

#pragma mark Checking Text Positions

- (BOOL)containsTextPosition:(NKTTextPosition *)textPosition;

#pragma mark Creating Text Ranges

- (NKTTextRange *)textRangeByGrowingLeft;

- (NKTTextRange *)textRangeByReplacingLengthWithLength:(NSUInteger)length;
- (NKTTextRange *)textRangeByReplacingStartIndexWithIndex:(NSUInteger)index;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------

@interface NKTTextRange(PropertyRedeclarations)

@property (nonatomic, readonly) NKTTextPosition *start;
@property (nonatomic, readonly) NKTTextPosition *end;

@end
