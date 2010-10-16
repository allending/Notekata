//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KobaUI.h"
#import "KobaText.h"
#import "NKTLine.h"

@class NKTTextPosition;
@class NKTTextRange;

// NKTFramesetter manages the typesetting of stylized text within a rectangular frame. It provides
// support for efficient updates of the text frame, hit-testing, and drawing.
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

// Returns the size of the text frame based on the number of typeset lines.
@property (nonatomic, readonly) CGSize frameSize;

#pragma mark Accessing Lines

@property (nonatomic, readonly) NSUInteger numberOfLines;

- (NKTLine *)lineAtIndex:(NSUInteger)lineIndex;
- (NKTLine *)firstLine;
- (NKTLine *)lastLine;

#pragma mark Updating the Framesetter

// Call this method to make the framesetter invalidate and typeset portions of the text that have
// changed.
- (void)textChangedFromTextPosition:(NKTTextPosition *)textPosition;

#pragma mark Hit-Testing and Geometry

- (NKTLine *)lineClosestToPoint:(CGPoint)point;
- (NKTTextPosition *)closestTextPositionForCaretToPoint:(CGPoint)point;
- (NKTLine *)lineForCaretAtTextPosition:(NKTTextPosition *)textPosition;
- (CGPoint)baselineOriginForCharAtTextPosition:(NKTTextPosition *)textPosition;

- (CGRect)firstRectForTextRange:(NKTTextRange *)textRange;
- (CGRect)lastRectForTextRange:(NKTTextRange *)textRange;
- (NSArray *)rectsForTextRange:(NKTTextRange *)textRange transform:(CGAffineTransform)transform;

#pragma mark Drawing

// Draws the given range of lines. The framesetter expects the CTM to be set up with the
// framesetter's space when this method is called.
- (void)drawLinesInRange:(NSRange)range inContext:(CGContextRef)context;

@end
