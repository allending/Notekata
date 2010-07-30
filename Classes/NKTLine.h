//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

@interface NKTLine : NSObject {

}

#pragma mark -
#pragma mark Initializing

- (id)initWithTypesetter:(CTTypesetterRef)typesetter text:(NSAttributedString *)text range:(NSRange)range;

#pragma mark -
#pragma mark Getting Line Metrics

@property (nonatomic, readonly) CGFloat descent;

#pragma mark -
#pragma mark Drawing

- (void)drawInContext:(CGContextRef)context;

@end
