//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#define KBC_LOGGING_DISABLE_DEBUG_OUTPUT 1

#import "NKTLine.h"
#import "NKTTextPosition.h"
#import "NKTTextRange.h"

@interface NKTLine()

#pragma mark Accessing the Typeset Line

@property (nonatomic, readonly) CTLineRef line;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------

@implementation NKTLine

@synthesize index = index_;
@synthesize range = range_;
@synthesize baselineOrigin = baselineOrigin_;

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (id)initWithDelegate:(id <NKTLineDelegate>)delegate
                 index:(NSUInteger)index
                  text:(NSAttributedString *)text
                 range:(NSRange)range
                baselineOrigin:(CGPoint)origin
                 width:(CGFloat)width
                height:(CGFloat)height
{
    if ((self = [super init]))
    {
        delegate_ = delegate;
        index_ = index;
        text_ = text;
        range_ = range;
        baselineOrigin_ = origin;
        width_ = width;
        height_ = height;
    }
    
    return self;
}

- (void)dealloc
{
    if (line_ != NULL)
    {
        CFRelease(line_);
    }
    
    [super dealloc];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Accessing the Typeset Line

- (CTLineRef)line
{
    if (line_ == NULL && (range_.length != 0))
    {
        KBCLogDebug(@"core text line for %@ created", self);
        CTTypesetterRef typesetter = [delegate_ typesetter];
        line_ = CTTypesetterCreateLine(typesetter, CFRangeFromNSRange(range_));
    }
    
    return line_;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Accessing the Text Range

- (NKTTextRange *)textRange
{
    return [NKTTextRange textRangeWithRange:range_ affinity:UITextStorageDirectionForward];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Line Geometry

- (CGRect)rect
{
    if (self.textRange.empty)
    {
        return CGRectNull;
    }
    
    return CGRectMake(baselineOrigin_.x, baselineOrigin_.y - self.ascent, width_, self.ascent + self.descent);
}

- (CGRect)rectFromTextPosition:(NKTTextPosition *)fromTextPosition toTextPosition:(NKTTextPosition *)toTextPosition
{
    CGRect rect = self.rect;
    CGFloat fromCharOffset = [self offsetForCharAtTextPosition:fromTextPosition];
    CGFloat toCharOffset = [self offsetForCharAtTextPosition:toTextPosition];
    rect.origin.x += fromCharOffset;
    rect.size.width = toCharOffset - fromCharOffset;
    return rect;
}

- (CGRect)rectFromTextPosition:(NKTTextPosition *)textPosition
{
    CGRect rect = self.rect;
    CGFloat charOffset = [self offsetForCharAtTextPosition:textPosition];
    rect.origin.x += charOffset;
    rect.size.width -= charOffset;
    return rect;
}

- (CGRect)rectToTextPosition:(NKTTextPosition *)textPosition
{
    CGRect rect = self.rect;
    CGFloat charOffset = [self offsetForCharAtTextPosition:textPosition];
    rect.size.width = charOffset;
    return rect;
}

//--------------------------------------------------------------------------------------------------

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

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Character Offsets

- (CGFloat)offsetForCharAtTextPosition:(NKTTextPosition *)textPosition
{
    if (range_.length == 0)
    {
        return 0.0;
    }
    
    CGFloat charOffset = CTLineGetOffsetForStringIndex(self.line, (CFIndex)textPosition.location, NULL);
    return charOffset;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Hit-Testing

// TODO: rename this to for caret
// add affinity output
- (NKTTextPosition *)closestTextPositionToFramesetterPoint:(CGPoint)framesetterPoint
{
    if (range_.length == 0)
    {
        return [NKTTextPosition textPositionWithLocation:range_.location affinity:UITextStorageDirectionForward];
    }
    
    CGPoint localPoint = CGPointMake(framesetterPoint.x - baselineOrigin_.x, framesetterPoint.y - baselineOrigin_.y);
    NSUInteger charIndex = (NSUInteger)CTLineGetStringIndexForPosition(self.line, localPoint);
    UITextStorageDirection affinity = UITextStorageDirectionForward;
    
    // When the line ends with a newline, the caret should be placed before the newline character
    if (charIndex == NSMaxRange(range_))
    {
        unichar lastChar = [[text_ string] characterAtIndex:charIndex - 1];
        NSCharacterSet *newlines = [NSCharacterSet newlineCharacterSet];
        
        if ([newlines characterIsMember:lastChar])
        {
            charIndex = charIndex - 1;
        }
        else
        {
            affinity = UITextStorageDirectionBackward;
        }
    }
    
    return [NKTTextPosition textPositionWithLocation:charIndex affinity:affinity];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Drawing

- (void)drawInContext:(CGContextRef)context
{
    CTLineDraw(self.line, context);
}

//--------------------------------------------------------------------------------------------------

#pragma mark Debugging

- (NSString *)description
{
    return [NSString stringWithFormat:@"line %d %@", index_, NSStringFromRange(range_)];
}

@end
