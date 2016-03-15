//
//  YCAttributeLabelCommon.h

#import <CoreText/CoreText.h>
#ifndef YCAttributeLabelCommon_h
#define YCAttributeLabelCommon_h

typedef NS_ENUM(NSInteger, YCTextAlignment) {
    YCTextAlignmentLeft      = NSTextAlignmentLeft,    // Visually left aligned
    YCTextAlignmentCenter    = NSTextAlignmentCenter,    // Visually centered
    YCTextAlignmentRight     = NSTextAlignmentRight,    // Visually right aligned
    YCTextAlignmentTop     = 10,    // Visually top aligned
    YCTextAlignmentBottom    = 11,    // Visually bottom
};

typedef NS_ENUM(NSUInteger, YCTextDirectionFormat) {
    YCTextFormatVertical, //竖版
    YCTextFormatHorizonal //横版
};

typedef NS_ENUM(NSUInteger, YCTextWriteDirection) {
    YCTextWriteDirectionLeftToRight = kCTFrameProgressionLeftToRight,
    YCTextWriteDirectionRightToLeft = kCTFrameProgressionRightToLeft
};

typedef NS_ENUM(NSUInteger, YCTTTStrokeLineType) {
    YCTTTStrokeLineNone,
    YCTTTStrokeLineWord,
    YCTTTStrokeLineLine,
    YCTTTStrokeLineAll,
};

typedef NS_ENUM(NSUInteger, YCTTTStrokeLinePositionType) {
    YCTTTStrokeLinePositionNone     = 0,
    YCTTTStrokeLinePositionLeft     = 1<<0,
    YCTTTStrokeLinePositionRight    = 1<<1,
    YCTTTStrokeLinePositionTop      = 1<<2,
    YCTTTStrokeLinePositionBottom   = 1<<3,
    YCTTTStrokeLinePositionLeftTopCorner     = 1<<4,
    YCTTTStrokeLinePositionRightTopCorner    = 1<<5,
    YCTTTStrokeLinePositionLeftBottomCorner  = 1<<6,
    YCTTTStrokeLinePositionRightBottomCorner = 1<<7,
    YCTTTStrokeLinePositionAll = YCTTTStrokeLinePositionLeft|YCTTTStrokeLinePositionRight|YCTTTStrokeLinePositionTop|YCTTTStrokeLinePositionBottom,
    YCTTTStrokeLinePositionAllCorner = YCTTTStrokeLinePositionLeftTopCorner|YCTTTStrokeLinePositionRightTopCorner|YCTTTStrokeLinePositionLeftBottomCorner|YCTTTStrokeLinePositionRightBottomCorner
};

static NSString * const kYCTTTBackgroundFillColorAttributeName = @"TTTBackgroundFillColor";
static NSString * const kYCTTTBackgroundFillPaddingAttributeName = @"TTTBackgroundFillPadding";
static NSString * const kYCTTTBackgroundStrokeColorAttributeName = @"TTTBackgroundStrokeColor";
static NSString * const kYCTTTBackgroundLineWidthAttributeName = @"TTTBackgroundLineWidth";
static NSString * const kYCTTTBackgroundCornerRadiusAttributeName = @"TTTBackgroundCornerRadius";
static NSString * const kYCTTTBackgroundCornerLineLengthAttributeName = @"TTTBackgroundCornerLineLength";
static NSString * const kYCTTTBackgroundStrokeLineAttributeName = @"TTTBackgroundStrokeLine";
static NSString * const kYCTTTBackgroundStrokeLinePositionAttributeName = @"TTTBackgroundStrokeLinePosition";
static NSString * const kYCTTTTextLineAlignmentAttributeName = @"TTTTextLineAlignment";
static NSString * const kYCTTTTextLinePathAttributeName = @"TTTTextLinePath";
static NSString * const kYCTTTTextLineLeadingAttributeName = @"TTTTextLineLeading";
static NSString * const kYCTTTTextLineWriteDirectionAttributeName = @"TTTTextLineWriteDirection";//左到右或者右到左
static NSString * const kYCTTTTextLineFormatDirectionAttributeName = @"TTTTextLineFormatDirection";//横版竖版

#define CFRANGE_TO_NSRANGE(cfrange) NSMakeRange(cfrange.location, cfrange.length)
#define NSRANGE_TO_CFRANGE(nsrange) CFRangeMake(nsrange.location, nsrange.length)
#define DEFAULT_LINE_WIDTH (1.0f)
#define DEFAULT_CORNER_LENGTH (15.0f)
#define DEFAULT_PADDING (5.0f)

static inline CGFLOAT_TYPE CGFloat_ceil(CGFLOAT_TYPE cgfloat) {
#if CGFLOAT_IS_DOUBLE
    return ceil(cgfloat);
#else
    return ceilf(cgfloat);
#endif
}

static inline CGFLOAT_TYPE CGFloat_floor(CGFLOAT_TYPE cgfloat) {
#if CGFLOAT_IS_DOUBLE
    return floor(cgfloat);
#else
    return floorf(cgfloat);
#endif
}

static inline CGFLOAT_TYPE CGFloat_round(CGFLOAT_TYPE cgfloat) {
#if CGFLOAT_IS_DOUBLE
    return round(cgfloat);
#else
    return roundf(cgfloat);
#endif
}


#endif /* YCAttributeLabelCommon_h */
