//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NKTTextPosition;

@interface NKTTextRange : UITextRange {
@private
    NSRange nsRange;
}

#pragma mark -
#pragma mark Initializing

- (id)initWithNSRange:(NSRange)nsRange;

+ (id)textRangeWithNSRange:(NSRange)nsRange;

#pragma mark -
#pragma mark Accessing the Range

@property (nonatomic, readonly) NSRange nsRange;

#pragma mark -
#pragma mark Accessing Range Indices

@property (nonatomic, readonly) NSUInteger startIndex;
@property (nonatomic, readonly) NSUInteger endIndex;

#pragma mark -
#pragma mark Checking Text Positions

- (BOOL)containsTextPosition:(NKTTextPosition *)textPosition;

@end
