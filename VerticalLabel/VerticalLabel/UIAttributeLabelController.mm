//
//  UIAttributeLabelController.m
//  VerticalLabel
//
//  Created by LiuGang on 16/3/16.
//  Copyright © 2016年 test. All rights reserved.
//

#import "UIAttributeLabelController.h"
#import "YCAttributeVerticalLabel.h"
#import "common.h"

@interface UIAttributeLabelController ()<YCAttributeLabelVerticalDelegate>
@property (nonatomic, strong) YCAttributeVerticalLabel* label;
@end

@implementation UIAttributeLabelController
- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    view.backgroundColor = [UIColor blackColor];
    self.view = view;
}

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.view.backgroundColor = [UIColor clearColor];
    // Do any additional setup after loading the view, typically from a nib.
    self.label = [[YCAttributeVerticalLabel alloc]initWithFrame:self.view.bounds];
    self.label.delegate = self;
    self.label.backgroundColor = [UIColor clearColor];
    [self updateLabel];
    [self.view addSubview:self.label];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGSize size = [self.label sizeThatFits:self.view.bounds.size];
    self.label.frame = CGRectMake(0, 0, size.width, size.height);
    self.label.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateLabel
{
    NSString* text = [self text];
    UIFont* font = [UIFont fontWithName:@"Heiti SC" size:14];
    
    NSMutableAttributedString* attriString = [[NSMutableAttributedString alloc]initWithString:text];
    
    UIColor* color = [UIColor whiteColor];

    //    leading = 0;
    NSMutableParagraphStyle* para = [[NSMutableParagraphStyle alloc]init];
    para.lineSpacing = 0;
    para.headIndent = 0;
    para.paragraphSpacing = 4;
    para.paragraphSpacingBefore = 0;

    if (self.styleType == LabelStyle0) {
        [attriString addAttributes:@{NSForegroundColorAttributeName:color,
                                     NSFontAttributeName:font,
                                     NSParagraphStyleAttributeName:para,
                                     kYCTTTTextLineWriteDirectionAttributeName:@(YCTextWriteDirectionLeftToRight),
                                     kYCTTTTextLineAlignmentAttributeName:@(YCTextAlignmentCenter),
                                     kYCTTTTextLineLeadingAttributeName:@(0),}
                             range:NSMakeRange(0, text.length)];
    }
    else if (self.styleType == LabelStyle1){
        [attriString addAttributes:@{NSForegroundColorAttributeName:color,
                                     NSFontAttributeName:font,
                                     NSParagraphStyleAttributeName:para,
                                     kYCTTTTextLineWriteDirectionAttributeName:@(YCTextWriteDirectionRightToLeft),
                                     kYCTTTTextLineAlignmentAttributeName:@(YCTextAlignmentCenter),
                                     kYCTTTTextLineLeadingAttributeName:@(0),
                                     kYCTTTBackgroundStrokeColorAttributeName:color,
                                     kYCTTTBackgroundLineWidthAttributeName:@(1.5),
                                     kYCTTTBackgroundStrokeLineAttributeName:@(YCTTTStrokeLineLine),
                                     kYCTTTBackgroundStrokeLinePositionAttributeName:@(YCTTTStrokeLinePositionRight)}
                             range:NSMakeRange(0, text.length)];
        
    }
    else if (self.styleType == LabelStyle2){
        [attriString addAttributes:@{NSForegroundColorAttributeName:color,
                                     NSFontAttributeName:font,
                                     NSParagraphStyleAttributeName:para,
                                     kYCTTTTextLineWriteDirectionAttributeName:@(YCTextWriteDirectionRightToLeft),
                                     kYCTTTTextLineAlignmentAttributeName:@(YCTextAlignmentTop),
                                     kYCTTTTextLineLeadingAttributeName:@(0)}
                             range:NSMakeRange(0, text.length)];
        
    }
    else if (self.styleType == LabelStyle3){
        [attriString addAttributes:@{NSForegroundColorAttributeName:color,
                                     NSFontAttributeName:font,
                                     NSParagraphStyleAttributeName:para,
                                     kYCTTTTextLineWriteDirectionAttributeName:@(YCTextWriteDirectionLeftToRight),
                                     kYCTTTTextLineAlignmentAttributeName:@(YCTextAlignmentTop),
                                     kYCTTTTextLineLeadingAttributeName:@(0),
                                     kYCTTTBackgroundStrokeColorAttributeName:color,
                                     kYCTTTBackgroundLineWidthAttributeName:@(1.5),
                                     kYCTTTBackgroundStrokeLineAttributeName:@(YCTTTStrokeLineLine),
                                     kYCTTTBackgroundStrokeLinePositionAttributeName:@(YCTTTStrokeLinePositionLeftTopCorner|YCTTTStrokeLinePositionRightBottomCorner),
                                     kYCTTTBackgroundCornerLineLengthAttributeName:@(10)}
                             range:NSMakeRange(0, text.length)];
        
    }

    self.label.attributedText = attriString;
}
@end
