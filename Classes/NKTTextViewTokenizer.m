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
    BOOL result = NO;
    
    if (granularity == UITextGranularityLine)
    {
        result = [textView_ isTextPosition:position atLineBoundaryInDirection:direction];
    }
    else
    {
        result = [super isPosition:position atBoundary:granularity inDirection:direction];
    }
    
    
    KBCLogDebug(@"pos:%d gran:%@ dir:%@ result:%d",
                position.index,
                StringFromGranularity(granularity),
                StringFromDirection(direction),
                result);
    
    return result;
}

- (BOOL)isPosition:(NKTTextPosition *)position
    withinTextUnit:(UITextGranularity)granularity
       inDirection:(UITextDirection)direction
{    
    BOOL result = NO;
    
    if (granularity == UITextGranularityLine)
    {
        result = [textView_ isTextPosition:position withinLineInDirection:direction];
    }
    else
    {
        result = [super isPosition:position withinTextUnit:granularity inDirection:direction];
    }
    
    KBCLogDebug(@"pos:%d gran:%@ dir:%@ result:%d",
                position.index,
                StringFromGranularity(granularity),
                StringFromDirection(direction),
                result);
    
    return result;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Computing Text Position by Unit Boundaries

- (UITextPosition *)positionFromPosition:(NKTTextPosition *)position
                              toBoundary:(UITextGranularity)granularity
                             inDirection:(UITextDirection)direction
{
    UITextPosition *result = nil;

    if (granularity == UITextGranularityLine)
    {
        result = [textView_ positionFromTextPosition:position toLineBoundaryInDirection:direction];
    }
    else
    {
        result = [super positionFromPosition:position toBoundary:granularity inDirection:direction];
    }
    
    KBCLogDebug(@"pos:%d gran:%@ dir:%@ result:%d",
                position.index,
                StringFromGranularity(granularity),
                StringFromDirection(direction),
                ((NKTTextPosition *)result).index);
    
    return result;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Getting Ranges of Specific Text Units

- (UITextRange *)rangeEnclosingPosition:(NKTTextPosition *)position
                        withGranularity:(UITextGranularity)granularity
                            inDirection:(UITextDirection)direction
{
    UITextRange *result = nil;
    
    if (granularity == UITextGranularityLine)
    {
        result = [textView_ textRangeForLineEnclosingTextPosition:position inDirection:direction];
    }
    else
    {
        result = [super rangeEnclosingPosition:position withGranularity:granularity inDirection:direction];
    }
    
    KBCLogDebug(@"pos:%d gran:%@ dir:%@ result:%@",
                position.index,
                StringFromGranularity(granularity),
                StringFromDirection(direction),
                NSStringFromRange(((NKTTextRange *)result).NSRange));
    
    return result;
}

@end
