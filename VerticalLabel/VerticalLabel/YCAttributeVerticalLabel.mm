//
//  YCAttributeVerticalLabel.m


#import "YCAttributeVerticalLabel.h"
#import <QuartzCore/QuartzCore.h>
#import <Availability.h>
#import "UIBezierPath+points.h"
#import "common.h"

typedef struct CustomGlyphMetrics {
    CGFloat ascent;
    CGFloat descent;
    CGFloat width;
} CustomGlyphMetrics,*CustomGlyphMetricsRef;

static void deallocCallback(void *refCon) {
    if(refCon) free(refCon), refCon = NULL;
}

static CGFloat ascentCallback(void *refCon) {
    CustomGlyphMetricsRef metrics = (CustomGlyphMetricsRef)refCon;
    return metrics->ascent;
}

static CGFloat descentCallback(void *refCon) {
    CustomGlyphMetricsRef metrics = (CustomGlyphMetricsRef)refCon;
    return metrics->descent;
}

static CGFloat widthCallback(void *refCon) {
    CustomGlyphMetricsRef metrics = (CustomGlyphMetricsRef)refCon;
    return metrics->width;
}


static inline CGFloat TTTFlushFactorForTextAlignment(YCTextAlignment textAlignment) {
    switch (textAlignment) {
        case NSTextAlignmentCenter:
            return 0.5f;
        case YCTextAlignmentBottom:
            return 1.0f;
        case YCTextAlignmentTop:
        default:
            return 0.0f;
    }
}

@interface YCAttributeVerticalLabel ()
{
    BOOL _needsFramesetter;
    CTFramesetterRef _framesetter;
    UIEdgeInsets _internalInsets;
}
@end

@implementation YCAttributeVerticalLabel
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.contentInsets = UIEdgeInsetsMake(DEFAULT_PADDING, DEFAULT_PADDING, DEFAULT_PADDING, DEFAULT_PADDING);;
    }
    return self;
}

- (void)dealloc
{
    if (_framesetter) {
        CFRelease(_framesetter);
    }
    self.attributedText = nil;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {

    // Drawing code
    if (self.attributedText.length > 0) {
        [self drawTextInRect:rect];
    }
}

- (void)drawTextInRect:(CGRect)rect {
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextClearRect(c, rect);
    CGContextSaveGState(c);
    {
        CGContextSetTextMatrix(c, CGAffineTransformIdentity);
        
        // Inverts the CTM to match iOS coordinates (otherwise text draws upside-down; Mac OS's system is different)
        CGContextTranslateCTM(c, 0.0f, rect.size.height);
        CGContextScaleCTM(c, 1.0f, -1.0f);
        
        CGRect textRect = UIEdgeInsetsInsetRect(rect, self.contentInsets);;
        CFRange textRange = CFRangeMake(0, (CFIndex)[self.attributedText length]);
        textRect = UIEdgeInsetsInsetRect(textRect, _internalInsets);
        // First, get the text rect (which takes vertical centering into account)
        // CoreText draws it's text aligned to the bottom, so we move the CTM here to take our vertical offsets into account
        CGContextTranslateCTM(c, textRect.origin.x, rect.size.height - textRect.origin.y - textRect.size.height);
        
        [self drawFramesetter:[self framesetter] attributedString:self.attributedText textRange:textRange inRect:textRect context:c];
    }
    CGContextRestoreGState(c);
  
}

- (void)setAttributedText:(NSMutableAttributedString *)text {
    if ([text isEqualToAttributedString:_attributedText]) {
        return;
    }
    
    _attributedText = [text mutableCopy];
    [_attributedText addAttribute:(NSString *)kCTVerticalFormsAttributeName value:[NSNumber numberWithBool:YES] range:NSMakeRange(0, _attributedText.length)];
    
    [self setNeedsFramesetter];
    [self setNeedsDisplay];
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    if ([self respondsToSelector:@selector(invalidateIntrinsicContentSize)]) {
        [self invalidateIntrinsicContentSize];
    }
#endif
}

- (void)setNeedsFramesetter {
    // Reset the rendered attributed text so it has a chance to regenerate
    _needsFramesetter = YES;
}

- (CTFramesetterRef)framesetter {
    if (_needsFramesetter) {
        @synchronized(self) {
            CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.attributedText);
            [self setFramesetter:framesetter];
            _needsFramesetter = NO;
            
            if (framesetter) {
                CFRelease(framesetter);
            }
        }
    }
    
    return _framesetter;
}

