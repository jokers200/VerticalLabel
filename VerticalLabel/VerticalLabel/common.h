//
//  common.h
//  VerticalLabel
//
//  Created by LiuGang on 16/3/16.
//  Copyright © 2016年 test. All rights reserved.
//

#ifndef common_h
#define common_h
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifdef __cplusplus
extern "C" {
#endif

    CGPoint LeftTopPoint(CGRect rect);
    CGPoint LeftBottomPoint(CGRect rect);
    CGPoint RightTopPoint(CGRect rect);
    CGPoint RightBottomPoint(CGRect rect);
    CGRect CenterRect(CGRect rect, float width, float height);
    int ScreenHeight();

#ifdef __cplusplus
}
#endif

#endif /* common_h */
