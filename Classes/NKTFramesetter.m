//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTFramesetter.h"
#import <CoreText/CoreText.h>
#import "NKTLine.h"

@interface NKTFramesetter()

#pragma mark -
#pragma mark Typesetting

@property (nonatomic, readonly) CTTypesetterRef typesetter;
@property (nonatomic, readonly) NSArray *lines;

- (void)createLines;

@end

@implementation NKTFramesetter

@synthesize text;
@synthesize lineWidth;
@synthesize lineHeight;
@synthesize lines;
@synthesize typesetter;

#pragma mark -
#pragma mark Initializing

- (id)initWithText:(NSAttributedString *)theText lineWidth:(CGFloat)theLineWidth lineHeight:(CGFloat)theLineHeight {
    if ((self = [super init])) {
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
    NSMutableArray *mutableLines = [[NSMutableArray alloc] init];
    lines = mutableLines;
    
    CFIndex length = (CFIndex)[self.text length];
    CFIndex charIndex = 0;
    
    while (charIndex < length) {
        CFIndex lineCharCount = CTTypesetterSuggestLineBreak(self.typesetter, charIndex, self.lineWidth);
        NKTLine *line = [[NKTLine alloc] initWithTypesetter:self.typesetter text:self.text range:NSMakeRange(charIndex, lineCharCount)];
        [mutableLines addObject:line];
        [line release];
        charIndex += lineCharCount;
    }
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
    
    CGFloat baselineY = 0.0;
    
    for (NKTLine *line in self.lines) {
        CGContextSetTextPosition(context, 0.0, baselineY);
        [line drawInContext:context];
        baselineY -= self.lineHeight;
    }
}

@end
