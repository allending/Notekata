//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTTextFrame.h"
#import "NKTLine.h"

@interface NKTTextFrame()

#pragma mark -
#pragma mark Typesetting

@property (nonatomic, readonly) CTTypesetterRef typesetter;
@property (nonatomic, readonly) NSArray *lines;

- (void)createLines;

@end

@implementation NKTTextFrame

@synthesize text;
@synthesize lineWidth;
@synthesize lineHeight;

@synthesize typesetter;
@synthesize lines;

#pragma mark -
#pragma mark Initializing

- (id)initWithText:(NSAttributedString *)theText lineWidth:(CGFloat)theLineWidth lineHeight:(CGFloat)theLineHeight {
    if ((self = [super init])) {
        // TODO: should really copy text?
        text = [theText copy];
        lineWidth = theLineWidth;
        lineHeight = theLineHeight;
        typesetter = CTTypesetterCreateWithAttributedString((CFAttributedStringRef)text);
        [self createLines];
    }
    
    return self;
}

- (void)dealloc {
    [text release];
    
    if (typesetter != NULL) {
        CFRelease(typesetter);
    }

    [lines release];
    [super dealloc];
}

#pragma mark -
#pragma mark Typesetting

- (void)createLines {
    NSMutableArray *theLines = [[NSMutableArray alloc] init];
    CFIndex length = (CFIndex)[self.text length];
    CFIndex charIndex = 0;
    
    while (charIndex < length) {
        CFIndex charCount = CTTypesetterSuggestLineBreak(self.typesetter, charIndex, self.lineWidth);
        NSRange range = NSMakeRange(charIndex, charCount);
        NKTLine *line = [[NKTLine alloc] initWithTypesetter:self.typesetter text:self.text range:range];
        [theLines addObject:line];
        [line release];
        charIndex += charCount;
    }
    
    lines = theLines;
}

#pragma mark -
#pragma mark Getting Frame Metrics

- (CGFloat)suggestedFrameHeight {
    NSUInteger count = [self.lines count];
    CGFloat height = (count + 1) * self.lineHeight;
    return height;
}

#pragma mark -
#pragma mark Drawing

- (void)drawInContext:(CGContextRef)context {
    if ([self.text length] == 0) {
        return;
    }
    
    CGFloat baseline = 0.0;
    
    for (NKTLine *line in self.lines) {
        CGContextSetTextPosition(context, 0.0, baseline);
        [line drawInContext:context];
        baseline -= self.lineHeight;
    }
}

@end
