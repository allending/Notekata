//
// Copyright 2010 Allen Ding. All rights reserved.
//

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

#pragma mark -
#pragma mark Getting the Frame Size

- (CGSize)frameSize
{
    return CGSizeMake(lineWidth_, lineHeight_ * (CGFloat)self.numberOfLines);
}

#pragma mark -
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

#pragma mark -
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

#pragma mark -
#pragma mark Typesetting Lines

- (void)typesetFromLineAtIndex:(NSUInteger)lineIndex
{
    if (lineIndex > [lines_ count])
    {
        KBCLogWarning(@"line index %d is greater than the number of lines %d, ignoring", lineIndex, [lines_ count]);
        return;
    }
    
    NSUInteger textLength = [text_ length];
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
        currentLocation = line.textRange.start.location;
        currentLineBaselineOrigin = line.baselineOrigin;
    }
    
    // Remove lines that will be retypeset
    [lines_ removeObjectsInRange:NSMakeRange(lineIndex, [lines_ count] - lineIndex)];
    
    BOOL needsSentinelLine = [[text_ string] isLastCharacterNewline] || textLength == 0;
    
    // Typeset until end of text
    while (currentLocation < textLength)
    {
        NSUInteger lineLength = (NSUInteger)CTTypesetterSuggestLineBreak(self.typesetter, currentLocation, lineWidth_);
        NKTTextPosition *startTextPosition = [NKTTextPosition textPositionWithLocation:currentLocation
                                                                              affinity:UITextStorageDirectionForward];
        NKTTextPosition *endTextPosition = [NKTTextPosition textPositionWithLocation:currentLocation + lineLength
                                                                            affinity:UITextStorageDirectionForward];
        NKTTextRange *textRange = [NKTTextRange textRangeWithTextPosition:startTextPosition
                                                             textPosition:endTextPosition];
        BOOL isLastLine = !needsSentinelLine && endTextPosition.location == textLength;
        NKTLine *line = [[NKTLine alloc] initWithDelegate:self
                                                    index:currentLineIndex
                                                     text:text_
                                                textRange:textRange
                                           baselineOrigin:currentLineBaselineOrigin
                                                    width:lineWidth_
                                                   height:lineHeight_
                                                 lastLine:isLastLine];
        [lines_ addObject:line];
        KBCLogDebug(@"typesetted %@", line);
        [line release];
        ++currentLineIndex;
        currentLocation += lineLength;
        currentLineBaselineOrigin.y += lineHeight_;
    }
    
    // Add a sentinel line if needed
    if (needsSentinelLine)
    {
        NKTTextPosition *textPosition = [NKTTextPosition textPositionWithLocation:textLength
                                                                         affinity:UITextStorageDirectionForward];
        NKTLine *sentinel = [[NKTLine alloc] initWithDelegate:self
                                                        index:[lines_ count]
                                                         text:text_
                                                    textRange:[textPosition textRange]
                                               baselineOrigin:currentLineBaselineOrigin
                                                        width:lineWidth_
                                                       height:lineHeight_
                                                     lastLine:YES];
        [lines_ addObject:sentinel];
        [sentinel release];
    }
}

#pragma mark -
#pragma mark Updating the Framesetter

- (void)textChangedFromTextPosition:(NKTTextPosition *)textPosition
{
    NKTLine *line = [self lineForCaretAtTextPosition:textPosition];
    [self invalidateTypesetter];
    [self typesetFromLineAtIndex:line.index];
}

#pragma mark -
#pragma mark Hit-Testing and Geometry

- (NSInteger)virtualIndexForLineClosestToPoint:(CGPoint)point
{
    //CGFloat virtualLinePointOffset = -lineHeight_ * 0.1;
    return (NSInteger)floor((point.y - 12.0) / lineHeight_);
}

- (NKTLine *)lineClosestToPoint:(CGPoint)point
{
    NSInteger lineIndex = [self virtualIndexForLineClosestToPoint:point];
    
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
    NSInteger lineIndex = [self virtualIndexForLineClosestToPoint:point];
    
    if (lineIndex < 0)
    {
        lineIndex = 0;
    }
    else if (lineIndex >= self.numberOfLines)
    {
        lineIndex = self.numberOfLines - 1;
    }
    
    NKTLine *line = [self.lines objectAtIndex:lineIndex];
    return [line closestTextPositionForCaretToPoint:point];
}

- (NKTLine *)lineForCaretAtTextPosition:(NKTTextPosition *)textPosition
{
    NSUInteger minLineIndex = 0;
    NSUInteger maxLineIndex = self.numberOfLines - 1;
    NSUInteger midLineIndex = 0;
    
    while (minLineIndex <= maxLineIndex)
    {
        midLineIndex = minLineIndex + ((maxLineIndex - minLineIndex) / 2);
        NKTLine *currentLine = [self.lines objectAtIndex:midLineIndex];
        
        if ([currentLine containsCaretAtTextPosition:textPosition])
        {
            return currentLine;
        }
        
        // Text position lies before current line
        if ([textPosition compare:currentLine.textRange.start] == NSOrderedAscending)
        {
            maxLineIndex = midLineIndex - 1;
        }
        // Text position lies after current line
        else
        {
            minLineIndex = midLineIndex + 1;
        }
    }
    
    KBCLogWarning(@"search failed, returning nil");
    return nil;
}

- (CGPoint)baselineOriginForCharAtTextPosition:(NKTTextPosition *)textPosition
{
    NKTLine *line = [self lineForCaretAtTextPosition:textPosition];
    return [line baselineOriginForCharAtTextPosition:textPosition];
}

- (CGRect)firstRectForTextRange:(NKTTextRange *)textRange
{
    NKTLine *line = [self lineForCaretAtTextPosition:textRange.start];
    CGRect rect = [line rectForTextRange:textRange];
    
    if (CGRectEqualToRect(rect, CGRectNull) && line.index > 0)
    {
        line = [self.lines objectAtIndex:line.index - 1];
        rect = [line rectForTextRange:textRange];
    }
    
    return rect;
}

- (CGRect)lastRectForTextRange:(NKTTextRange *)textRange
{
    NKTLine *line = [self lineForCaretAtTextPosition:textRange.end];
    CGRect rect = [line rectForTextRange:textRange];
    
    if (CGRectEqualToRect(rect, CGRectNull) && line.index > 0)
    {
        line = [self.lines objectAtIndex:line.index - 1];
        rect = [line rectForTextRange:textRange];
    }
    
    return rect;
}

- (NSArray *)rectsForTextRange:(NKTTextRange *)textRange transform:(CGAffineTransform)transform
{
    NSMutableArray *rects = [NSMutableArray array];
    NKTLine *firstLine = [self lineForCaretAtTextPosition:textRange.start];
    NKTLine *lastLine = [self lineForCaretAtTextPosition:textRange.end];
    
    for (NSUInteger lineIndex = firstLine.index; lineIndex <= lastLine.index; ++lineIndex)
    {
        NKTLine *line = [self.lines objectAtIndex:lineIndex];
        CGRect rect = [line rectForTextRange:textRange];
        
        if (!CGRectEqualToRect(rect, CGRectNull))
        {
            rect = CGRectApplyAffineTransform(rect, transform);
            [rects addObject:[NSValue valueWithCGRect:rect]];
        }
    }
    
    return rects;
}

#pragma mark -
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