- (void)setFramesetter:(CTFramesetterRef)framesetter {
    if (framesetter) {
        CFRetain(framesetter);
    }
    
    if (_framesetter) {
        CFRelease(_framesetter);
    }
    
    _framesetter = framesetter;
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize retSize = [self sizeThatFitsForText:size];
    if (CGSizeEqualToSize(retSize, CGSizeZero)) {
        return CGSizeZero;
    }
    retSize.width += self.contentInsets.left + self.contentInsets.right + _internalInsets.left + _internalInsets.right;
    retSize.height += self.contentInsets.top + self.contentInsets.bottom + _internalInsets.top + _internalInsets.bottom;
    return retSize;
}

- (CGSize)sizeThatFitsForText:(CGSize)size
{
    if (self.attributedText.length == 0) {
        return CGSizeZero;
    }
    CGSize realSize = CGSizeMake(size.width - self.contentInsets.left - self.contentInsets.right - _internalInsets.left - _internalInsets.right, size.height - self.contentInsets.top - self.contentInsets.bottom);

    CGSize retSize = [self CTFramesetterSuggestFrameSizeForAttributedStringWithConstraints:[self framesetter] attributedString:self.attributedText size:realSize numberOfLines:self.numberOfLines];
    return retSize;
}

- (void)drawFramesetter:(CTFramesetterRef)framesetter
       attributedString:(NSAttributedString *)attributedString
              textRange:(CFRange)textRange
                 inRect:(CGRect)rect
                context:(CGContextRef)c
{
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, rect);
    YCTextWriteDirection writeDir = YCTextWriteDirectionRightToLeft;
    NSDictionary* dic = [attributedString attributesAtIndex:textRange.location effectiveRange:NULL];
    if ([dic objectForKey:kYCTTTTextLineWriteDirectionAttributeName]) {
        writeDir = (YCTextWriteDirection)[[dic objectForKey:kYCTTTTextLineWriteDirectionAttributeName]integerValue];
    }

    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, textRange, path, (CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedLong:writeDir], (NSString *)kCTFrameProgressionAttributeName, nil]);
    
    CFArrayRef lines = CTFrameGetLines(frame);
    NSInteger numberOfLines = self.numberOfLines > 0 ? MIN(self.numberOfLines, CFArrayGetCount(lines)) : CFArrayGetCount(lines);

    BOOL truncateLastLine = YES;
    CGPoint lineOrigins[numberOfLines];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, numberOfLines), lineOrigins);
    float linespace = 0;
    if ([dic objectForKey:kYCTTTTextLineLeadingAttributeName]) {
        linespace = [[dic objectForKey:kYCTTTTextLineLeadingAttributeName]floatValue];
    }
    
    CGFloat heightOffset = 0;
    for (CFIndex lineIndex = 0; lineIndex < numberOfLines; lineIndex++) {
        CGPoint lineOrigin = lineOrigins[lineIndex];
        lineOrigin = CGPointMake(CGFloat_ceil(lineOrigin.x), CGFloat_ceil(lineOrigin.y));
        CTLineRef line = (CTLineRef)CFArrayGetValueAtIndex(lines, lineIndex);
        CFRange lineRange = CTLineGetStringRange(line);
        
        if ([self.delegate respondsToSelector:@selector(attributeVerticalLabel:willDrawLineWithAttribute:range:lineIndex:lineCount:)]) {
            [self.delegate attributeVerticalLabel:self
                        willDrawLineWithAttribute:(NSMutableAttributedString*)attributedString
                                            range:CFRANGE_TO_NSRANGE(lineRange)
                                        lineIndex:lineIndex
                                        lineCount:numberOfLines];
        }
        
        NSDictionary* dic = [attributedString attributesAtIndex:lineRange.location effectiveRange:NULL];
        if ([dic objectForKey:kYCTTTTextLinePathAttributeName]) {
            UIBezierPath* path = [dic objectForKey:kYCTTTTextLinePathAttributeName];
            CGRect bounds = [path bounds];
            heightOffset += bounds.size.width;
        }
        lineOrigin.x += heightOffset;
        if (writeDir == YCTextWriteDirectionLeftToRight) {
            lineOrigin.x += linespace*lineIndex;
        }
        else{
            lineOrigin.x -= linespace*lineIndex;
        }
        
        CGContextSetTextPosition(c, lineOrigin.x, lineOrigin.y);
        
        CGFloat ascent = 0.0f;
        CGFloat descent = 0.0f;
        CGFloat leading = 0.0f;
        CGFloat width = 0.0f;
        width = CTLineGetTypographicBounds((CTLineRef)line, &ascent, &descent, &leading);
        NSLog(@"lineOr=%@,ac=%f,des=%f,lead=%f,width=%f",NSStringFromCGPoint(lineOrigin),ascent,descent,leading,width);

        //使用besierPath绘制文字布局路径
        UIBezierPath* path = nil;
        if ([self.delegate respondsToSelector:@selector(attributeVerticalLabel:willDrawLineInBounds:withAttribute:range:lineIndex:lineCount:)]) {
            path = [self.delegate attributeVerticalLabel:self
                                    willDrawLineInBounds:CGRectMake(0, 0, rect.size.width, rect.size.height)
                                           withAttribute:self.attributedText
                                                   range:CFRANGE_TO_NSRANGE(lineRange)
                                               lineIndex:lineIndex
                                               lineCount:CFArrayGetCount(lines)];
            [path applyTransform:CGAffineTransformMakeScale(1, -1)];
            [path applyTransform:CGAffineTransformMakeTranslation(0, -path.bounds.size.height)];
        }

        NSParagraphStyle* para = [dic objectForKey:NSParagraphStyleAttributeName];
        if (!para) {
            para = [NSParagraphStyle defaultParagraphStyle];
        }
        NSTextAlignment textAlignment = para.alignment;
        if ([dic objectForKey:kYCTTTTextLineAlignmentAttributeName]) {
            textAlignment = (NSTextAlignment)[[dic objectForKey:kYCTTTTextLineAlignmentAttributeName]integerValue];
        }
        // Adjust pen offset for flush depending on text alignment
        CGFloat flushFactor = TTTFlushFactorForTextAlignment((YCTextAlignment)textAlignment);
        
        if (lineIndex == numberOfLines - 1 && truncateLastLine) {
            // Check if the range of text in the last line reaches the end of the full attributed string
            CFRange lastLineRange = CTLineGetStringRange(line);
            
            if (!(lastLineRange.length == 0 && lastLineRange.location == 0) && lastLineRange.location + lastLineRange.length < textRange.location + textRange.length) {
                // Get correct truncationType and attribute position
                CTLineTruncationType truncationType = kCTLineTruncationEnd;
                CFIndex truncationAttributePosition = lastLineRange.location + (lastLineRange.length - 1);
                
                NSDictionary *truncationTokenStringAttributes = [attributedString attributesAtIndex:(NSUInteger)truncationAttributePosition effectiveRange:NULL];
                NSString *truncationTokenString = @"\u2026";
                NSAttributedString *attributedTokenString = [[NSAttributedString alloc] initWithString:truncationTokenString attributes:truncationTokenStringAttributes];
                CTLineRef truncationToken = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)attributedTokenString);
                
                // Append truncationToken to the string
                // because if string isn't too long, CT wont add the truncationToken on it's own
                // There is no change of a double truncationToken because CT only add the token if it removes characters (and the one we add will go first)
                NSMutableAttributedString *truncationString = [[attributedString attributedSubstringFromRange:NSMakeRange((NSUInteger)lastLineRange.location, (NSUInteger)lastLineRange.length)] mutableCopy];
                if (lastLineRange.length > 0) {
                    // Remove any newline at the end (we don't want newline space between the text and the truncation token). There can only be one, because the second would be on the next line.
                    unichar lastCharacter = [[truncationString string] characterAtIndex:(NSUInteger)(lastLineRange.length - 1)];
                    if ([[NSCharacterSet newlineCharacterSet] characterIsMember:lastCharacter]) {
                        [truncationString deleteCharactersInRange:NSMakeRange((NSUInteger)(lastLineRange.length - 1), 1)];
                    }
                }
                [truncationString appendAttributedString:attributedTokenString];
                CTLineRef truncationLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)truncationString);
                
                // Truncate the line in case it is too long.
                CTLineRef truncatedLine = CTLineCreateTruncatedLine(truncationLine, rect.size.height, truncationType, truncationToken);
                if (!truncatedLine) {
                    // If the line is not as wide as the truncationToken, truncatedLine is NULL
                    CFRetain(truncationToken);
                    truncatedLine = truncationToken;
                }
                
                CGFloat penOffset = (CGFloat)CTLineGetPenOffsetForFlush(truncatedLine, flushFactor, rect.size.height);
                CGContextSetTextPosition(c, lineOrigin.x, lineOrigin.y-penOffset);
                
                [self drawLine:truncatedLine withContext:c origin:CGPointMake(lineOrigin.x, lineOrigin.y-penOffset) path:path];
                
                CFRelease(truncatedLine);
                CFRelease(truncationLine);
                CFRelease(truncationToken);
            } else {
                CGFloat penOffset = (CGFloat)CTLineGetPenOffsetForFlush(line, flushFactor, rect.size.height);
                CGContextSetTextPosition(c, lineOrigin.x, lineOrigin.y-penOffset);
                [self drawLine:line withContext:c origin:CGPointMake(lineOrigin.x, lineOrigin.y-penOffset) path:path];
            }
        } else {
            CGFloat penOffset = (CGFloat)CTLineGetPenOffsetForFlush(line, flushFactor, rect.size.height);
            CGContextSetTextPosition(c, lineOrigin.x, lineOrigin.y-penOffset);
            [self drawLine:line withContext:c origin:CGPointMake(lineOrigin.x, lineOrigin.y-penOffset) path:path];
        }
        
    }
    [self drawBackground:frame inRect:rect context:c];
    
    CFRelease(frame);
    CFRelease(path);
}

