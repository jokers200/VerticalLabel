//
//  UIBezierPath+points.m

#import "UIBezierPath+points.h"

#define VALUE(pt) [NSValue valueWithCGPoint:pt]
#define POINT(pt) [(NSValue *)pt CGPointValue]

@implementation UIBezierPath (points)
void getPointsFromBezier(void *info, const CGPathElement *element)
{
    NSMutableDictionary* dic = (__bridge NSMutableDictionary*)info;
    NSMutableArray *bezierPoints = [dic objectForKey:@"points"];
    CGPoint pt = [[dic objectForKey:@"inputPoint"] CGPointValue];
    
    // Retrieve the path element type and its points
    CGPathElementType type = element->type;
    CGPoint *points = element->points;
    
    CGPoint lastPt = [[bezierPoints lastObject] CGPointValue];
    
    switch (type) {
        case kCGPathElementMoveToPoint:
            
            break;
        case kCGPathElementAddLineToPoint:
            if ((lastPt.x <= pt.x && points[0].x >= pt.x)
                ||(lastPt.x >= pt.x && points[0].x <= pt.x)) {
                pt.y = (lastPt.y - points[0].y)*pt.x/(lastPt.x - points[0].x);
            }

            break;
        case kCGPathElementAddCurveToPoint:
//            pt.y = [Calculation calcWithA:lastPt andB:points[0] andC:points[1] andD:points[2] andXy:pt.x];
            break;
            
        default:
            break;
    }
    if (pt.y < CGFLOAT_MAX) {
        [dic setObject:VALUE(pt) forKey:@"inputPoint"];
    }
    // Add the points if they're available (per type)
    if (type != kCGPathElementCloseSubpath)
    {
        [bezierPoints addObject:VALUE(points[0])];
        if ((type != kCGPathElementAddLineToPoint) &&
            (type != kCGPathElementMoveToPoint))
            [bezierPoints addObject:VALUE(points[1])];
    }
    if (type == kCGPathElementAddCurveToPoint)
        [bezierPoints addObject:VALUE(points[2])];
}

- (NSArray*)points
{
    NSMutableArray *points = [NSMutableArray array];
    CGPathApply(self.CGPath, (__bridge void *)points, getPointsFromBezier);
    return points;
}

- (float)yForX:(float)x
{
    float y = 0;
    CGPoint pt = CGPointMake(x, CGFLOAT_MAX);
    id Point = [NSValue valueWithCGPoint:pt];
    NSMutableArray *bezierPoints = [NSMutableArray array];
    NSMutableDictionary* dic = [NSMutableDictionary dictionary];
    [dic setObject:bezierPoints forKey:@"points"];
    [dic setObject:Point forKey:@"inputPoint"];
    
    CGPathApply(self.CGPath, (__bridge void * _Nullable)(dic), getPointsFromBezier);
    y = [[dic objectForKey:@"inputPoint"]CGPointValue].y;
    return y;
}
@end
