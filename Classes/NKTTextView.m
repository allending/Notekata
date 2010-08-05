//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTTextView.h"
#import "NKTTextViewCore.h"
#import <CoreText/CoreText.h>

@interface NKTTextView()

#pragma mark -
#pragma mark Accessing the Text View Core

@property (nonatomic, readonly) NKTTextViewCore *textViewCore;

#pragma mark -
#pragma mark Updating View Sizes

- (void)updateTextViewCoreSize;
- (void)updateContentSize;

@end

@implementation NKTTextView

@synthesize textViewCore;

#pragma mark -
#pragma mark Initializing

- (void)createTextViewCore {
    textViewCore = [[NKTTextViewCore alloc] initWithFrame:self.bounds];
    [self addSubview:textViewCore];
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self createTextViewCore];
        self.alwaysBounceVertical = YES;
    }
    
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self createTextViewCore];
    self.alwaysBounceVertical = YES;
}

- (void)dealloc {
    [textViewCore release];
    [super dealloc];
}

#pragma mark -
#pragma mark Updating View Sizes

- (void)updateTextViewCoreSize {
    CGRect frame = self.textViewCore.frame;
    frame.size = self.textViewCore.suggestedFrameSize;
    self.textViewCore.frame = frame;
}

- (void)updateContentSize {
    self.contentSize = self.textViewCore.frame.size;
}
#pragma mark -
#pragma mark Modifying View Bounds

- (void)setFrame:(CGRect)newFrame {
    CGRect previousFrame = self.frame;
    [super setFrame:newFrame];
    
    if (previousFrame.size.width != newFrame.size.width) {
        self.textViewCore.contentWidth = newFrame.size.width;
        [self updateTextViewCoreSize];
        [self updateContentSize];
    }
}

- (void)setBounds:(CGRect)newBounds {
    CGRect previousBounds = self.bounds;
    [super setBounds:newBounds];
    
    if (previousBounds.size.width != newBounds.size.width) {
        self.textViewCore.contentWidth = newBounds.size.width;
        [self updateTextViewCoreSize];
        [self updateContentSize];
    }
}

#pragma mark -
#pragma mark Accessing Text

- (NSAttributedString *)text {
    return self.textViewCore.text;
}

- (void)setText:(NSAttributedString *)text {
    self.textViewCore.text = text;
    [self updateTextViewCoreSize];
    [self updateContentSize];
}

#pragma mark -
#pragma mark Configuring Text Layout

- (CGFloat)lineHeight {
    return self.textViewCore.lineHeight;
}

- (void)setLineHeight:(CGFloat)lineHeight {
    self.textViewCore.lineHeight = lineHeight;
    [self updateTextViewCoreSize];
    [self updateContentSize];
}

- (UIEdgeInsets)margins {
    return self.textViewCore.margins;
}

- (void)setMargins:(UIEdgeInsets)margins {
    self.textViewCore.margins = margins;
    [self updateTextViewCoreSize];
    [self updateContentSize];
}

@end
