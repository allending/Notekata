//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTFramesetter.h"
#import "NKTLine.h"
#import "NKTTextPosition.h"
#import "NKTTextRange.h"

@interface NKTFramesetter()

#pragma mark Managing the Typesetter

- (void)invalidateTypesetter;

#pragma mark Managing Lines

@property (nonatomic, readonly) NSArray *lines;

- (void)typesetLinesFromIndex:(NSUInteger)lineIndex;

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
        NSUInteger lineLength = (NSUInteger)CTTypesetterSuggestLineBreak(self.typesetter, currentLocation, lineWidth_);
        NKTLine *line = [[NKTLine alloc] initWithDelegate:self
                                                    index:currentLineIndex
                                                    range:NSMakeRange(currentLocation, lineLength)
                                                   origin:lineOrigin
                                                    width:lineWidth_
                                                   height:lineHeight_];
        [lines_ addObject:line];
        [line release];
        ++currentLineIndex;
        currentLocation += lineLength;
        lineOrigin.y -= lineHeight_;
    }
    
    // Add a sentinel line if the text ends with a line break or if the text is empty
    if ([[text_ string] isLastCharacterNewline] || [text_ length] == 0)
    {
        NKTLine *sentinel = [[NKTLine alloc] initWithDelegate:self
                                                        index:[lines_ count]
                                                        range:NSMakeRange([text_ length], 0)
                                                       origin:lineOrigin
                                                        width:lineWidth_
                                                       height:lineHeight_];
        [lines_ addObject:sentinel];
        [sentinel release];
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
    return [self.lines objectAtIndex:lineIndex];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Converting Coordinates

- (CGPoint)convertPoint:(CGPoint)point toLine:(NKTLine *)line
{
    return CGPointMake(point.x - line.origin.x, point.y - line.origin.y);
}

//--------------------------------------------------------------------------------------------------

#pragma mark Hit-Testing and Geometry

- (NKTLine *)lineClosestToPoint:(CGPoint)point
{
    NSInteger lineIndex = (NSInteger)floor(point.y / lineHeight_);
    
    if (lineIndex < 0)
    {
        lineIndex = 0;
    }
    else if (lineIndex > self.numberOfLines)
    {
        lineIndex = self.numberOfLines - 1;
    }
    
    return [self.lines objectAtIndex:lineIndex];
}

//*********************************************
// TODO: refine semantics of method - use affinity param?
//*********************************************
- (NKTLine *)lineContainingTextPosition:(NKTTextPosition *)textPosition
{
    for (NKTLine *line in self.lines)
    {
        if ([line.textRange containsTextPosition:textPosition] ||
            [line.textRange isEqualToTextPosition:textPosition])
        {
            return line;
        }
    }
    
    KBCLogWarning(@"could not find line containing text position %@, returning nil", textPosition);
    return nil;
}

- (NKTTextPosition *)textPositionLogicallyClosestToPoint:(CGPoint)point
{
    NSInteger lineIndex = (NSInteger)floor(point.y / lineHeight_);
    
    if (lineIndex < 0)
    {
        return [NKTTextPosition textPositionWithLocation:0];
    }
    else if (lineIndex > self.numberOfLines)
    {
        return [NKTTextPosition textPositionWithLocation:[text_ length] - 1];
    }

    NKTLine *line = [self.lines objectAtIndex:lineIndex];
    CGPoint linePoint = [self convertPoint:point toLine:line];
    return [line closestTextPositionToPoint:linePoint];
}

- (NKTTextPosition *)textPositionGeometricallyClosestToPoint:(CGPoint)point
{
    NKTLine *line = [self lineClosestToPoint:point];
    CGPoint linePoint = [self convertPoint:point toLine:line];
    return [line closestTextPositionToPoint:linePoint];
}

- (CGPoint)originForCharAtTextPosition:(NKTTextPosition *)textPosition
{
    NKTLine *line = [self lineContainingTextPosition:textPosition];
    CGFloat charOffset = [line offsetForCharAtTextPosition:textPosition];
    return CGPointMake(line.origin.x + charOffset, line.origin.y);
}

- (NSArray *)rectsForTextRange:(NKTTextRange *)textRange
{
    NKTLine *firstLine = [self lineContainingTextPosition:textRange.start];
    NKTLine *lastLine = [self lineContainingTextPosition:textRange.end];
    
    // Single rect
    if (firstLine == lastLine)
    {
        CGRect lineRect = [firstLine rectFromTextPosition:textRange.start toTextPosition:textRange.end];
        return [NSArray arrayWithObject:[NSValue valueWithCGRect:lineRect]];
    }
    // Dealing with multiple lines
    else
    {
        NSMutableArray *rects = [NSMutableArray arrayWithCapacity:lastLine.index - firstLine.index];
        CGRect firstLineRect = [firstLine rectFromTextPosition:textRange.start];
        [rects addObject:[NSValue valueWithCGRect:firstLineRect]];
        
        for (NSUInteger lineIndex = firstLine.index; lineIndex < lastLine.index; ++lineIndex)
        {
            NKTLine *line = [self.lines objectAtIndex:lineIndex];
            CGRect lineRect = [line rect];
            [rects addObject:[NSValue valueWithCGRect:lineRect]];
        }
        
        CGRect lastLineRect = [lastLine rectToTextPosition:textRange.end];
        [rects addObject:[NSValue valueWithCGRect:lastLineRect]];
        return rects;
    }
}

//--------------------------------------------------------------------------------------------------

#pragma mark Drawing

- (void)drawLinesInRange:(NSRange)range inContext:(CGContextRef)context
{    
    CGFloat baselineOffset = -lineHeight_ * (CGFloat)range.location;
    
    for (NSUInteger lineIndex = range.location; lineIndex < NSMaxRange(range); ++lineIndex)
    {
        CGContextSetTextPosition(context, 0.0, baselineOffset);
        NKTLine *line = [self.lines objectAtIndex:lineIndex];
        [line drawInContext:context];
        baselineOffset -= lineHeight_;
    }
}

@end
