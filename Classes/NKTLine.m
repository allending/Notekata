//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTLine.h"

@interface NKTLine()

#pragma mark -
#pragma mark Accessing the Underlying Line

@property (nonatomic, readonly) CTLineRef line;

@end

@implementation NKTLine

@synthesize line;

#pragma mark -
#pragma mark Initializing

- (id)initWithTypesetter:(CTTypesetterRef)typesetter text:(NSAttributedString *)text range:(NSRange)range {
    if ((self = [super init])) {
        CFRange adaptedRange = CFRangeMake(range.location, range.length);
        line = CTTypesetterCreateLine(typesetter, adaptedRange);
    }
    
    return self;
}

- (void)dealloc {
    CFRelease(line);
    [super dealloc];
}

#pragma mark -
#pragma mark Getting Line Metrics

- (CGFloat)descent {
    float ascent, descent, leading;
    CTLineGetTypographicBounds(self.line, &ascent, &descent, &leading);
    return descent;
}

#pragma mark -
#pragma mark Drawing

- (void)drawInContext:(CGContextRef)context {
    CTLineDraw(self.line, context);
}

@end
