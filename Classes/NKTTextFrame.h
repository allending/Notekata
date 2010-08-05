//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

@interface NKTTextFrame : NSObject {
@private
    NSAttributedString *text;
    
    CGFloat lineWidth;
    CGFloat lineHeight;
    
    CTTypesetterRef typesetter;
    NSArray* lines;
}

#pragma mark -
#pragma mark Initializing

- (id)initWithText:(NSAttributedString *)text lineWidth:(CGFloat)lineWidth lineHeight:(CGFloat)lineHeight;

#pragma mark -
#pragma mark Accessing Text Frame Attributes

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
