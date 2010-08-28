//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

@class NKTTextRange;
@class NKTTextPosition;

//--------------------------------------------------------------------------------------------------
// NKTLine represents a typesetted line that renders a range of text.
//--------------------------------------------------------------------------------------------------

@interface NKTLine : NSObject
{
@private
    NSUInteger index;
    NSAttributedString *text;
    CTLineRef ctLine;
}

#pragma mark Initializing

- (id)initWithIndex:(NSUInteger)index text:(NSAttributedString *)text CTLine:(CTLineRef)ctLine;

#pragma mark Accessing Line Information

@property (nonatomic, readonly) NSUInteger index;

#pragma mark Getting Text Ranges

@property (nonatomic, readonly) NKTTextRange *textRange;

#pragma mark Getting Typographic Bounds

@property (nonatomic, readonly) CGFloat ascent;
@property (nonatomic, readonly) CGFloat descent;
@property (nonatomic, readonly) CGFloat leading;

#pragma mark Getting Offsets

- (CGFloat)offsetForCharAtTextPosition:(NKTTextPosition *)textPosition;

#pragma mark Hit Testing

// Returns a text position usable for the next character to be inserted on the line. Relative to
// the line's text range, the index of the text position returned will be no less than the start
// index and no more than the last string index plus 1.
//
// If the last character on the line is a line break, the text position returned will no more than
// the last string index. This is so that insertions using the returned text position can be used
// to insert text on the same line before the line break.
- (NKTTextPosition *)closestTextPositionToPoint:(CGPoint)point;

#pragma mark Drawing

- (void)drawInContext:(CGContextRef)context;

@end
