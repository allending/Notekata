//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTFramesetter.h"
#import "NKTLine.h"

@interface NKTFramesetter()

#pragma mark Managing the Typesetter

- (void)invalidateTypesetter;

#pragma mark Managing Lines

@property (nonatomic, readonly) NSArray *lines;

- (void)typesetLinesFromIndex:(NSUInteger)lineIndex;

#pragma mark Hit-Testing and Geometry

- (CGPoint)originForLineAtIndex:(NSUInteger)lineIndex;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------

@implementation NKTFramesetter

#pragma mark Initializing

- (id)initWithText:(NSAttributedString *)text lineWidth:(CGFloat)lineWidth lineHeight:(CGFloat)lineHeight
{
    if ((self = [super init]))
    {
        text_ = [text retain];
        lineWidth_ = lineWidth;
        lineHeight_ = lineHeight;
    }
    
    return self;
}

- (void)dealloc
{
    [text_ release];
    
    if (typesetter_ != NULL)
    {
        CFRelease(typesetter_);
    }
    
    [lines_ release];
    [super dealloc];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Managing the Typesetter

- (CTTypesetterRef)typesetter
{
    if (typesetter_ == NULL)
    {
        typesetter_ = CTTypesetterCreateWithAttributedString((CFAttributedStringRef)text_);
    }
    
    return typesetter_;
}

- (void)invalidateTypesetter
{
    if (typesetter_ != NULL)
    {
        CFRelease(typesetter_);
        typesetter_ = NULL;
    }
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting the Frame Size

- (CGSize)frameSize
{
    CGFloat height = lineHeight_ * (CGFloat)self.numberOfLines;
    return CGSizeMake(lineWidth_, height);
}

//--------------------------------------------------------------------------------------------------

#pragma mark Notifying the Framesetter of Changes

- (void)textChangedFromTextPosition:(NKTTextPosition *)textPosition
{
    [self invalidateTypesetter];
    NKTLine *line = [self lineContainingTextPosition:textPosition];
    [self typesetLinesFromIndex:line.index];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Managing Lines

- (void)typesetLinesFromIndex:(NSUInteger)lineIndex
{
    if (lineIndex > [lines_ count])
    {
        KBCLogWarning(@"line index %d is greater than the number of lines %d, ignoring", lineIndex, [lines_ count]);
        return;
    }
    
    // Get the line index, start location, and origin of the first line that will be typeset
    NSUInteger currentLineIndex = lineIndex;
    NSUInteger currentLocation;
    CGPoint lineOrigin;
    
    if ([lines_ count] == 0)
    {
        currentLocation = 0;
        lineOrigin = CGPointMake(0.0, -lineHeight_);
    }
    else
    {
        // Can reuse existing information
        NKTLine *line = [lines_ objectAtIndex:currentLineIndex];
        currentLocation = line.range.location;
        lineOrigin = line.origin;
    }
    
    // Remove lines that will be retypeset
    [lines_ removeObjectsInRange:NSMakeRange(lineIndex, [lines_ count] - lineIndex)];
    
    // Typeset until end of text
    while (currentLocation < [text_ length])
    {
        CFIndex lineLength = CTTypesetterSuggestLineBreak(self.typesetter, currentLocation, lineWidth_);
        NKTLine *line = [[NKTLine alloc] initWithDelegate:self
                                                    index:currentLineIndex
                                                    range:NSMakeRange((NSUInteger)currentLocation,
                                                                      (NSUInteger)lineLength)
                                                   origin:lineOrigin];
        [lines_ addObject:line];
        [line release];
        ++currentLineIndex;
        currentLocation += lineLength;
        lineOrigin.y -= lineHeight_;
    }
    
    // Add a sentinel line if the text ends with a line break or if the text is empty
    if ([[text_ string] isLastCharacterLineBreak] || [text_ length] == 0)
    {
        NKTLine *sentinelLine = [[NKTLine alloc] initWithDelegate:self
                                                            index:[lines_ count]
                                                            range:NSMakeRange([text_ length], 0)
                                                           origin:lineOrigin];
        [lines_ addObject:sentinelLine];
        [sentinelLine release];
    }
}

- (NSArray *)lines
{
    if (lines_ == nil)
    {
        lines_ = [[NSMutableArray alloc] init];
        [self typesetLinesFromIndex:0];
    }
    
    return lines_;
}

- (NSUInteger)numberOfLines
{
    return [self.lines count];
}

- (NKTLine *)lineAtIndex:(NSUInteger)lineIndex
{
    return [lines_ objectAtIndex:lineIndex];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Hit-Testing and Geometry

- (CGPoint)originForLineAtIndex:(NSUInteger)lineIndex
{
    return CGPointMake(0.0, lineHeight_ * (CGFloat)lineIndex);
}

@end
