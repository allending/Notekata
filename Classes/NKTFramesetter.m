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
    
    // TODO: guarantee at least one typeset line .. sentinel is pointless if it isn't always
    // there
    //
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

- (NKTLine *)firstLine
{
    return [self.lines objectAtIndex:0];
}

- (NKTLine *)lastLine
{
    return [self.lines objectAtIndex:self.numberOfLines - 1];
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

// TODO: potential affinity semantic
//
// need to have a semantic that means 'line that text position appears on, possibly with affinity option'
- (NKTLine *)lineContainingTextPosition:(NKTTextPosition *)textPosition
{
    return [self lineContainingTextPosition:textPosition affinity:UITextStorageDirectionForward];
}

// TODO: potential affinity semantic
// who uses this method
// rename this to line appearing to contain text position
// ...
// need to have a semantic that means 'line that text position appears on, possibly with affinity option'
- (NKTLine *)lineContainingTextPosition:(NKTTextPosition *)textPosition affinity:(UITextStorageDirection)affinity
{
    NKTLine *lineContainingTextPosition = nil;
    
    for (NKTLine *line in self.lines)
    {
        if ([line.textRange containsTextPosition:textPosition] || [line.textRange isEqualToTextPosition:textPosition])
        {   
            lineContainingTextPosition = line;
        }
    }
    
    // do stuff
    if ((affinity == UITextStorageDirectionBackward) &&
        [textPosition isEqualToTextPosition:lineContainingTextPosition.textRange.start])
    {
        // use previous line if available
    }
    
    KBCLogWarning(@"could not find line containing text position %@, returning nil", textPosition);
    return nil;
}

// TODO: potential affinity semantic
- (CGPoint)originForCharAtTextPosition:(NKTTextPosition *)textPosition affinity:(UITextStorageDirection)affinity
{
    NKTLine *line = [self lineContainingTextPosition:textPosition affinity:affinity];
    CGFloat charOffset = [line offsetForCharAtTextPosition:textPosition];
    return CGPointMake(line.origin.x + charOffset, line.origin.y);
}

// TODO: potential affinity semantic
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

- (NKTTextPosition *)closestLogicalTextPositionToPoint:(CGPoint)point affinity:(UITextStorageDirection *)affinity
{
    if (affinity != NULL)
    {
        *affinity = UITextStorageDirectionForward;
    }
    
    NSInteger lineIndex = (NSInteger)floor(point.y / lineHeight_);
    
    if (lineIndex < 0)
    {
        return [NKTTextPosition textPositionWithLocation:0];
    }
    else if (lineIndex > self.numberOfLines)
    {
        if (affinity != NULL)
        {
            *affinity = UITextStorageDirectionForward;
        }
        
        return [NKTTextPosition textPositionWithLocation:[text_ length] - 1];
    }
    
    NKTLine *line = [self.lines objectAtIndex:lineIndex];
    CGPoint linePoint = [self convertPoint:point toLine:line];
    NKTTextPosition *textPosition = [line closestTextPositionToPoint:linePoint];
    
    if (affinity != NULL && [textPosition isEqualToTextPosition:line.textRange.end])
    {
        *affinity = UITextStorageDirectionBackward;
    }
    
    return textPosition;
}

- (NKTTextPosition *)closestGeometricTextPositionToPoint:(CGPoint)point affinity:(UITextStorageDirection *)affinity
{
    if (affinity != NULL)
    {
        *affinity = UITextStorageDirectionForward;
    }
    
    NKTLine *line = [self lineClosestToPoint:point];
    CGPoint linePoint = [self convertPoint:point toLine:line];
    NKTTextPosition *textPosition = [line closestTextPositionToPoint:linePoint];
    
    if (affinity != NULL && [textPosition isEqualToTextPosition:line.textRange.end])
    {
        *affinity = UITextStorageDirectionBackward;
    }
    
    return textPosition;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Drawing

// Draws the given range of lines. The framesetter expects the CTM to be set up with the
// framesetter's space when this method is called.
//
- (void)drawLinesInRange:(NSRange)range inContext:(CGContextRef)context
{
    // The framesetter's origin is at the top left of the text frame it manages. The first line's
    // baseline is one line height below the top of this text frame.
    
    CGFloat currentBaseline = -lineHeight_ * (CGFloat)(range.location + 1);
    
    for (NSUInteger lineIndex = range.location; lineIndex < NSMaxRange(range); ++lineIndex)
    {
        CGContextSetTextPosition(context, 0.0, currentBaseline);
        NKTLine *line = [self.lines objectAtIndex:lineIndex];
        [line drawInContext:context];
        currentBaseline -= lineHeight_;
    }
}

@end
