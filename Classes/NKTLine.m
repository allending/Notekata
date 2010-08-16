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

- (id)initWithCTLine:(CTLineRef)ctLine {
    if ((self = [super init])) {
        line = ctLine;
        
        if (line != NULL) {
            CFRetain(line);
        }
    }
    
    return self;
}

- (void)dealloc {
    if (line != NULL) {
        CFRelease(line);
    }

    [super dealloc];
}

#pragma mark -
#pragma mark Drawing

- (void)drawInContext:(CGContextRef)context {
    CTLineDraw(self.line, context);
}

@end
