//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KobaUI.h"

@class NKTTextPosition;

// NKTTextRange is a subclass of UITextRange that represents text positions with instances of NKTTextPosition.
@interface NKTTextRange : UITextRange
{
@private
    NKTTextPosition *startTextPosition_;
    NKTTextPosition *endTextPosition_;
}

#pragma mark Initializing

- (id)initWithTextPosition:(NKTTextPosition *)textPosition textPosition:(NKTTextPosition *)otherTextPosition;

+ (id)textRangeWithTextPosition:(NKTTextPosition *)textPosition textPosition:(NKTTextPosition *)otherTextPosition;

#pragma mark Accessing the Range

@property (nonatomic, readonly) NSRange nsRange;
@property (nonatomic, readonly) CFRange cfRange;
@property (nonatomic, readonly) NSUInteger location;
@property (nonatomic, readonly) NSUInteger length;

#pragma mark Checking for Text Position Containment

- (BOOL)containsTextPosition:(NKTTextPosition *)textPosition;
- (BOOL)containsTextPositionIgnoringAffinity:(NKTTextPosition *)textPosition;

#pragma mark Creating Text Ranges

- (NKTTextRange *)textRangeByApplyingStartOffset:(NSUInteger)offset;
- (NKTTextRange *)textRangeByApplyingEndOffset:(NSUInteger)offset;

#pragma mark Comparing Text Ranges

- (BOOL)isEqualToTextRange:(NKTTextRange *)textRange;
- (BOOL)isEqualToTextPosition:(NKTTextPosition *)textPosition;

@end

@interface NKTTextRange(PropertyRedeclarations)

#pragma mark Accessing the Text Positions

@property (nonatomic, readonly) NKTTextPosition *start;
@property (nonatomic, readonly) NKTTextPosition *end;

@end
