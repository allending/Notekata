//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#define KBC_LOGGING_DISABLE_DEBUG_OUTPUT 1

#import "NKTTextViewTokenizer.h"
#import "KobaText.h"
#import "NKTTextPosition.h"
#import "NKTTextRange.h"
#import "NKTTextView.h"

// Either I am out of my mind or as of SDK 3.2, the recommended UITextInputStringTokenizer base
// implementation for the UITextInputTokenizer protocol is hopelessly broken (or has some weird
// semantics at the very least).
//
// As far as I can understand, theoretically NKTTextViewTokenizer only needs to handle the
// cases with line text granularity. Unfortunately, the behavior is absolutely bonkers if that
// is all we handle.
//
// Instead, as it stands, NKTTextViewTokenizer is almost a complete standalone implementation of
// the UITextInputTokenizer protocol, except in cases where the behavior provided by
// UITextInputStringTokenizer actually works as expected.
//
// Note that this implementation only supports left-to-right text.
//
// Overview:
// - Forward and backward refer to movement directions. NOT front/back of a text unit (e.g word)
// - A text unit has two boundaries - front and back
//
// Example:
// - Consider the phrase 'foobar mules x' and word granularity context
//
// - The word 'foobar' has two boundaries: 'f' and one-past 'r'
// 
// - 'f' is a word boundary in the backward direction
// - one-past 'r' is word boundary in the forward direction
// - 'f' is only part of the word in the forward direction
// - one-past 'r' is only a part of the text unit in the backward direction
//
// +-------------+--------------+--------------+--------------+--------------+
// |             | isPo:atB:fwd | isPo:atB:bwd | isPo:wTU:fwd | isPo:wTU:bwd |
// +-------------+--------------+--------------+--------------+--------------+
// | 'f'         |              |      x       |      x       |              |
// | 'oobar'     |              |              |      x       |       x      |
// | one-past'r' |       x      |              |              |       x      |
// +-------------+--------------+--------------+--------------+--------------+
//
// - one-past 'r' is the next word boundary in the forward direction from 'foobar'
// - 'm' is the next word boundary in the forward direction from one-past 'r'
// - 'f' is the next word boundary in the backward direction from 'oobar'
// - 'f' is the next word boundary in the backward direction from one-past 'r'
//
// +------------------------+--------------+--------------+
// |                        | pFP:toBo:fwd | pFP:toBo:bwd |
// +------------------------+--------------+--------------+
// | 'f'                    | one-past 'r' |     nil      |
// | 'oobar'                | one-past 'r' |     'f'      |
// | one-past 'r'           |    'm'       |     'f'      |
// +------------------------+--------------+--------------+
//
// - for 'f', the enclosing range is nil in the backward direction, and is 'foobar' in the forward direction
// - for 'oobar', the enclosing range in the forward and backward direction is 'foobar'
// - for one-past 'r', the enclosing range is nil in the forward direction, and is 'foobar' in the backward direction
//
// +---------------------+--------------+--------------+
// |                     | range:wG:fwd | range:wG:bwd |
// +---------------------+--------------+--------------+
// | 'f'                 |   'foobar'   |     nil      |
// | 'oobar'             |   'foobar'   |   'foobar'   |
// | one-past 'r'        |      nil     |   'foobar'   |
// +---------------------+--------------+--------------+

@interface NKTTextViewTokenizer()

#pragma mark Determining Text Positions Relative to Unit Boundaries

- (BOOL)isTextPosition:(NKTTextPosition *)textPosition atWordBoundaryInDirection:(UITextDirection)direction;
- (BOOL)isTextPosition:(NKTTextPosition *)textPosition atLineBoundaryInDirection:(UITextDirection)direction;
- (BOOL)isTextPosition:(NKTTextPosition *)textPosition atParagraphBoundaryInDirection:(UITextDirection)direction;

- (BOOL)isTextPosition:(NKTTextPosition *)textPosition withinWordInDirection:(UITextDirection)direction;
- (BOOL)isTextPosition:(NKTTextPosition *)textPosition withinLineInDirection:(UITextDirection)direction;
- (BOOL)isTextPosition:(NKTTextPosition *)textPosition withinParagraphInDirection:(UITextDirection)direction;

#pragma mark Computing Text Position by Unit Boundaries

