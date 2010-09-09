//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KBCMath.h"

CGFloat KBCClamp(CGFloat value, CGFloat min, CGFloat max)
{
    if (value < min)
    {
        value = min;
    }
    
    if (value > max)
    {
        value = max;
    }
    
    return value;
}
