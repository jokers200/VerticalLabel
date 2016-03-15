//
//  YCAttributeVerticalLabel.h


#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#import "YCAttributeLabelCommon.h"

@class YCAttributeVerticalLabel;
@protocol YCAttributeLabelVerticalDelegate <NSObject>
@optional
- (void)attributeVerticalLabel:(YCAttributeVerticalLabel*)label willDrawLineWithAttribute:(NSMutableAttributedString*)attribute range:(NSRange)range lineIndex:(NSInteger)index lineCount:(NSInteger)count;
- (void)attributeVerticalLabel:(YCAttributeVerticalLabel*)label willDrawLineBackgroundWithAttribute:(NSMutableAttributedString*)attribute range:(NSRange)range lineIndex:(NSInteger)index lineCount:(NSInteger)count;
- (UIBezierPath*)attributeVerticalLabel:(YCAttributeVerticalLabel*)label willDrawLineInBounds:(CGRect)bounds withAttribute:(NSMutableAttributedString*)attribute range:(NSRange)range lineIndex:(NSInteger)index lineCount:(NSInteger)count;
@end

@interface YCAttributeVerticalLabel : UIView

@property (readwrite, nonatomic, copy) NSMutableAttributedString *attributedText;
@property (nonatomic, assign) NSInteger numberOfLines;
@property (nonatomic, assign) id<YCAttributeLabelVerticalDelegate> delegate;
@property (nonatomic, assign) UIEdgeInsets contentInsets;

- (CGSize)sizeThatFitsForText:(CGSize)size;

@end
