//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaUI.h"
#import "KobaText.h"
#import "NKTLine.h"

@class NKTTextPosition;
@class NKTTextRange;

// NKTFramesetter
//
@interface NKTFramesetter : NSObject <NKTLineDelegate>
{
@private
    NSAttributedString *text_;
    CGFloat lineWidth_;
    CGFloat lineHeight_;
    CTTypesetterRef typesetter_;
    NSMutableArray *lines_;
}

#pragma mark Initializing

- (id)initWithText:(NSAttributedString *)text lineWidth:(CGFloat)lineWidth lineHeight:(CGFloat)lineHeight;

#pragma mark Getting the Frame Size

@property (nonatomic, readonly) CGSize frameSize;

#pragma mark Notifying the Framesetter of Changes

- (void)textChangedFromTextPosition:(NKTTextPosition *)textPosition;

#pragma mark Managing Lines

@property (nonatomic, readonly) NSUInteger numberOfLines;

- (NKTLine *)lineAtIndex:(NSUInteger)lineIndex;

#pragma mark Converting Coordinates

- (CGPoint)convertPoint:(CGPoint)point toLine:(NKTLine *)line;

#pragma mark Hit-Testing and Geometry

- (NKTLine *)lineClosestToPoint:(CGPoint)point;
- (NKTLine *)lineContainingTextPosition:(NKTTextPosition *)textPosition;
- (NKTTextPosition *)textPositionLogicallyClosestToPoint:(CGPoint)point;
- (NKTTextPosition *)textPositionGeometricallyClosestToPoint:(CGPoint)point;
- (CGPoint)originForCharAtTextPosition:(NKTTextPosition *)textPosition;
- (NSArray *)rectsForTextRange:(NKTTextRange *)textRange;

@end
