//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#define KBC_LOGGING_DISABLE_DEBUG_OUTPUT 1

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
    NKTLine *line = [self lineForCaretAtTextPosition:textPosition];
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
    NSUInteger currentLocation = 0;
    CGPoint currentLineBaselineOrigin = CGPointZero;
    
    // The framesetter's origin is at the top left of the text frame it manages. The first line's
    // baseline is one line height below the top of this text frame.
    
    if ([lines_ count] == 0)
    {
        currentLocation = 0;
        currentLineBaselineOrigin = CGPointMake(0.0, lineHeight_);
    }
    else
    {
        // Can reuse existing information
        NKTLine *line = [lines_ objectAtIndex:currentLineIndex];
        currentLocation = line.range.location;
        currentLineBaselineOrigin = line.baselineOrigin;
    }
    
    // Remove lines that will be retypeset
    [lines_ removeObjectsInRange:NSMakeRange(lineIndex, [lines_ count] - lineIndex)];
    
    // Typeset until end of text
    while (currentLocation < [text_ length])
    {        
        NSUInteger lineLength = (NSUInteger)CTTypesetterSuggestLineBreak(self.typesetter, currentLocation, lineWidth_);
        NKTLine *line = [[NKTLine alloc] initWithDelegate:self
                                                    index:currentLineIndex
                                                     text:text_
                                                    range:NSMakeRange(currentLocation, lineLength)
                                           baselineOrigin:currentLineBaselineOrigin
                                                    width:lineWidth_
                                                   height:lineHeight_];
        [lines_ addObject:line];
        KBCLogDebug(@"typesetted %@", line);
        [line release];
        ++currentLineIndex;
        currentLocation += lineLength;
        currentLineBaselineOrigin.y += lineHeight_;
    }
    
    // TODO: guarantee at least one typeset line .. sentinel is pointless if it isn't always
    // there
    //
    // Add a sentinel line if the text ends with a line break or if the text is empty
    if ([[text_ string] isLastCharacterNewline] || [text_ length] == 0)
    {
        NKTLine *sentinel = [[NKTLine alloc] initWithDelegate:self
                                                        index:[lines_ count]
                                                         text:text_
                                                        range:NSMakeRange([text_ length], 0)
                                                       baselineOrigin:currentLineBaselineOrigin
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

#pragma mark Hit-Testing and Geometry

- (NKTLine *)lineClosestToPoint:(CGPoint)point
{
    // Apply a 20% line height offset to the point to account for line descent and tune for user
    // interaction
    CGFloat virtualLinePointOffset = -lineHeight_ * 0.2;
    NSInteger lineIndex = (NSInteger)floor((point.y + virtualLinePointOffset) / lineHeight_);
    
    if (lineIndex < 0)
    {
        lineIndex = 0;
    }
    else if (lineIndex >= self.numberOfLines)
    {
        lineIndex = self.numberOfLines - 1;
    }
    
    return [self.lines objectAtIndex:lineIndex];
}

// TODO: desired behavior
// touch at end of a line
// - if line ends with a newline, text position is at end of line before newline
// - if line does not end with a newline, text position is end of line, which is also the start of the next line
//   
//
// TODO: tune for hit testing
- (NKTTextPosition *)closestTextPositionToPoint:(CGPoint)point
{
    // Apply a 20% line height offset to the point to account for line descent and tune for user
    // interaction
    CGFloat virtualLinePointOffset = -lineHeight_ * 0.2;
    NSInteger lineIndex = (NSInteger)floor((point.y + virtualLinePointOffset) / lineHeight_);
    
    if (lineIndex < 0)
    {
        return [NKTTextPosition textPositionWithLocation:0 affinity:UITextStorageDirectionForward];
    }
    else if (lineIndex >= self.numberOfLines)
    {
        return [NKTTextPosition textPositionWithLocation:[text_ length] affinity:UITextStorageDirectionForward];
    }
    
    NKTLine *line = [self.lines objectAtIndex:lineIndex];
    NKTTextPosition *textPosition = [line closestTextPositionToFramesetterPoint:point];
    return textPosition;
}

- (NKTLine *)lineForCaretAtTextPosition:(NKTTextPosition *)textPosition
{
    for (NKTLine *line in self.lines)
    {
        if ([line.textRange enclosesTextPosition:textPosition])
        {
            return line;
        }
    }
    
    // If no lines were found to contain the text position, then the line for the caret may be
    // the last line (happens when the end of the text is not a newline)
    NKTLine *lastLine = [self lastLine];
    
    if ([lastLine.textRange.end isEqualToTextPosition:textPosition])
    {
        return lastLine;
    }
    
    KBCLogWarning(@"no line contains %@", textPosition);
    return nil;
}

// TODO: potential affinity semantic
- (CGPoint)baselineOriginForCharAtTextPosition:(NKTTextPosition *)textPosition
{
    NKTLine *line = [self lineForCaretAtTextPosition:textPosition];
    // TODO: just ask line
    CGFloat charOffset = [line offsetForCharAtTextPosition:textPosition];
    return CGPointMake(line.baselineOrigin.x + charOffset, line.baselineOrigin.y);
}

- (NSArray *)rectsForTextRange:(NKTTextRange *)textRange
{
    return [self rectsForTextRange:textRange transform:CGAffineTransformIdentity];
}

// TODO: potential affinity semantic
- (NSArray *)rectsForTextRange:(NKTTextRange *)textRange transform:(CGAffineTransform)transform
{
    NKTLine *firstLine = [self lineForCaretAtTextPosition:textRange.start];
    NKTLine *lastLine = [self lineForCaretAtTextPosition:textRange.end];
    
    // Single rect
    if (firstLine == lastLine)
    {
        // TODO: what if this is the last line?
        CGRect lineRect = [firstLine rectFromTextPosition:textRange.start toTextPosition:textRange.end];
        lineRect = CGRectApplyAffineTransform(lineRect, transform);
        return [NSArray arrayWithObject:[NSValue valueWithCGRect:lineRect]];
    }
    // Dealing with multiple lines
    else
    {
        NSMutableArray *rects = [NSMutableArray arrayWithCapacity:lastLine.index - firstLine.index];
        CGRect firstLineRect = [firstLine rectFromTextPosition:textRange.start];
        firstLineRect = CGRectApplyAffineTransform(firstLineRect, transform);
        [rects addObject:[NSValue valueWithCGRect:firstLineRect]];
        
        for (NSUInteger lineIndex = firstLine.index; lineIndex < lastLine.index; ++lineIndex)
        {
            NKTLine *line = [self.lines objectAtIndex:lineIndex];
            CGRect lineRect = [line rect];
            lineRect = CGRectApplyAffineTransform(lineRect, transform);
            [rects addObject:[NSValue valueWithCGRect:lineRect]];
        }
        
        CGRect lastLineRect = [lastLine rectToTextPosition:textRange.end];
        lastLineRect = CGRectApplyAffineTransform(lastLineRect, transform);
        
        // Last line may be the null rect if the last line is empty
        if (!CGRectEqualToRect(lastLineRect, CGRectNull))
        {
            [rects addObject:[NSValue valueWithCGRect:lastLineRect]];
        }
        
        return rects;
    }
}

//--------------------------------------------------------------------------------------------------

#pragma mark Drawing

// Draws the given range of lines. The framesetter expects the CTM to be set up with the
// framesetter's space when this method is called.
//
- (void)drawLinesInRange:(NSRange)range inContext:(CGContextRef)context
{
    for (NSUInteger lineIndex = range.location; lineIndex < NSMaxRange(range); ++lineIndex)
    {
        NKTLine *line = [self.lines objectAtIndex:lineIndex];
        CGContextSetTextPosition(context, line.baselineOrigin.x, -line.baselineOrigin.y);
        [line drawInContext:context];
    }
}

@end
