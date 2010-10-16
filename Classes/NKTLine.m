//
// Copyright 2010 Allen Ding. All rights reserved.
//

#define KBC_LOGGING_DISABLE_DEBUG_OUTPUT 1

#import "NKTLine.h"
#import "NKTTextPosition.h"
#import "NKTTextRange.h"

@interface NKTLine()

#pragma mark Accessing the Core Text Line

@property (nonatomic, readonly) CTLineRef line;

@end

#pragma mark -

@implementation NKTLine

@synthesize index = index_;
@synthesize textRange = textRange_;
@synthesize baselineOrigin = baselineOrigin_;

#pragma mark -
#pragma mark Initializing

- (id)initWithDelegate:(id <NKTLineDelegate>)delegate
                 index:(NSUInteger)index
                  text:(NSAttributedString *)text
             textRange:(NKTTextRange *)textRange
        baselineOrigin:(CGPoint)origin
                 width:(CGFloat)width
                height:(CGFloat)height
              lastLine:(BOOL)lastLine
{
    if ((self = [super init]))
    {        
        delegate_ = delegate;
        index_ = index;
        text_ = text;
        textRange_ = [textRange copy];
        baselineOrigin_ = origin;
        width_ = width;
        height_ = height;
        lastLine_ = lastLine;
    }
    
    return self;
}

- (void)dealloc
{
    [textRange_ release];
    
    if (line_ != NULL)
    {
        CFRelease(line_);
    }
    
    [super dealloc];
}

#pragma mark -
#pragma mark Accessing the Core Text Line

- (CTLineRef)line
{
    if (line_ == NULL && !textRange_.empty)
    {
        KBCLogDebug(@"core text line created for %@", self);
        CTTypesetterRef typesetter = [delegate_ typesetter];
        line_ = CTTypesetterCreateLine(typesetter, textRange_.cfRange);
    }
    
    return line_;
}

#pragma mark -
#pragma mark Line Geometry

- (CGRect)rectForTextRange:(NKTTextRange *)textRange
{
    if (textRange_.empty ||
        textRange.empty ||
        [textRange_.start compare:textRange.end] != NSOrderedAscending ||
        [textRange.start compare:textRange_.end] != NSOrderedAscending)
    {
        return CGRectNull;
    }
    
    CGFloat backwardOffset = [self offsetForCharAtTextPosition:textRange.start];
    CGFloat forwardOffset = 0.0;
    
    if ([textRange.end compare:textRange_.end] != NSOrderedAscending && !lastLine_)
    {
        forwardOffset = width_;
    }
    else
    {
        forwardOffset = [self offsetForCharAtTextPosition:textRange.end];
    }
    
    CGFloat rectWidth = forwardOffset - backwardOffset;
    CGFloat topOffset = self.ascent != 0.0 ? self.ascent : height_;
    CGFloat bottomOffset = self.descent;
    CGFloat rectHeight = topOffset + bottomOffset;
    return CGRectMake(backwardOffset, baselineOrigin_.y - topOffset, rectWidth, rectHeight);
}

#pragma mark -
#pragma mark Getting Line Typographic Information

- (CGFloat)ascent
{
    CGFloat ascent = 0.0;
    CTLineGetTypographicBounds(self.line, &ascent, NULL, NULL);
    return ascent;
}

- (CGFloat)descent
{
    CGFloat descent = 0.0;
    CTLineGetTypographicBounds(self.line, NULL, &descent, NULL);
    return descent;
}

- (CGFloat)leading
{
    CGFloat leading = 0.0;
    CTLineGetTypographicBounds(self.line, NULL, NULL, &leading);
    return leading;
}

#pragma mark -
#pragma mark Getting Character Positions

- (CGFloat)offsetForCharAtTextPosition:(NKTTextPosition *)textPosition
{
    if (textRange_.empty)
    {
        return 0.0;
    }
    
    CGFloat charOffset = CTLineGetOffsetForStringIndex(self.line, (CFIndex)textPosition.location, NULL);
    return charOffset;
}

- (CGPoint)baselineOriginForCharAtTextPosition:(NKTTextPosition *)textPosition
{
    CGFloat charOffset = [self offsetForCharAtTextPosition:textPosition];
    return CGPointMake(baselineOrigin_.x + charOffset, baselineOrigin_.y);
}

#pragma mark -
#pragma mark Hit-Testing

- (NKTTextPosition *)closestTextPositionForCaretToPoint:(CGPoint)point
{
    //  If the text range is empty, return the text position with the proper affinity
    if (textRange_.empty)
    {
        if (point.x <= baselineOrigin_.x)
        {
            return textRange_.start;
        }
        else
        {
            return textRange_.end;
        }

    }
    
    // NOTE: y-coordinate ignored
    CGPoint localPoint = CGPointMake(point.x - baselineOrigin_.x, point.y - baselineOrigin_.y);
    NSUInteger charIndex = (NSUInteger)CTLineGetStringIndexForPosition(self.line, localPoint);
    UITextStorageDirection affinity = UITextStorageDirectionForward;
    
    // When the index matches the end of the line's text range, we may not want to return the end of the line's text
    // range depending on whether it is a newline or not
    if (charIndex == textRange_.end.location)
    {
        unichar lastCharOnLine = [[text_ string] characterAtIndex:charIndex - 1];
        NSCharacterSet *newlines = [NSCharacterSet newlineCharacterSet];
        
        // The caret should be placed before any newlines at the end of the line
        if ([newlines characterIsMember:lastCharOnLine])
        {
            charIndex = charIndex - 1;
        }
        else
        {
            affinity = UITextStorageDirectionBackward;
        }
    }
    
    NKTTextPosition *textPosition = [NKTTextPosition textPositionWithLocation:charIndex affinity:affinity];
    return textPosition;
}

- (BOOL)containsCaretAtTextPosition:(NKTTextPosition *)textPosition
{
    if ([self.textRange containsTextPosition:textPosition])
    {
        return YES;
    }
    else if (lastLine_ && [self.textRange.end isEqualToTextPositionIgnoringAffinity:textPosition])
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

#pragma mark -
#pragma mark Drawing

- (void)drawInContext:(CGContextRef)context
{
    CTLineDraw(self.line, context);
}

#pragma mark -
#pragma mark Debugging

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (%d, %@)", [self class], index_, textRange_];
}

@end
