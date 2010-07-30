//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NKTFramesetter : NSObject {

}

#pragma mark -
#pragma mark Initializing

- (id)initWithText:(NSAttributedString *)text lineWidth:(CGFloat)lineWidth lineHeight:(CGFloat)lineHeight;

#pragma mark -
#pragma mark Accessing Frame Attributes

@property (nonatomic, readonly, copy) NSAttributedString *text;
@property (nonatomic, readonly) CGFloat lineWidth;
@property (nonatomic, readonly) CGFloat lineHeight;

#pragma mark -
#pragma mark Getting Frame Metrics

- (CGFloat)suggestedFrameHeight;

#pragma mark -
#pragma mark Drawing

- (void)drawInContext:(CGContextRef)context;

@end