- (void)drawLine:(CTLineRef)line withContext:(CGContextRef)c origin:(CGPoint)lineOrigin path:(UIBezierPath*)path
{
    CFRange range = CTLineGetStringRange(line);
    NSDictionary* dic = [self.attributedText attributesAtIndex:range.location effectiveRange:NULL];
    CFArrayRef runs = CTLineGetGlyphRuns(line);
    for (int i = 0; i < CFArrayGetCount(runs); i++) {
        CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(runs, i);
        CFIndex count = CTRunGetGlyphCount(run);
        for (int j = 0; j < count; j++) {
            CGPoint point = {0};
            CTRunGetPositions(run, CFRangeMake(j, 1), &point);
            float yOffset = [path yForX:(lineOrigin.x+point.x)];
            if (yOffset > ScreenHeight()) {
                yOffset = 0;
            }
            float yStart = lineOrigin.y + yOffset;
            CGContextSetTextPosition(c, lineOrigin.x, yStart);
            NSShadow* shadow = [dic objectForKey:NSShadowAttributeName];
            if (shadow) {
                UIColor* shadowColor = shadow.shadowColor;
                CGContextSetShadowWithColor(c, shadow.shadowOffset, shadow.shadowBlurRadius, shadowColor.CGColor);
            }
            else{
                CGContextSetShadowWithColor(c, shadow.shadowOffset, shadow.shadowBlurRadius, [UIColor clearColor].CGColor);
            }

            CTRunDraw(run, c, CFRangeMake(j, 1));
            CGFloat ascent = 0;
            CGFloat descent = 0;
            CGFloat leading = 0;
            CGFloat width = CTRunGetTypographicBounds(run, CFRangeMake(j, 1), &ascent, &descent, &leading);
            NSLog(@"a=%f,d=%f,l=%f,w=%f",ascent,descent,leading,width);
        }
    }
}

