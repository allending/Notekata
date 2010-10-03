//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaUI.h"
#import "KobaText.h"

@class NKTTextRange;
@class NKTTextPosition;

//--------------------------------------------------------------------------------------------------
// NKTLine represents a typesetted line that renders a range of text.
//--------------------------------------------------------------------------------------------------

@interface NKTLine : NSObject
{
@private
    NSUInteger index_;
    NSAttributedString *text_;
    CTLineRef ctLine_;
    CGPoint origin_;
}

#pragma mark Initializing

// Initializes the NKTLine with the given Core Text line. If the Core Text line is NULL, the text
// range for the line will be the empty range at the end of the text.
- (id)initWithIndex:(NSUInteger)index text:(NSAttributedString *)text ctLine:(CTLineRef)ctLine origin:(CGPoint)origin;

#pragma mark Accessing the Index

@property (nonatomic, readonly) NSUInteger index;

#pragma mark Accessing the Text

@property (nonatomic, readonly) NSString *lineText;

#pragma mark Getting Text Ranges

@property (nonatomic, readonly) NKTTextRange *textRange;

#pragma mark Getting Line Geometry

@property (nonatomic, readonly) CGPoint origin;
@property (nonatomic, readonly) CGFloat ascent;
@property (nonatomic, readonly) CGFloat descent;
@property (nonatomic, readonly) CGFloat leading;

#pragma mark Getting Offsets

- (CGFloat)offsetForCharAtTextPosition:(NKTTextPosition *)textPosition;

#pragma mark Hit Testing

// If the last character on the line is a line break, the text position returned will no more than
// the last string index. Insertions can be made using the returned text position can be used to
// insert text on the same line before the line break.
- (NKTTextPosition *)closestTextPositionToPoint:(CGPoint)point;

#pragma mark Drawing

- (void)drawInContext:(CGContextRef)context;

@end
