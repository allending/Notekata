//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

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
    NSRange range_;
    CGPoint baselineOrigin_;
    CGFloat width_;
    CGFloat height_;
    CTLineRef line_;
}

#pragma mark Initializing

- (id)initWithDelegate:(id <NKTLineDelegate>)delegate
                 index:(NSUInteger)index
                  text:(NSAttributedString *)text
                 range:(NSRange)range
        baselineOrigin:(CGPoint)origin
                 width:(CGFloat)width
                height:(CGFloat)height;

#pragma mark Accessing the Index

@property (nonatomic, readonly) NSUInteger index;

#pragma mark Accessing the Text Range

@property (nonatomic, readonly) NSRange range;
@property (nonatomic, readonly) NKTTextRange *textRange;

#pragma mark Line Geometry

@property (nonatomic, readonly) CGPoint baselineOrigin;
@property (nonatomic, readonly) CGRect rect;

- (CGRect)rectFromTextPosition:(NKTTextPosition *)fromTextPosition toTextPosition:(NKTTextPosition *)toTextPosition;
- (CGRect)rectFromTextPosition:(NKTTextPosition *)textPosition;
- (CGRect)rectToTextPosition:(NKTTextPosition *)textPosition;

#pragma mark Getting Line Typographic Information

@property (nonatomic, readonly) CGFloat ascent;
@property (nonatomic, readonly) CGFloat descent;
@property (nonatomic, readonly) CGFloat leading;

#pragma mark Getting Character Positions

- (CGFloat)offsetForCharAtTextPosition:(NKTTextPosition *)textPosition;
- (CGPoint)baselineOriginForCharAtTextPosition:(NKTTextPosition *)textPosition;

#pragma mark Hit-Testing

// The line expects the point to be in the space of its parent.
- (NKTTextPosition *)closestTextPositionForCaretToPoint:(CGPoint)point;

#pragma mark Drawing

- (void)drawInContext:(CGContextRef)context;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------

// NKTLineDelegate
@protocol NKTLineDelegate

#pragma mark Getting the Typesetter

@property (nonatomic, readonly) CTTypesetterRef typesetter;

@end