- (void)drawBackground:(CTFrameRef)frame
                inRect:(CGRect)rect
               context:(CGContextRef)c
{
    NSArray *lines = (__bridge NSArray *)CTFrameGetLines(frame);
    CGPoint origins[[lines count]];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), origins);
    
    CGFloat heightOffset = 0;
    // Compensate for y-offset of text rect from vertical positioning
    CGFloat yOffset = 0;
    
    CFIndex lineIndex = 0;
    for (id line in lines) {
        lineIndex = [lines indexOfObject:line];
        CGFloat ascent = 0.0f, descent = 0.0f, leading = 0.0f;
        CGFloat width = (CGFloat)CTLineGetTypographicBounds((__bridge CTLineRef)line, &ascent, &descent, &leading) ;
        CGFloat whiteSpaceWidth = CTLineGetTrailingWhitespaceWidth((__bridge CTLineRef)line);
        width -= whiteSpaceWidth;
        CGRect lineBounds = CGRectMake(rect.origin.x, rect.origin.y, descent, width);
        CFRange lineRange = CTLineGetStringRange((__bridge CTLineRef)line);
        
        if ([self.delegate respondsToSelector:@selector(attributeVerticalLabel:willDrawLineBackgroundWithAttribute:range:lineIndex:lineCount:)]) {
            [self.delegate attributeVerticalLabel:self
              willDrawLineBackgroundWithAttribute:(self.attributedText)
                                            range:CFRANGE_TO_NSRANGE(lineRange)
                                        lineIndex:lineIndex
                                        lineCount:lines.count];
            
        }
        NSDictionary* dic = [self.attributedText attributesAtIndex:lineRange.location effectiveRange:NULL];
        NSParagraphStyle* para = [dic objectForKey:NSParagraphStyleAttributeName];
        if (!para) {
            para = [NSParagraphStyle defaultParagraphStyle];
        }
        NSTextAlignment textAlignment = para.alignment;
        if ([dic objectForKey:kYCTTTTextLineAlignmentAttributeName]) {
            textAlignment = (NSTextAlignment)[[dic objectForKey:kYCTTTTextLineAlignmentAttributeName]integerValue];
        }
        // Adjust pen offset for flush depending on text alignment
        CGFloat flushFactor = TTTFlushFactorForTextAlignment((YCTextAlignment)textAlignment);
        
        CGFloat penOffset = (CGFloat)CTLineGetPenOffsetForFlush((__bridge CTLineRef)line, flushFactor, rect.size.height);
        
        lineBounds.origin.x = origins[lineIndex].x;
        lineBounds.origin.y = origins[lineIndex].y;
        lineBounds.origin.y += heightOffset;
        {
            YCTTTStrokeLineType strokeLineType = (YCTTTStrokeLineType)[[dic objectForKey:kYCTTTBackgroundStrokeLineAttributeName] integerValue];
            if (strokeLineType == YCTTTStrokeLineLine) {
                UIEdgeInsets fillPadding = [[dic objectForKey:kYCTTTBackgroundFillPaddingAttributeName] UIEdgeInsetsValue];
                CGFloat cornerRadius = [[dic objectForKey:kYCTTTBackgroundCornerRadiusAttributeName] floatValue];
                CGFloat lineWidth = [[dic objectForKey:kYCTTTBackgroundLineWidthAttributeName] floatValue];
                lineWidth = MAX(lineWidth, DEFAULT_LINE_WIDTH);
                
                CGRect curLineBounds = lineBounds;
                
                CGFloat xOffset = 0.0f;
                CFIndex charIndex = lineRange.location;
                CGFloat adustPadding = 1;
                CGFloat secondOffset = 0;
                xOffset = CTLineGetOffsetForStringIndex((__bridge CTLineRef)line, charIndex, &secondOffset);
                curLineBounds.origin.x = curLineBounds.origin.x - fillPadding.left - adustPadding- descent/2;
                curLineBounds.origin.y = origins[lineIndex].y + yOffset - fillPadding.bottom;
                curLineBounds.origin.y -= penOffset;
                curLineBounds.size.width += (fillPadding.left+ fillPadding.right)+adustPadding*2;
                curLineBounds.size.height+= (fillPadding.top+ fillPadding.bottom);
                curLineBounds.origin.y -= curLineBounds.size.height;
                
                [self drawBackgroundRect:curLineBounds withAttribute:dic context:c];
            }
        }
        YCTTTStrokeLineType strokeLineType = (YCTTTStrokeLineType)[[dic objectForKey:kYCTTTBackgroundStrokeLineAttributeName] integerValue];
        if (strokeLineType == YCTTTStrokeLineWord){
            NSArray* glyphRuns = (__bridge NSArray *)CTLineGetGlyphRuns((__bridge CTLineRef)line);
            for (id glyphRun in glyphRuns) {
                CFRange range = CTRunGetStringRange((CTRunRef)glyphRun);
                NSString *str = [[[self.attributedText string]substringWithRange:CFRANGE_TO_NSRANGE(range)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if(str.length == 0){
                    continue;
                }
                NSDictionary *attributes = (__bridge NSDictionary *)CTRunGetAttributes((__bridge CTRunRef) glyphRun);
                CGColorRef strokeColor;
                id color = [attributes objectForKey:kYCTTTBackgroundStrokeColorAttributeName];
                if ([color isKindOfClass:[UIColor class]]) {
                    strokeColor = ((UIColor*)color).CGColor;
                }
                else{
                    strokeColor = (__bridge CGColorRef)color;
                }
                
                CGColorRef fillColor;
                color = [attributes objectForKey:kYCTTTBackgroundFillColorAttributeName];
                if ([color isKindOfClass:[UIColor class]]) {
                    fillColor = ((UIColor*)color).CGColor;
                }
                else{
                    fillColor = (__bridge CGColorRef)color;
                }
                
                UIEdgeInsets fillPadding = [[attributes objectForKey:kYCTTTBackgroundFillPaddingAttributeName] UIEdgeInsetsValue];
                CGFloat cornerRadius = [[attributes objectForKey:kYCTTTBackgroundCornerRadiusAttributeName] floatValue];
                CGFloat lineWidth = [[attributes objectForKey:kYCTTTBackgroundLineWidthAttributeName] floatValue];
                lineWidth = MAX(lineWidth, DEFAULT_LINE_WIDTH);
                if (strokeColor || fillColor) {
                    CGRect runBounds = CGRectZero;
                    CGFloat runAscent = 0.0f;
                    CGFloat runDescent = 0.0f;
                    
                    runBounds.size.width = (CGFloat)CTRunGetTypographicBounds((__bridge CTRunRef)glyphRun, CFRangeMake(0, 0), &runAscent, &runDescent, NULL) + fillPadding.left + fillPadding.right;
                    runBounds.size.height = runAscent + runDescent + fillPadding.top + fillPadding.bottom;
                    
                    CGFloat xOffset = 0.0f;
                    CFRange glyphRange = CTRunGetStringRange((__bridge CTRunRef)glyphRun);
                    switch (CTRunGetStatus((__bridge CTRunRef)glyphRun)) {
                        case kCTRunStatusRightToLeft:
                            xOffset = CTLineGetOffsetForStringIndex((__bridge CTLineRef)line, glyphRange.location + glyphRange.length, NULL);
                            break;
                        default:
                            xOffset = CTLineGetOffsetForStringIndex((__bridge CTLineRef)line, glyphRange.location, NULL);
                            break;
                    }
                    
                    runBounds.origin.x = penOffset + rect.origin.x + xOffset - fillPadding.left - rect.origin.x;
                    runBounds.origin.y = origins[lineIndex].y + rect.origin.y + yOffset - fillPadding.bottom - rect.origin.y;
                    runBounds.origin.y += heightOffset;
                    runBounds.origin.y -= runDescent;
                    
                    // Don't draw higlightedLinkBackground too far to the right
                    if (CGRectGetWidth(runBounds) > CGRectGetWidth(lineBounds)) {
                        runBounds.size.width = CGRectGetWidth(lineBounds);
                    }
                    
                    CGPathRef path = [[UIBezierPath bezierPathWithRoundedRect:CGRectInset(runBounds, -lineWidth/2, -lineWidth/2) cornerRadius:cornerRadius] CGPath];
                    
                    CGContextSetLineJoin(c, kCGLineJoinRound);
                    
                    if (fillColor) {
                        CGContextSetFillColorWithColor(c, fillColor);
                        CGContextAddPath(c, path);
                        CGContextFillPath(c);
                    }
                    
                    if (strokeColor) {
                        CGContextSetLineWidth(c, lineWidth);
                        CGContextSetStrokeColorWithColor(c, strokeColor);
                        CGContextAddPath(c, path);
                        CGContextStrokePath(c);
                    }
                }
            }
        }
        if ([dic objectForKey:kYCTTTTextLinePathAttributeName]) {
            UIBezierPath* path = [dic objectForKey:kYCTTTTextLinePathAttributeName];
            CGRect bounds = [path bounds];
            heightOffset += bounds.size.height;
        }
    }
}

- (void)drawBackgroundRect:(CGRect)rect withAttribute:(NSDictionary*)attributeDic context:(CGContextRef)c
{
    NSDictionary* dic = attributeDic;
    CGRect curLineBounds = rect;
    
    id lineWidthObj = [dic objectForKey:kYCTTTBackgroundLineWidthAttributeName];
    CGFloat lineWidth = lineWidthObj? [lineWidthObj floatValue]:DEFAULT_LINE_WIDTH;
    UIEdgeInsets fillPadding = [[attributeDic objectForKey:kYCTTTBackgroundFillPaddingAttributeName] UIEdgeInsetsValue];
    CGFloat cornerRadius = [[attributeDic objectForKey:kYCTTTBackgroundCornerRadiusAttributeName] floatValue];
    
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    YCTTTStrokeLinePositionType strokeLineType = (YCTTTStrokeLinePositionType)[[dic objectForKey:kYCTTTBackgroundStrokeLinePositionAttributeName] integerValue];
    curLineBounds = CGRectInset(curLineBounds, -lineWidth/2, -lineWidth/2);
    if ((strokeLineType & YCTTTStrokeLinePositionAll) == YCTTTStrokeLinePositionAll) {
        bezierPath = [UIBezierPath bezierPathWithRoundedRect:curLineBounds cornerRadius:cornerRadius];
    }
    else{
        //加各个方向的边框
        if (strokeLineType & YCTTTStrokeLinePositionLeft) {
            [bezierPath moveToPoint:LeftBottomPoint(curLineBounds)];
            [bezierPath addLineToPoint:LeftTopPoint(curLineBounds)];
        }
        if (strokeLineType & YCTTTStrokeLinePositionBottom) {
            CGPoint startPt = LeftTopPoint(curLineBounds);
            if (!CGPointEqualToPoint(startPt, bezierPath.currentPoint)) {
                [bezierPath moveToPoint:startPt];
            }
            [bezierPath addLineToPoint:RightTopPoint(curLineBounds)];
        }
        if (strokeLineType & YCTTTStrokeLinePositionRight) {
            CGPoint startPt = RightTopPoint(curLineBounds);
            if (!CGPointEqualToPoint(startPt, bezierPath.currentPoint)) {
                [bezierPath moveToPoint:startPt];
            }
            [bezierPath addLineToPoint:RightBottomPoint(curLineBounds)];
        }
        if (strokeLineType & YCTTTStrokeLinePositionTop) {
            CGPoint startPt = RightBottomPoint(curLineBounds);
            if (!CGPointEqualToPoint(startPt, bezierPath.currentPoint)) {
                [bezierPath moveToPoint:startPt];
            }
            [bezierPath addLineToPoint:LeftBottomPoint(curLineBounds)];
            if(strokeLineType & YCTTTStrokeLinePositionLeft){
                [bezierPath closePath];
            }
        }
        
        CGFloat cornerLength = DEFAULT_CORNER_LENGTH;
        id cornerlenObj = [dic objectForKey:kYCTTTBackgroundCornerLineLengthAttributeName];
        if (cornerlenObj) {
            cornerLength = [cornerlenObj floatValue];
        }
        
        //加各个角
        if (strokeLineType & YCTTTStrokeLinePositionLeftTopCorner) {
            CGPoint leftTopPt = LeftBottomPoint(curLineBounds);
            [bezierPath moveToPoint:CGPointMake(leftTopPt.x, leftTopPt.y-cornerLength)];
            [bezierPath addLineToPoint:leftTopPt];
            [bezierPath addLineToPoint:CGPointMake(leftTopPt.x+cornerLength, leftTopPt.y)];
        }
        if (strokeLineType & YCTTTStrokeLinePositionRightTopCorner) {
            CGPoint rightTopPt = RightBottomPoint(curLineBounds);
            [bezierPath moveToPoint:CGPointMake(rightTopPt.x, rightTopPt.y-cornerLength)];
            [bezierPath addLineToPoint:rightTopPt];
            [bezierPath addLineToPoint:CGPointMake(rightTopPt.x-cornerLength, rightTopPt.y)];
        }
        if (strokeLineType & YCTTTStrokeLinePositionLeftBottomCorner) {
            CGPoint leftBottomPt = LeftTopPoint(curLineBounds);
            [bezierPath moveToPoint:CGPointMake(leftBottomPt.x, leftBottomPt.y+cornerLength)];
            [bezierPath addLineToPoint:leftBottomPt];
            [bezierPath addLineToPoint:CGPointMake(leftBottomPt.x+cornerLength, leftBottomPt.y)];
        }
        if (strokeLineType & YCTTTStrokeLinePositionRightBottomCorner) {
            CGPoint rightBottomPt = RightTopPoint(curLineBounds);
            [bezierPath moveToPoint:CGPointMake(rightBottomPt.x, rightBottomPt.y+cornerLength)];
            [bezierPath addLineToPoint:rightBottomPt];
            [bezierPath addLineToPoint:CGPointMake(rightBottomPt.x-cornerLength, rightBottomPt.y)];
        }
    }
    
    CGContextSetLineJoin(c, kCGLineJoinRound);
    
    CGColorRef strokeColor;
    id color = [dic objectForKey:kYCTTTBackgroundStrokeColorAttributeName];
    if ([color isKindOfClass:[UIColor class]]) {
        strokeColor = ((UIColor*)color).CGColor;
    }
    else{
        strokeColor = (__bridge CGColorRef)color;
    }
    
    CGColorRef fillColor;
    color = [dic objectForKey:kYCTTTBackgroundFillColorAttributeName];
    if ([color isKindOfClass:[UIColor class]]) {
        fillColor = ((UIColor*)color).CGColor;
    }
    else{
        fillColor = (__bridge CGColorRef)color;
    }
    NSShadow* shadow = [dic objectForKey:NSShadowAttributeName];
    if (shadow) {
        UIColor* shadowColor = shadow.shadowColor;
        CGContextSetShadowWithColor(c, shadow.shadowOffset, shadow.shadowBlurRadius, shadowColor.CGColor);
    }
    else{
        CGContextSetShadowWithColor(c, shadow.shadowOffset, shadow.shadowBlurRadius, [UIColor clearColor].CGColor);
    }
    if (fillColor) {
        CGContextSetFillColorWithColor(c, fillColor);
        CGContextAddPath(c, bezierPath.CGPath);
        CGContextFillPath(c);
    }
    
    if (strokeColor) {
        CGContextSetLineWidth(c, lineWidth);
        CGContextSetStrokeColorWithColor(c, strokeColor);
        CGContextAddPath(c, bezierPath.CGPath);
        CGContextStrokePath(c);;
    }
    
}

- (CGSize)CTFramesetterSuggestFrameSizeForAttributedStringWithConstraints:(CTFramesetterRef)framesetter  attributedString:(NSAttributedString*)attributedString size:(CGSize)size numberOfLines:(NSUInteger)numberOfLines {
    CFRange rangeToSize = CFRangeMake(0, (CFIndex)[attributedString length]);
    CGSize constraints = CGSizeMake(size.width, size.height);
    NSDictionary* dic = [attributedString attributesAtIndex:rangeToSize.location effectiveRange:NULL];
    
    YCTextWriteDirection writeDir = (YCTextWriteDirection)[[dic objectForKey:kYCTTTTextLineWriteDirectionAttributeName]integerValue];
                                     
    CGFloat heightExtend = 0;
    NSUInteger realNumberOfLines = 1;
    float leading = 0;
    if ([dic objectForKey:kYCTTTTextLineLeadingAttributeName]) {
        leading = [[dic objectForKey:kYCTTTTextLineLeadingAttributeName]floatValue];
    }

    // If the line count of the label more than 1, limit the range to size to the number of lines that have been set
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectMake(0.0f, 0.0f,CGFLOAT_MAX, constraints.height));
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, (CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedLong:kCTFrameProgressionLeftToRight], (NSString *)kCTFrameProgressionAttributeName, /*ctPara,kCTParagraphStyleAttributeName,*/nil]);
    CFArrayRef lines = CTFrameGetLines(frame);
    
    //根据bezier曲线扩大绘制范围
    for (int i = 0; i < CFArrayGetCount(lines); i++) {
        CTLineRef line = (CTLineRef)CFArrayGetValueAtIndex(lines, i);
        CFRange range = CTLineGetStringRange(line);
        if ([self.delegate respondsToSelector:@selector(attributeVerticalLabel:willDrawLineInBounds:withAttribute:range:lineIndex:lineCount:)]) {
            UIBezierPath* path = [self.delegate attributeVerticalLabel:self
                                                  willDrawLineInBounds:CGRectMake(0, 0, size.width, size.height)
                                                         withAttribute:self.attributedText
                                                                 range:CFRANGE_TO_NSRANGE(range)
                                                             lineIndex:i
                                                             lineCount:CFArrayGetCount(lines)];
            if (path) {
                CGRect bounds = [path bounds];
                heightExtend += bounds.size.width;
            }
        }
    }
    
    if (CFArrayGetCount(lines) > 0) {
        NSInteger lastVisibleLineIndex = MIN((CFIndex)numberOfLines, CFArrayGetCount(lines)) - 1;
        if (numberOfLines == 0) {
            lastVisibleLineIndex = CFArrayGetCount(lines) - 1;
        }
        CTLineRef lastVisibleLine = (CTLineRef)CFArrayGetValueAtIndex(lines, lastVisibleLineIndex);
        
        CFRange rangeToLayout = CTLineGetStringRange(lastVisibleLine);
        rangeToSize = CFRangeMake(0, rangeToLayout.location + rangeToLayout.length);
        realNumberOfLines = CFArrayGetCount(lines);
    }
    
    CFRelease(frame);
    CFRelease(path);

    CGSize suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, rangeToSize, (CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedLong:kCTFrameProgressionLeftToRight], (NSString *)kCTFrameProgressionAttributeName, nil], constraints, NULL);
    
    suggestedSize.width += heightExtend;
    suggestedSize.width += leading * (realNumberOfLines-1);
    return CGSizeMake(CGFloat_ceil(suggestedSize.width), CGFloat_ceil(suggestedSize.height));
}
@end
