//
//  UIAttributeLabelController.h
//  VerticalLabel
//
//  Created by LiuGang on 16/3/16.
//  Copyright © 2016年 test. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, LabelStyle) {
    LabelStyle0,
    LabelStyle1,
    LabelStyle2,
    LabelStyle3,
    LabelStyleMax,
};

@interface UIAttributeLabelController : UIViewController
@property (nonatomic, assign) LabelStyle styleType;
@property (nonatomic, copy) NSString* text;
@end
