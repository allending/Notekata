//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#define KBC_LOGGING_DISABLE_DEBUG_OUTPUT 1

#import "NKTLine.h"
#import "NKTTextPosition.h"
#import "NKTTextRange.h"

@interface NKTLine()

#pragma mark Accessing the Core Text Line

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

#pragma mark Accessing the Core Text Line

- (CTLineRef)line
{
    if (line_ == NULL && (range_.length != 0))
    {
        KBCLogDebug(@"core text line created for %@", self);
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
    
    return CGRectMake(baselineOrigin_.x, baselineOrigin_.y - self.ascent - 2.0, width_, self.ascent + self.descent + 4.0);
}

- (CGRect)rectFromTextPosition:(NKTTextPosition *)fromTextPosition toTextPosition:(NKTTextPosition *)toTextPosition
{
    CGRect rect = self.rect;
    CGFloat fromCharOffset = [self offsetForCharAtTextPosition:fromTextPosition];
    CGFloat toCharOffset = [self offsetForCharAtTextPosition:toTextPosition];
    
    if (toCharOffset == 0.0)
    {
        return CGRectNull;
    }
    
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
    
    if (charOffset == 0.0)
    {
        return CGRectNull;
    }
    
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

#pragma mark Getting Character Positions

- (CGFloat)offsetForCharAtTextPosition:(NKTTextPosition *)textPosition
{
    if (range_.length == 0)
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

//--------------------------------------------------------------------------------------------------

#pragma mark Hit-Testing

- (NKTTextPosition *)closestTextPositionForCaretToPoint:(CGPoint)point
{
    if (range_.length == 0)
    {
        return [NKTTextPosition textPositionWithLocation:range_.location affinity:UITextStorageDirectionForward];
    }
    
    CGPoint localPoint = CGPointMake(point.x - baselineOrigin_.x, point.y - baselineOrigin_.y);
    NSUInteger charIndex = (NSUInteger)CTLineGetStringIndexForPosition(self.line, localPoint);
    UITextStorageDirection affinity = UITextStorageDirectionForward;
    
    if (charIndex == NSMaxRange(range_))
    {
        unichar lastChar = [[text_ string] characterAtIndex:charIndex - 1];
        NSCharacterSet *newlines = [NSCharacterSet newlineCharacterSet];
    
        // The caret should be placed before any newlines that break the line
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
    return [NSString stringWithFormat:@"%@ (%d, %@)",
                                       [self class],
                                       index_,
                                       NSStringFromRange(range_)];
}

@end
