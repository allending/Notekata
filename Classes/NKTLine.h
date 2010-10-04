//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaUI.h"
#import "KobaText.h"

@class NKTTextRange;
@class NKTTextPosition;

@protocol NKTLineDelegate;

// NKTLine represents a typesetted line that renders a range of text.
//
@interface NKTLine : NSObject
{
@private
    id <NKTLineDelegate> delegate_;
    NSUInteger index_;
    NSRange range_;
    CGPoint origin_;
    CGFloat width_;
    CGFloat height_;
    CTLineRef line_;
}

#pragma mark Initializing

- (id)initWithDelegate:(id <NKTLineDelegate>)delegate
                 index:(NSUInteger)index
                 range:(NSRange)range
                origin:(CGPoint)origin
                 width:(CGFloat)width
                height:(CGFloat)height;

#pragma mark Accessing the Index

@property (nonatomic, readonly) NSUInteger index;

#pragma mark Accessing the Text Range

@property (nonatomic, readonly) NSRange range;
@property (nonatomic, readonly) NKTTextRange *textRange;

#pragma mark Line Geometry

@property (nonatomic, readonly) CGPoint origin;
@property (nonatomic, readonly) CGRect rect;

- (CGRect)rectFromTextPosition:(NKTTextPosition *)fromTextPosition toTextPosition:(NKTTextPosition *)toTextPosition;
- (CGRect)rectFromTextPosition:(NKTTextPosition *)textPosition;
- (CGRect)rectToTextPosition:(NKTTextPosition *)textPosition;

#pragma mark Getting Line Typographic Information

@property (nonatomic, readonly) CGFloat ascent;
@property (nonatomic, readonly) CGFloat descent;
@property (nonatomic, readonly) CGFloat leading;

#pragma mark Getting Character Offsets

- (CGFloat)offsetForCharAtTextPosition:(NKTTextPosition *)textPosition;

#pragma mark Hit-Testing

- (NKTTextPosition *)closestTextPositionToPoint:(CGPoint)point;

#pragma mark Drawing

- (void)drawInContext:(CGContextRef)context;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------

// NKTLineDelegate
//
@protocol NKTLineDelegate

#pragma mark Getting the Typesetter

@property (nonatomic, readonly) CTTypesetterRef typesetter;

@end
