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

#pragma mark Accessing Lines

@property (nonatomic, readonly) NSArray *lines;

#pragma mark Typesetting Lines

- (void)typesetFromLineAtIndex:(NSUInteger)lineIndex;

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

#pragma mark Getting the Frame Size

- (CGSize)frameSize
{
    return CGSizeMake(lineWidth_, lineHeight_ * (CGFloat)self.numberOfLines);
}

//--------------------------------------------------------------------------------------------------

#pragma mark Managing the Typesetter

// It isn't clear whether it is safe to change the backing text for the typesetter returned by
// CTTypesetterCreateWithAttributedString, so we invalidate and recreate the CTTypesetter each
// time the text changes.

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

#pragma mark Accessing Lines

- (NSArray *)lines
{
    if (lines_ == nil)
    {
        lines_ = [[NSMutableArray alloc] init];
        [self typesetFromLineAtIndex:0];
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

#pragma mark Typesetting Lines

- (void)typesetFromLineAtIndex:(NSUInteger)lineIndex
{
    if (lineIndex > [lines_ count])
    {
        KBCLogWarning(@"line index %d is greater than the number of lines %d, ignoring", lineIndex, [lines_ count]);
        return;
    }
    
    NSUInteger currentLineIndex = lineIndex;
    NSUInteger currentLocation = 0;
    CGPoint currentLineBaselineOrigin = CGPointZero;
    
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
    
    // Add a sentinel line if needed
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

//--------------------------------------------------------------------------------------------------

#pragma mark Updating the Framesetter

- (void)textChangedFromTextPosition:(NKTTextPosition *)textPosition
{
    NKTLine *line = [self lineForCaretAtTextPosition:textPosition];
    [self invalidateTypesetter];
    [self typesetFromLineAtIndex:line.index];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Hit-Testing and Geometry

- (NSInteger)virtualLineIndexClosestToPoint:(CGPoint)point
{
    //CGFloat virtualLinePointOffset = -lineHeight_ * 0.1;
    return (NSInteger)floor(point.y / lineHeight_);
}

- (NKTLine *)lineClosestToPoint:(CGPoint)point
{
    NSInteger lineIndex = [self virtualLineIndexClosestToPoint:point];
    
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

- (NKTTextPosition *)closestTextPositionForCaretToPoint:(CGPoint)point
{
    NSInteger lineIndex = [self virtualLineIndexClosestToPoint:point];
    
    if (lineIndex < 0)
    {
        return [NKTTextPosition textPositionWithLocation:0 affinity:UITextStorageDirectionForward];
    }
    else if (lineIndex >= self.numberOfLines)
    {
        return [NKTTextPosition textPositionWithLocation:[text_ length] affinity:UITextStorageDirectionForward];
    }
    
    NKTLine *line = [self.lines objectAtIndex:lineIndex];
    return [line closestTextPositionForCaretToPoint:point];
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
    
    // If no lines were found to contain the text position, then the line for the caret may be the
    // last line (happens when the end of the text is not a newline)
    NKTLine *lastLine = [self lastLine];
    
    if ([lastLine.textRange.end isEqualToTextPosition:textPosition])
    {
        return lastLine;
    }
    
    KBCLogWarning(@"no line contains %@, returning nil", textPosition);
    return nil;
}

- (CGPoint)baselineOriginForCharAtTextPosition:(NKTTextPosition *)textPosition
{
    NKTLine *line = [self lineForCaretAtTextPosition:textPosition];
    return [line baselineOriginForCharAtTextPosition:textPosition];
}

- (NSArray *)rectsForTextRange:(NKTTextRange *)textRange
{
    return [self rectsForTextRange:textRange transform:CGAffineTransformIdentity];
}

- (NSArray *)rectsForTextRange:(NKTTextRange *)textRange transform:(CGAffineTransform)transform
{
    NKTLine *firstLine = [self lineForCaretAtTextPosition:textRange.start];
    NKTLine *lastLine = [self lineForCaretAtTextPosition:textRange.end];
    
    // Single line
    if (firstLine == lastLine)
    {
        CGRect lineRect = [firstLine rectFromTextPosition:textRange.start toTextPosition:textRange.end];
        lineRect = CGRectApplyAffineTransform(lineRect, transform);
        return [NSArray arrayWithObject:[NSValue valueWithCGRect:lineRect]];
    }
    //  Multiple lines
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
        
        // Last line is null when the last line is empty, and we had better not include it
        if (!CGRectEqualToRect(lastLineRect, CGRectNull))
        {
            [rects addObject:[NSValue valueWithCGRect:lastLineRect]];
        }
        
        return rects;
    }
}

//--------------------------------------------------------------------------------------------------

#pragma mark Drawing

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
