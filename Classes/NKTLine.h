//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KobaUI.h"
#import "KobaText.h"

@class NKTTextPosition;
@class NKTTextRange;

@protocol NKTLineDelegate;

// NKTLine represents a typesetted line that renders a range of text.
@interface NKTLine : NSObject
{
@private
    id <NKTLineDelegate> delegate_;
    NSUInteger index_;
    NSAttributedString *text_;
    NKTTextRange *textRange_;
    CGPoint baselineOrigin_;
    CGFloat width_;
    CGFloat height_;
    CTLineRef line_;
    BOOL lastLine_;
}

#pragma mark Initializing

- (id)initWithDelegate:(id <NKTLineDelegate>)delegate
                 index:(NSUInteger)index
                  text:(NSAttributedString *)text
             textRange:(NKTTextRange *)textRange
        baselineOrigin:(CGPoint)origin
                 width:(CGFloat)width
                height:(CGFloat)height
              lastLine:(BOOL)lastLine;

#pragma mark Accessing the Index

@property (nonatomic, readonly) NSUInteger index;

#pragma mark Accessing the Text Range

@property (nonatomic, readonly) NKTTextRange *textRange;

#pragma mark Line Geometry

@property (nonatomic, readonly) CGPoint baselineOrigin;

- (CGRect)rectForTextRange:(NKTTextRange *)textRange;

#pragma mark Getting Line Typographic Information

@property (nonatomic, readonly) CGFloat ascent;
@property (nonatomic, readonly) CGFloat descent;
@property (nonatomic, readonly) CGFloat leading;

#pragma mark Getting Character Positions

- (CGFloat)offsetForCharAtTextPosition:(NKTTextPosition *)textPosition;
- (CGPoint)baselineOriginForCharAtTextPosition:(NKTTextPosition *)textPosition;

#pragma mark Hit-Testing

// The point needs to be in the space of the line's parent.
- (NKTTextPosition *)closestTextPositionForCaretToPoint:(CGPoint)point;
- (BOOL)containsCaretAtTextPosition:(NKTTextPosition *)textPosition;

#pragma mark Drawing

- (void)drawInContext:(CGContextRef)context;

@end

#pragma mark -

// NKTLineDelegate
@protocol NKTLineDelegate

#pragma mark Getting the Typesetter

@property (nonatomic, readonly) CTTypesetterRef typesetter;

@end
