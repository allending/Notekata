//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

@interface NKTLine : NSObject {

}

#pragma mark -
#pragma mark Initializing

- (id)initWithCTLine:(CTLineRef)ctLine;

#pragma mark -
#pragma mark Drawing

- (void)drawInContext:(CGContextRef)context;

@end
