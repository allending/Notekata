//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTTextViewTokenizer.h"
#import "NKTTextPosition.h"
#import "NKTTextRange.h"
#import "NKTTextView.h"

NSString *StringFromGranularity(UITextGranularity granularity)
{
    switch (granularity)
    {
        case UITextGranularityCharacter:
            return @"character";
        case UITextGranularityWord:
            return @"word";
        case UITextGranularitySentence:
            return @"sentence";
        case UITextGranularityParagraph:
            return @"paragraph";
        case UITextGranularityLine:
            return @"line";
        case UITextGranularityDocument:
            return @"document";
    }
    
    return @"unknown";
}

NSString *StringFromDirection(UITextDirection direction)
{
    switch (direction)
    {
        case UITextStorageDirectionForward:
            return @"forward";
        case UITextStorageDirectionBackward:
            return @"backward";
        case UITextLayoutDirectionRight:
            return @"right";
        case UITextLayoutDirectionLeft:
            return @"left";
        case UITextLayoutDirectionUp:
            return @"up";
        case UITextLayoutDirectionDown:
            return @"down";
    }
    
    return @"unknown";
}

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

- (BOOL)isPosition:(NKTTextPosition *)position
        atBoundary:(UITextGranularity)granularity
       inDirection:(UITextDirection)direction
{
    KBCLogDebug(@"pos:%d gran:%@ dir:%@",
                position.index,
                StringFromGranularity(granularity),
                StringFromDirection(direction));

    BOOL result = NO;
    
//    if (granularity == UITextGranularityParagraph)
//    {
//        if (direction == UITextStorageDirectionForward || direction == UITextLayoutDirectionRight)
//        {
//            NSString *string = [textView_.text string];
//            
//            if (position.index == [string length])
//            {
//                result = YES;
//            }
//            else
//            {
//                NSCharacterSet *nlcs = [NSCharacterSet newlineCharacterSet];
//                unichar nextchar = [string characterAtIndex:position.index + 1];
//                result = [nlcs characterIsMember:nextchar];
//            }
//        }
//        else if (direction == UITextStorageDirectionBackward || direction == UITextLayoutDirectionLeft)
//        {
//            NSString *string = [textView_.text string];
//            
//            if (position.index == 0)
//            {
//                result = YES;
//            }
//            else
//            {
//                NSCharacterSet *nlcs = [NSCharacterSet newlineCharacterSet];
//                unichar prevChar = [string characterAtIndex:position.index - 1];
//                result = [nlcs characterIsMember:prevChar];
//            }
//        }
//    }
    if (granularity == UITextGranularityLine)
    {
        result = [textView_ isTextPosition:position atLineBoundaryInDirection:direction];
    }
    else
    {
        result = [super isPosition:position atBoundary:granularity inDirection:direction];
    }
    
    
    KBCLogDebug(@"result:%d", result);
    
    return result;
}

