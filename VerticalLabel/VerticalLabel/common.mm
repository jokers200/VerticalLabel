//
//  common.m
//  VerticalLabel
//
//  Created by LiuGang on 16/3/15.
//  Copyright © 2016年 test. All rights reserved.
//
#import "common.h"

CGPoint LeftTopPoint(CGRect rect) {
    return rect.origin;
}

CGPoint LeftBottomPoint(CGRect rect) {
    CGPoint pt = rect.origin;
    pt.y += rect.size.height;
    return pt;
}

CGPoint RightTopPoint(CGRect rect) {
    CGPoint pt = rect.origin;
    pt.x += rect.size.width;
    return pt;
}

CGPoint RightBottomPoint(CGRect rect) {
    CGPoint pt = rect.origin;
    pt.x += rect.size.width;
    pt.y += rect.size.height;
    return pt;
}

CGPoint CenterPoint(CGRect rect) {
    CGPoint point = {rect.origin.x + rect.size.width / 2,
        rect.origin.y + rect.size.height / 2};
    return point;
}

CGRect CenterRect(CGRect rect, float width, float height) {
    CGPoint pt = CenterPoint(rect);
    return CGRectMake(pt.x - width/2,
                      pt.y - height/2,
                      width,
                      height);
}

int ScreenHeight()
{
    return MAX([[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
}
