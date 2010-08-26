//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

@class NKTTextPosition;

//--------------------------------------------------------------------------------------------------=
// NKTTextRange is a subclass of UITextRange that creates NKTTextPosition objects to represent its
// text positions.
//--------------------------------------------------------------------------------------------------=

@interface NKTTextRange : UITextRange
{
@private
    NSRange nsRange;
}

#pragma mark Initializing

- (id)initWithNSRange:(NSRange)nsRange;

+ (id)textRangeWithNSRange:(NSRange)nsRange;
+ (id)textRangeWithTextPosition:(NKTTextPosition *)textPosition textPosition:(NKTTextPosition *)otherTextPosition;

#pragma mark Accessing the NSRange

@property (nonatomic, readonly) NSRange nsRange;

#pragma mark Accessing Range Indices

// TODO: needed?
@property (nonatomic, readonly) NSUInteger startIndex;
@property (nonatomic, readonly) NSUInteger endIndex;

#pragma mark Checking Text Positions

- (BOOL)containsTextPosition:(NKTTextPosition *)textPosition;

@end
