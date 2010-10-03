//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaCore.h"

CFRange CFRangeFromNSRange(NSRange range)
{
    return CFRangeMake((CFIndex)range.location, (CFIndex)range.length);
}