- (UITextPosition *)positionFromTextPosition:(NKTTextPosition *)textPosition 
                   toWordBoundaryInDirection:(UITextDirection)direction;
- (UITextPosition *)positionFromTextPosition:(NKTTextPosition *)textPosition 
                   toLineBoundaryInDirection:(UITextDirection)direction;
- (UITextPosition *)positionFromTextPosition:(NKTTextPosition *)textPosition 
              toParagraphBoundaryInDirection:(UITextDirection)direction;

#pragma mark Getting Ranges of Specific Text Units

- (UITextRange *)textRangeForWordEnclosingTextPosition:(NKTTextPosition *)textPosition
                                           inDirection:(UITextDirection)direction;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------

@implementation NKTTextViewTokenizer

#pragma mark Initializing

- (id)initWithTextView:(NKTTextView *)textView
{
    if ((self = [super initWithTextInput:textView]))
    {
        textView_ = textView;
    }
    
    return self;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Determining Text Positions Relative to Unit Boundaries

- (BOOL)isPosition:(NKTTextPosition *)textPosition
        atBoundary:(UITextGranularity)granularity
       inDirection:(UITextDirection)direction
{
    BOOL result = NO;
    
    if (granularity == UITextGranularityWord)
    {
        result = [self isTextPosition:textPosition atWordBoundaryInDirection:direction];
    }
    else if (granularity == UITextGranularityLine)
    {
        result = [self isTextPosition:textPosition atLineBoundaryInDirection:direction];
    }
    else if (granularity == UITextGranularityParagraph)
    {
        result = [self isTextPosition:textPosition atParagraphBoundaryInDirection:direction];
    }
    else
    {
        result = [super isPosition:textPosition atBoundary:granularity inDirection:direction];
    }
 
    KBCLogDebug(@"%d : %@ : %@ -> %d",
                textPosition.location,
                KBTStringFromUITextGranularity(granularity),
                KBTStringFromUITextDirection(direction),
                result);
    
    return result;
}

// A text position is a word boundary in the forward direction if the text position is the end of
// a word.
//
// A text position is a word boundary in the backward direction if the text position is the start
// of a word.
- (BOOL)isTextPosition:(NKTTextPosition *)textPosition atWordBoundaryInDirection:(UITextDirection)direction
{
    NSString *string = [textView_.text string];
    NSCharacterSet *alphanumerics = [NSCharacterSet alphanumericCharacterSet];
    
    if (direction == UITextStorageDirectionForward ||
        direction == UITextLayoutDirectionRight ||
        direction == UITextLayoutDirectionDown)
    {
        // Not end of word if index is 0
        if (textPosition.location == 0)
        {
            return NO;
        }
        
        // End of word if previous position is alphanumeric, and position is not alphanumeric
        
        unichar previousChar = [string characterAtIndex:textPosition.location - 1];
        
        if (textPosition.location == [string length])
        {
            return [alphanumerics characterIsMember:previousChar];
        }
        
        unichar theChar = [string characterAtIndex:textPosition.location];
        return [alphanumerics characterIsMember:previousChar] && ![alphanumerics characterIsMember:theChar];
    }
    else
    {
        // Not start of word if index is the end
        if (textPosition.location == [string length])
        {
            return NO;
        }
        
        // Start of word if previous position is not alphanumeric and position is alphanumeric
        
        unichar theChar = [string characterAtIndex:textPosition.location];
        
        if (textPosition.location == 0)
        {
            return [alphanumerics characterIsMember:theChar];
        }
        
        unichar previousChar = [string characterAtIndex:textPosition.location - 1];
        return [alphanumerics characterIsMember:theChar] && ![alphanumerics characterIsMember:previousChar];
    }
}

// A text position is a line boundary in the forward direction if the text position is one before
// the end of a line's text range.
//
// A text position is a line boundary in the backward direction if the text position is the start
// of a line's text range.
- (BOOL)isTextPosition:(NKTTextPosition *)textPosition atLineBoundaryInDirection:(UITextDirection)direction
{
    NKTTextRange *lineTextRange = [textView_ textRangeForLineContainingTextPosition:textPosition];
    
    if (lineTextRange == nil)
    {
        return NO;
    }
    
    if (direction == UITextStorageDirectionForward ||
        direction == UITextLayoutDirectionRight ||
        direction == UITextLayoutDirectionDown)
    {
        return [textPosition isEqualToTextPosition:[lineTextRange.end textPositionByApplyingOffset:-1]];
    }
    else
    {
        return [textPosition isEqualToTextPosition:lineTextRange.start];
    }
}

// A text position is a paragraph boundary in the forward direction if the text position is the
// end of a paragraph (newline).
//
// A text position is a paragraph boundary in the backward direction if the text position is the
// start of a paragraph (follows a newline).
- (BOOL)isTextPosition:(NKTTextPosition *)textPosition atParagraphBoundaryInDirection:(UITextDirection)direction
{
    NSString *string = [textView_.text string];
    NSCharacterSet *newlines = [NSCharacterSet newlineCharacterSet];
    
    if (direction == UITextStorageDirectionForward ||
        direction == UITextLayoutDirectionRight ||
        direction == UITextLayoutDirectionDown)
    {
        // End index is always ends a paragraph
        if (textPosition.location == [string length])
        {
            return YES;
        }
        
        // End of paragraph if position is a newline
        
        unichar theChar = [string characterAtIndex:textPosition.location];
        return [newlines characterIsMember:theChar];
    }
    else
    {
        // Start index always begins a paragraph
        if (textPosition.location == 0)
        {
            return YES;
        }
        
        // Start of paragraph if previous position is a newline
        
        unichar previousChar = [string characterAtIndex:textPosition.location - 1];
        return [newlines characterIsMember:previousChar];
    }
}

- (BOOL)isPosition:(NKTTextPosition *)textPosition
    withinTextUnit:(UITextGranularity)granularity
       inDirection:(UITextDirection)direction
{
    BOOL result = NO;
    
    if (granularity == UITextGranularityWord)
    {
        result = [self isTextPosition:textPosition withinWordInDirection:direction];
    }
    else if (granularity == UITextGranularityLine)
    {
        result = [self isTextPosition:textPosition withinLineInDirection:direction];
    }
    else if (granularity == UITextGranularityParagraph)
    {
        result = [self isTextPosition:textPosition withinParagraphInDirection:direction];
    }
    else
    {
        result = [super isPosition:textPosition withinTextUnit:granularity inDirection:direction];
    }
    
    KBCLogDebug(@"%d : %@ : %@ -> %d",
                textPosition.location,
                KBTStringFromUITextGranularity(granularity),
                KBTStringFromUITextDirection(direction),
                result);
    
    return result;
}

// A text position is within a word in the forward direction if the text position is part of a
// word.
//
// A text position is within a word in the backward direction if the previous text position is part
// of a word.
- (BOOL)isTextPosition:(NKTTextPosition *)textPosition withinWordInDirection:(UITextDirection)direction
{
    NSString *string = [textView_.text string];
    NSCharacterSet *alphanumerics = [NSCharacterSet alphanumericCharacterSet];
    
    if (direction == UITextStorageDirectionForward ||
        direction == UITextLayoutDirectionRight ||
        direction == UITextLayoutDirectionDown)
    {
        // No words beyond the end index
        if (textPosition.location == [string length])
        {
            return NO;
        }
        
        unichar theChar = [string characterAtIndex:textPosition.location];
        return [alphanumerics characterIsMember:theChar];
    }
    else
    {
        // No words before the start index
        if (textPosition.location == 0)
        {
            return NO;
        }
        
        unichar previousChar = [string characterAtIndex:textPosition.location - 1];
        return [alphanumerics characterIsMember:previousChar];
    }
}

// If the line containing a text position has a text range with a length equal to one, then the
// text position is a boundary in both the forward and backward direction. Otherwise, the
// following applies:
//
// A text position is within a line in the forward direction if the text position is not the
// position one before the end of a line's text range.
//
// A text position is within a line in the backward direction if the text position is not the
// start of a line's text range.
- (BOOL)isTextPosition:(NKTTextPosition *)textPosition withinLineInDirection:(UITextDirection)direction
{
    NKTTextRange *lineTextRange = [textView_ textRangeForLineContainingTextPosition:textPosition];
    
    if (lineTextRange == nil)
    {
        return NO;
    }
    
    if (lineTextRange.length == 1)
    {
        return YES;
    }
    
    if (direction == UITextStorageDirectionForward ||
        direction == UITextLayoutDirectionRight ||
        direction == UITextLayoutDirectionDown)
    {
        return ![textPosition isEqualToTextPosition:[lineTextRange.end textPositionByApplyingOffset:-1]];
    }
    else
    {
        return ![textPosition isEqualToTextPosition:lineTextRange.start];
    }
}

// A text position is within a paragraph in the forward direction if the text position is not the
// end of a paragraph (newline).
//
// A text position is within a paragraph in the backward direction if the text position is not the
// start of a paragraph (follows a newline).
- (BOOL)isTextPosition:(NKTTextPosition *)textPosition withinParagraphInDirection:(UITextDirection)direction
{
    NSString *string = [textView_.text string];
    NSCharacterSet *newlines = [NSCharacterSet newlineCharacterSet];
    
    if (direction == UITextStorageDirectionForward ||
        direction == UITextLayoutDirectionRight ||
        direction == UITextLayoutDirectionDown)
    {
        // End index is always end of a paragraph
        if (textPosition.location == [string length])
        {
            return NO;
        }
        
        unichar theChar = [string characterAtIndex:textPosition.location];
        return ![newlines characterIsMember:theChar];
    }
    else
    {
        // Start index is always start of a paragraph
        if (textPosition.location == 0)
        {
            return NO;
        }
        
        unichar previousChar = [string characterAtIndex:textPosition.location - 1];
        return ![newlines characterIsMember:previousChar];
    }
}

//--------------------------------------------------------------------------------------------------

#pragma mark Computing Text Position by Unit Boundaries

- (UITextPosition *)positionFromPosition:(NKTTextPosition *)textPosition
                              toBoundary:(UITextGranularity)granularity
                             inDirection:(UITextDirection)direction
{
    UITextPosition *boundaryTextPosition = nil;
    
    if (granularity == UITextGranularityWord)
    {
        boundaryTextPosition = [self positionFromTextPosition:textPosition toWordBoundaryInDirection:direction];
    }
    else if (granularity == UITextGranularityLine)
    {
        boundaryTextPosition = [self positionFromTextPosition:textPosition toLineBoundaryInDirection:direction];
    }
    else if (granularity == UITextGranularityParagraph)
    {
        boundaryTextPosition = [self positionFromTextPosition:textPosition toParagraphBoundaryInDirection:direction];
    }
    else
    {
        boundaryTextPosition = [super positionFromPosition:textPosition toBoundary:granularity inDirection:direction];
    }
    
    KBCLogDebug(@"%d : %@ : %@ -> %d",
                textPosition.location,
                KBTStringFromUITextGranularity(granularity),
                KBTStringFromUITextDirection(direction),
                ((NKTTextPosition *)boundaryTextPosition).location);
    
    return boundaryTextPosition;
}

// The next word boundary in the forward direction is the furthest position in the direction that
// has the opposite alphanumeric 'sign' as the given position.
//
// The next word boundary in the backward direction is the furthest position in the direction that
// has the same alphanumeric 'sign' as the given position.
- (UITextPosition *)positionFromTextPosition:(NKTTextPosition *)textPosition 
                   toWordBoundaryInDirection:(UITextDirection)direction
{
    NSString *string = [textView_.text string];
    NSCharacterSet *alphanumerics = [NSCharacterSet alphanumericCharacterSet];
    
    if (direction == UITextStorageDirectionForward ||
        direction == UITextLayoutDirectionRight ||
        direction == UITextLayoutDirectionDown)
    {
        // The end position is always treated as a word boundary
        if (textPosition.location == [string length])
        {
            return textPosition;
        }
        
        unichar referenceChar = [string characterAtIndex:textPosition.location];
        BOOL referenceCharSign = [alphanumerics characterIsMember:referenceChar];
        NSUInteger currentIndex = textPosition.location + 1;
        
        for (; currentIndex < [string length]; ++currentIndex)
        {
            unichar currentChar = [string characterAtIndex:currentIndex];
            BOOL currentCharSign = [alphanumerics characterIsMember:currentChar];
            
            if (referenceCharSign != currentCharSign)
            {
                break;
            }
        }
        
        return [NKTTextPosition textPositionWithLocation:currentIndex affinity:UITextStorageDirectionForward];
    }
    else
    {
        // The start position is always treated a word boundary
        if (textPosition.location == 0)
        {
            return textPosition;
        }
        
        unichar referenceChar = [string characterAtIndex:textPosition.location - 1];
        BOOL referenceCharSign = [alphanumerics characterIsMember:referenceChar];
        NSUInteger currentIndex = textPosition.location - 1;
        
        for (; currentIndex > 0; --currentIndex)
        {
            unichar currentChar = [string characterAtIndex:currentIndex];
            BOOL currentCharSign = [alphanumerics characterIsMember:currentChar];
            
            if (referenceCharSign != currentCharSign)
            {
                ++currentIndex;
                break;
            }
        }
        
        return [NKTTextPosition textPositionWithLocation:currentIndex affinity:UITextStorageDirectionForward];
    }
}

// If the text position is one before the end of a line's text range, it is already at the
// boundary. Otherwise, the next line boundary in the forward direction is one before the
// end of the line's text range.
//
// If the text position is the start of a line's text range, it is already at the boundary.
// Otherwise, the next line boundary in the backward direction is the start of the line's text
// range.
- (UITextPosition *)positionFromTextPosition:(NKTTextPosition *)textPosition 
                   toLineBoundaryInDirection:(UITextDirection)direction
{
    NSString *string = [textView_.text string];
    NKTTextRange *lineTextRange = [textView_ textRangeForLineContainingTextPosition:textPosition];
    
    if (lineTextRange == nil)
    {
        return nil;
    }
    
    if (direction == UITextStorageDirectionForward ||
        direction == UITextLayoutDirectionRight ||
        direction == UITextLayoutDirectionDown)
    {
        // PENDING: No boundary position after the end index?
        if (textPosition.location == [string length])
        {
            return textPosition;
        }
        
        NKTTextPosition *oneBeforeEnd = [lineTextRange.end textPositionByApplyingOffset:-1];
        
        if ([textPosition isEqualToTextPosition:oneBeforeEnd])
        {
            // HACK: make sure that UITextInput does not 'skip' over a line
            return textPosition;
        }
        else
        {
            return oneBeforeEnd;
        }
    }
    else
    {
        // No boundary position before the start index
        if (textPosition.location == 0)
        {
            return textPosition;
        }
        
        if ([textPosition isEqualToTextPosition:lineTextRange.start])
        {
            // HACK: make sure that UITextInput does not 'skip' over a line
            return textPosition;
        }
        else
        {
            return lineTextRange.start;
        }
    }
}

// If the text position is the end of a paragraph, the next paragraph boundary in the
// forward direction is one beyond the end of the paragraph. Otherwise, the next paragraph
// boundary in the forward direction is one before the end of the paragraph.
//
// If the text position is the start of a paragraph, the next paragraph boundary in the backward
// direction is one before the start of the paragraph. Otherwise, the next paragraph boundary in
// the backward direction is the start of the paragraph.
- (UITextPosition *)positionFromTextPosition:(NKTTextPosition *)textPosition 
              toParagraphBoundaryInDirection:(UITextDirection)direction
{
    NSString *string = [textView_.text string];
    NSCharacterSet *newlines = [NSCharacterSet newlineCharacterSet];
    
    if (direction == UITextStorageDirectionForward ||
        direction == UITextLayoutDirectionRight ||
        direction == UITextLayoutDirectionDown)
    {
        if (textPosition.location == [string length])
        {
            return textPosition;
        }

        unichar theChar = [string characterAtIndex:textPosition.location];
        
        if ([newlines characterIsMember:theChar])
        {
            return [textPosition textPositionByApplyingOffset:+1];
        }
        else
        {
            NSUInteger currentIndex = textPosition.location + 1;
            
            for (; currentIndex < [string length]; ++currentIndex)
            {
                unichar currentChar = [string characterAtIndex:currentIndex];
                
                if ([newlines characterIsMember:currentChar])
                {
                    break;
                }
            }
            
            return [NKTTextPosition textPositionWithLocation:currentIndex affinity:UITextStorageDirectionForward];
        }
    }
    else
    {
        if (textPosition.location == 0)
        {
            return textPosition;
        }
        
        unichar previousChar = [string characterAtIndex:textPosition.location - 1];
        
        if ([newlines characterIsMember:previousChar])
        {
            return [textPosition textPositionByApplyingOffset:-1];
        }
        else
        {
            NSUInteger currentIndex = textPosition.location - 1;
            
            for (; currentIndex > 0; --currentIndex)
            {
                unichar currentChar = [string characterAtIndex:currentIndex];
                
                if ([newlines characterIsMember:currentChar])
                {
                    ++currentIndex;
                    break;
                }
            }
            
            return [NKTTextPosition textPositionWithLocation:currentIndex affinity:UITextStorageDirectionForward];
        }
    }
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Ranges of Specific Text Units

// In this method, return the range for the text enclosing a text position in a text unit of the
// given granularity, or nil if there is no such enclosing unit. If the text position is entirely
// enclosed within a text unit of the given granularity, it is considered enclosed. If the text
// position is at a text-unit boundary, it is considered enclosed only if the next position in
// the given direction is entirely enclosed.
- (UITextRange *)rangeEnclosingPosition:(NKTTextPosition *)textPosition
                        withGranularity:(UITextGranularity)granularity
                            inDirection:(UITextDirection)direction
{
    UITextRange *result = nil;
    
//    if (granularity == UITextGranularityWord)
//    {
//        result = [self textRangeForWordEnclosingTextPosition:textPosition inDirection:direction];
//    }
//    else if (granularity == UITextGranularityLine)
//    {
//        // PENDING: it looks like this is never used, so leave it unimplemented for now
//        result = nil;
//    }
//    else
//    {
        result = [super rangeEnclosingPosition:textPosition withGranularity:granularity inDirection:direction];
//    }
    
    KBCLogDebug(@"%d : %@ : %@ : %@",
                textPosition.location,
                KBTStringFromUITextGranularity(granularity),
                KBTStringFromUITextDirection(direction),
                result);
    
    return result;
}

- (UITextRange *)textRangeForWordEnclosingTextPosition:(NKTTextPosition *)textPosition
                                           inDirection:(UITextDirection)direction
{    
    if (direction == UITextStorageDirectionForward ||
        direction == UITextLayoutDirectionRight ||
        direction == UITextLayoutDirectionDown)
    {
        if (![self isTextPosition:textPosition withinWordInDirection:UITextStorageDirectionForward])
        {
            return nil;
        }
        
        NKTTextPosition *backwardBoundary = nil;
        
        if ([self isTextPosition:textPosition atWordBoundaryInDirection:UITextStorageDirectionBackward])
        {
            backwardBoundary = textPosition;
        }
        else
        {
            backwardBoundary = (NKTTextPosition *)[self positionFromTextPosition:textPosition
                                                       toWordBoundaryInDirection:UITextStorageDirectionBackward];
        }
        
        NKTTextPosition *forwardBoundary = nil;

        if ([self isTextPosition:textPosition atWordBoundaryInDirection:UITextStorageDirectionForward])
        {
            forwardBoundary = textPosition;
        }
        else
        {
            forwardBoundary = (NKTTextPosition *)[self positionFromTextPosition:textPosition
                                                      toWordBoundaryInDirection:UITextStorageDirectionForward];
        }
        
        return [NKTTextRange textRangeWithTextPosition:backwardBoundary textPosition:forwardBoundary];
    }
    else
    {
        if (![self isTextPosition:textPosition withinWordInDirection:UITextStorageDirectionBackward])
        {
            return nil;
        }
        
        NKTTextPosition *backwardBoundary = nil;
        
        if ([self isTextPosition:textPosition atWordBoundaryInDirection:UITextStorageDirectionBackward])
        {
            backwardBoundary = textPosition;
        }
        else
        {
            backwardBoundary = (NKTTextPosition *)[self positionFromTextPosition:textPosition
                                                       toWordBoundaryInDirection:UITextStorageDirectionBackward];
        }
        
        NKTTextPosition *forwardBoundary = nil;
        
        if ([self isTextPosition:textPosition atWordBoundaryInDirection:UITextStorageDirectionForward])
        {
            forwardBoundary = textPosition;
        }
        else
        {
            forwardBoundary = (NKTTextPosition *)[self positionFromTextPosition:textPosition
                                                      toWordBoundaryInDirection:UITextStorageDirectionForward];
        }
        
        return [NKTTextRange textRangeWithTextPosition:backwardBoundary textPosition:forwardBoundary];
    }
}

@end