// For word granurality and forward direction,
//   we are within a text unit if the position is non whitespace
// For word granurality and backwards direction,
//   we are within a text unit if the previous position is non whitespace
//
- (BOOL)isPosition:(NKTTextPosition *)position
    withinTextUnit:(UITextGranularity)granularity
       inDirection:(UITextDirection)direction
{ 
    KBCLogDebug(@"pos:%d gran:%@ dir:%@",
                position.index,
                StringFromGranularity(granularity),
                StringFromDirection(direction));
    
    BOOL result = NO;
    
    if (granularity == UITextGranularityWord)
    {
        if (direction == UITextStorageDirectionForward || direction == UITextLayoutDirectionRight)
        {
            // yes if position is non whitespace and previous is whitespace
            NSString *string = [textView_.text string];
            NSCharacterSet *wscset = [NSCharacterSet whitespaceAndNewlineCharacterSet];
            unichar theChar = [string characterAtIndex:position.index];
            
            if (position.index == 0)
            {
                if (![wscset characterIsMember:theChar])
                {
                    result = YES;
                }
                else
                {
                    result = NO;
                }
            }
            else
            {
                unichar prevChar = [string characterAtIndex:position.index - 1];
                
                if ([wscset characterIsMember:prevChar] && ![wscset characterIsMember:theChar])
                {
                    result = YES;
                }
                else
                {
                    result = NO;
                }
            }
        }
        else if (direction == UITextStorageDirectionBackward || direction == UITextLayoutDirectionLeft)
        {
            // yes if position is whitespace and previous is non whitespace
            NSString *string = [textView_.text string];
            
            if (position.index == 0)
            {
                result = NO;
            }
            else
            {
                NSCharacterSet *wscset = [NSCharacterSet whitespaceAndNewlineCharacterSet];
                
                if (position.index != [string length])
                {
                    unichar theChar = [string characterAtIndex:position.index];
                    
                    if (![wscset characterIsMember:theChar])
                    {
                        result = NO;
                    }
                    else
                    {
                        unichar charBefore = [string characterAtIndex:position.index - 1];
                        
                        if (![wscset characterIsMember:charBefore])
                        {
                            result = YES;
                        }
                        else
                        {
                            result = NO;
                        }
                    }
                }
                else
                {
                    unichar charBefore = [string characterAtIndex:position.index - 1];
                    
                    if (![wscset characterIsMember:charBefore])
                    {
                        result = YES;
                    }
                    else
                    {
                        result = NO;
                    }
                }
            }
        }
    }
    else if (granularity == UITextGranularityLine)
    {
        result = [textView_ isTextPosition:position withinLineInDirection:direction];
    }
    else
    {
        result = [super isPosition:position withinTextUnit:granularity inDirection:direction];
    }
    
    KBCLogDebug(@"result:%d", result);
    
    return result;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Computing Text Position by Unit Boundaries

- (UITextPosition *)positionFromPosition:(NKTTextPosition *)position
                              toBoundary:(UITextGranularity)granularity
                             inDirection:(UITextDirection)direction
{    
    KBCLogDebug(@"pos:%d gran:%@ dir:%@",
                position.index,
                StringFromGranularity(granularity),
                StringFromDirection(direction));
    
    UITextPosition *result = nil;
    
    if (granularity == UITextGranularityLine)
    {
        result = [textView_ positionFromTextPosition:position toLineBoundaryInDirection:direction];
    }
    else if (granularity == UITextGranularityParagraph)
    {
        if (direction == UITextStorageDirectionForward || direction == UITextLayoutDirectionRight)
        {
            NSString *string = [textView_.text string];
            NSUInteger firstSearchIndex = position.index + 1;
  
            if (firstSearchIndex == [string length])
            {
                result = [NKTTextPosition textPositionWithIndex:[string length]];
            }
            else
            {
                NSCharacterSet *nlcs = [NSCharacterSet newlineCharacterSet];
                NSRange range = [string rangeOfCharacterFromSet:nlcs
                                                        options:0
                                                          range:NSMakeRange(firstSearchIndex, [string length] - firstSearchIndex)];
                
                if (range.location == NSNotFound)
                {
                    result = [NKTTextPosition textPositionWithIndex:[string length]];
                }
                else
                {
                    result = [NKTTextPosition textPositionWithIndex:range.location];
                }
            }
        }
        else if (direction == UITextStorageDirectionBackward || direction == UITextLayoutDirectionLeft)
        {
            NSString *string = [textView_.text string];
            
            if (position.index == 0)
            {
                result = [NKTTextPosition textPositionWithIndex:0];
            }
            else
            {            
                NSUInteger firstSearchIndex = position.index - 1;
                NSCharacterSet *nlcs = [NSCharacterSet newlineCharacterSet];
                NSRange range = [string rangeOfCharacterFromSet:nlcs
                                                        options:NSBackwardsSearch
                                                          range:NSMakeRange(0, firstSearchIndex)];
                
                if (range.location == NSNotFound)
                {
                    result = [NKTTextPosition textPositionWithIndex:0];
                }
                else
                {
                    result = [NKTTextPosition textPositionWithIndex:range.location + 1];
                }
            }
        }
    }
    else if (granularity == UITextGranularityWord)
    {
        if (direction == UITextStorageDirectionForward || direction == UITextLayoutDirectionRight)
        {
            NSString *string = [textView_.text string];
            
            if (position.index == [string length])
            {
                result = [NKTTextPosition textPositionWithIndex:[string length]];
            }
            else
            {            
                unichar c = [string characterAtIndex:position.index];
                NSCharacterSet *wscset = [NSCharacterSet whitespaceAndNewlineCharacterSet];
                NSCharacterSet *puncset = [NSCharacterSet punctuationCharacterSet];
                
                // if char at position is non-whitespace, advance to first whitespace
                if (![wscset characterIsMember:c] && ![puncset characterIsMember:c])
                {
                    NSUInteger index = position.index + 1;
                    
                    for (; index < [string length]; ++index)
                    {
                        c = [string characterAtIndex:index];
                        
                        if ([wscset characterIsMember:c] || [puncset characterIsMember:c])
                        {
                            break;
                        }
                    }
                    
                    result = [NKTTextPosition textPositionWithIndex:index];
                }
                // else advance to first non-whitespace
                else
                {
                    NSUInteger index = position.index + 1;
                    
                    for (; index < [string length]; ++index)
                    {
                        c = [string characterAtIndex:index];
                        
                        if (![wscset characterIsMember:c] && ![puncset characterIsMember:c])
                        {
                            break;
                        }
                    }
                    
                    result = [NKTTextPosition textPositionWithIndex:index];
                }
            }
        }
        else if (direction == UITextStorageDirectionBackward || direction == UITextLayoutDirectionLeft)
        {
            NSString *string = [textView_.text string];
            
            if (position.index == 0)
            {
                result = [NKTTextPosition textPositionWithIndex:0];
            }
            else
            {
                unichar c = [string characterAtIndex:position.index - 1];
                NSCharacterSet *wscset = [NSCharacterSet whitespaceAndNewlineCharacterSet];
                NSCharacterSet *puncset = [NSCharacterSet punctuationCharacterSet];
                
                // if char before position is non-whitespace, advance to last non-whitespace
                if (![wscset characterIsMember:c] && ![puncset characterIsMember:c])
                {
                    NSUInteger index = position.index - 1;
                    
                    for (; index > 0; --index)
                    {
                        c = [string characterAtIndex:index];
                        
                        if ([wscset characterIsMember:c] || [puncset characterIsMember:c])
                        {
                            // go back to subsequent character
                            ++index;
                            break;
                        }
                    }
                    
                    result = [NKTTextPosition textPositionWithIndex:index];
                }
                // else advance to last whitespace
                else
                {
                    NSUInteger index = position.index - 1;
                    
                    for (; index > 0; --index)
                    {
                        c = [string characterAtIndex:index];
                        
                        if (![wscset characterIsMember:c] && ![puncset characterIsMember:c])
                        {
                            // go back to subsequent char
                            ++index;
                            break;
                        }
                    }
                    
                    result = [NKTTextPosition textPositionWithIndex:index];
                }
            }
        }
    }
    else
    {
        result = [super positionFromPosition:position toBoundary:granularity inDirection:direction];
    }
    
    KBCLogDebug(@"result:%d", ((NKTTextPosition *)result).index);
    
    return result;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Ranges of Specific Text Units

- (UITextRange *)rangeEnclosingPosition:(NKTTextPosition *)position
                        withGranularity:(UITextGranularity)granularity
                            inDirection:(UITextDirection)direction
{
    KBCLogDebug(@"pos:%d gran:%@ dir:%@",
                position.index,
                StringFromGranularity(granularity),
                StringFromDirection(direction));
    
    UITextRange *result = nil;
    
    if (granularity == UITextGranularityLine)
    {
        result = [textView_ textRangeForLineEnclosingTextPosition:position inDirection:direction];
    }
    else
    {
        result = [super rangeEnclosingPosition:position withGranularity:granularity inDirection:direction];
    }
    
    KBCLogDebug(@"result:%@", NSStringFromRange(((NKTTextRange *)result).NSRange));
    
    return result;
}

@end
