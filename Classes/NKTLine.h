//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

@class NKTTextRange;
@class NKTTextPosition;

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

- (CGFloat)ascent;
- (CGFloat)descent;
- (CGFloat)leading;

#pragma mark -
#pragma mark Getting Line Positioning

- (CGFloat)offsetForTextAtIndex:(NSUInteger)index;
- (NKTTextPosition *)closestTextPositionToPoint:(CGPoint)point;

#pragma mark -
#pragma mark Drawing

- (void)drawInContext:(CGContextRef)context;

@end
