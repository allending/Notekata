//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KBMGeometry.h"

CGPoint KBMClampPointToRect(CGPoint point, CGRect rect)
{
    CGPoint clampedPoint = point;
    clampedPoint.x = MAX(clampedPoint.x, CGRectGetMinX(rect));
    clampedPoint.x = MIN(clampedPoint.x, CGRectGetMaxX(rect));
    clampedPoint.y = MAX(clampedPoint.y, CGRectGetMinY(rect));
    clampedPoint.y = MIN(clampedPoint.y, CGRectGetMaxY(rect));
    return clampedPoint;
}
