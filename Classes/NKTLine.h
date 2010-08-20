//===================================================================================================
//
// Copyright 2010 Allen Ding. All rights reserved.
//
//===================================================================================================

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

@class NKTTextRange;
@class NKTTextPosition;

//===================================================================================================
// NKTLine represents a typesetted line that renders a range of text.
//===================================================================================================

@interface NKTLine : NSObject {
@private
    CTLineRef ctLine;
}

#pragma mark -
#pragma mark Initializing

- (id)initWithCTLine:(CTLineRef)ctLine;

#pragma mark -
#pragma mark Accessing the CTLine

@property (nonatomic, readonly) CTLineRef ctLine;

#pragma mark -
#pragma mark Accessing the Text Range

@property (nonatomic, readonly) NKTTextRange *textRange;

#pragma mark -
#pragma mark Getting Typographic Bounds

@property (nonatomic, readonly) CGFloat ascent;
@property (nonatomic, readonly) CGFloat descent;
@property (nonatomic, readonly) CGFloat leading;

#pragma mark -
#pragma mark Getting Offsets

- (CGFloat)offsetForTextPosition:(NKTTextPosition *)textPosition;

#pragma mark -
#pragma mark Hit Testing

- (NKTTextPosition *)closestTextPositionToPoint:(CGPoint)point;

#pragma mark -
#pragma mark Drawing

- (void)drawInContext:(CGContextRef)context;

@end
