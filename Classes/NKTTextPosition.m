//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTTextPosition.h"
#import "NKTTextRange.h"

@implementation NKTTextPosition

@synthesize index;

#pragma mark -
#pragma mark Initializing

- (id)initWithIndex:(NSUInteger)theIndex {
    if ((self = [super init])) {
        index = theIndex;
    }
    
    return self;
}

+ (id)textPositionWithIndex:(NSUInteger)index {
    return [[[self alloc] initWithIndex:index] autorelease];
}

#pragma mark -
#pragma mark Creating Text Ranges

- (NKTTextRange *)emptyTextRange {
    return [NKTTextRange textRangeWithNSRange:NSMakeRange(self.index, 0)];
}

@end
