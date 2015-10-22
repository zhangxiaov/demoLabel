//
//  DemoLabel.m
//  app_demo
//
//  Created by zhangxinwei on 15/10/15.
//  Copyright (c) 2015年 张新伟. All rights reserved.
//

#import "DemoLabel.h"
#import <CoreText/CoreText.h>

/* Callbacks */

static void deallocCallback( void* ref ){
    //    [(__bridge id)ref release];
}
static CGFloat ascentCallback( void *ref ){
    return [(NSString*)[(__bridge NSDictionary*)ref objectForKey:@"height"] floatValue];
}
static CGFloat descentCallback( void *ref ){
    return [(NSString*)[(__bridge NSDictionary*)ref objectForKey:@"descent"] floatValue];
}
static CGFloat widthCallback( void* ref ){
    return [(NSString*)[(__bridge NSDictionary*)ref objectForKey:@"width"] floatValue];
}

@implementation DemoLabel

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _font = @"ArialMT";
        _color = [UIColor blackColor];
        _strokeColor = [UIColor redColor];
        _strokeWidth = .0;
        _fontSize = 15.0;
        _imageRects = [[NSMutableArray alloc] init];
        _linkRects = [[NSMutableArray alloc] init];
        _linkValue = [[NSMutableArray alloc] init];
        NSLog(@"%f", [UIScreen mainScreen].bounds.size.width);
    }
    
    return self;
}

- (void)buildAttribute {
    _mAttr = [[NSMutableAttributedString alloc] init];
    NSRegularExpression *regx = [[NSRegularExpression alloc] initWithPattern:@"(.*?)(<[^>]+>|\\Z)" options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators error:nil];
    NSArray *matches = [regx matchesInString:_originString options:0 range:NSMakeRange(0, [_originString length])];
    
    for (int i = 0; i < matches.count; i ++) {
        NSTextCheckingResult *result = [matches objectAtIndex:i];
        NSArray *matches2 = [[_originString substringWithRange:result.range] componentsSeparatedByString:@"<"];
        CTFontRef font = CTFontCreateWithName((CFStringRef)self.font, self.fontSize, NULL);
        
        NSDictionary *d = [[NSDictionary alloc] initWithObjectsAndKeys:(__bridge id)font, kCTFontAttributeName,
                           (id)self.color.CGColor , kCTForegroundColorAttributeName,
                           (id)self.strokeColor.CGColor, kCTStrokeColorAttributeName,
                           (id)[NSNumber numberWithFloat:self.strokeWidth], kCTStrokeWidthAttributeName,nil];
        CFRelease(font);
        [_mAttr appendAttributedString:[[NSAttributedString alloc] initWithString:[matches2 objectAtIndex:0] attributes:d]];
        
        if ([matches2 count] > 1) {
            NSString *tag = (NSString *)[matches2 objectAtIndex:1];
            if ([tag hasPrefix:@"font"]) {
                NSRegularExpression *rgex_color = [[NSRegularExpression alloc] initWithPattern:@"(?<=color=)\\w+" options:0 error:nil];
                [rgex_color enumerateMatchesInString:tag options:0 range:NSMakeRange(0, [tag length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                    SEL colorSel = NSSelectorFromString([NSString stringWithFormat:@"%@Color", [tag substringWithRange:result.range]]);
                    self.color = [UIColor performSelector:colorSel];
                }];
                
                NSRegularExpression *rgex_face = [[NSRegularExpression alloc] initWithPattern:@"(?<=face=)\\w+" options:0 error:nil];
                [rgex_face enumerateMatchesInString:tag options:0 range:NSMakeRange(0, [tag length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                    self.font = [tag substringWithRange:result.range];
                }];
                
                NSRegularExpression *rgex_fontsize = [[NSRegularExpression alloc] initWithPattern:@"(?<=fontSize=)\\w+" options:0 error:nil];
                [rgex_fontsize enumerateMatchesInString:tag options:0 range:NSMakeRange(0, [tag length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                    self.fontSize = [tag substringWithRange:result.range].floatValue;
                }];
                
                NSRegularExpression *rgex_strokeColor = [[NSRegularExpression alloc] initWithPattern:@"(?<=strokeColor=)\\w+" options:0 error:nil];
                [rgex_strokeColor enumerateMatchesInString:tag options:0 range:NSMakeRange(0, [tag length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                    SEL colorSel = NSSelectorFromString([NSString stringWithFormat:@"%@Color", [tag substringWithRange:result.range]]);
                    self.strokeColor = [UIColor performSelector:colorSel];
                }];
                
                NSRegularExpression *rgex_strokeWidth = [[NSRegularExpression alloc] initWithPattern:@"(?<=strokeWidth=)\\w+" options:0 error:nil];
                [rgex_strokeWidth enumerateMatchesInString:tag options:0 range:NSMakeRange(0, [tag length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                    self.strokeWidth = [tag substringWithRange:result.range].floatValue;
                }];
                
            }else if ([tag hasPrefix:@"img"]) {
                __block NSNumber* width = [NSNumber numberWithInt:0];
                __block NSNumber* height = [NSNumber numberWithInt:0];
                __block NSString* imageName = @"";
                
                //width
                NSRegularExpression* widthRegex = [[NSRegularExpression alloc] initWithPattern:@"(?<=width=)\\d+" options:0 error:NULL];
                [widthRegex enumerateMatchesInString:tag options:0 range:NSMakeRange(0, [tag length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
                    width = [NSNumber numberWithInt: [[tag substringWithRange: match.range] intValue] ];
                }];
                
                //height
                NSRegularExpression* faceRegex = [[NSRegularExpression alloc] initWithPattern:@"(?<=height=)\\d+" options:0 error:NULL];
                [faceRegex enumerateMatchesInString:tag options:0 range:NSMakeRange(0, [tag length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
                    height = [NSNumber numberWithInt: [[tag substringWithRange:match.range] intValue]];
                }];
                
                //image name
                NSRegularExpression* srcRegex = [[NSRegularExpression alloc] initWithPattern:@"(?<=src=)[^\\s]+" options:0 error:NULL];
                [srcRegex enumerateMatchesInString:tag options:0 range:NSMakeRange(0, [tag length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
                    imageName = [tag substringWithRange: match.range];
                }];
                
                //render space when drawing text
                CTRunDelegateCallbacks callbacks;
                callbacks.version = kCTRunDelegateVersion1;
                callbacks.getAscent = ascentCallback;
                callbacks.getDescent = descentCallback;
                callbacks.getWidth = widthCallback;
                callbacks.dealloc = deallocCallback;
                
                NSDictionary* imgdict = [NSDictionary dictionaryWithObjectsAndKeys: width, @"width", height, @"height", nil];
                
                CTRunDelegateRef runDelegate = CTRunDelegateCreate(&callbacks, (__bridge void *)(imgdict));
                NSMutableAttributedString *imageAttributedString = [[NSMutableAttributedString alloc] initWithString:@" "];
                [imageAttributedString addAttribute:(NSString *)kCTRunDelegateAttributeName value:(__bridge id)runDelegate range:NSMakeRange(0, 1)];
                [imageAttributedString addAttribute:@"imageName" value:imageName range:NSMakeRange(0, 1)];
                [imageAttributedString addAttribute:@"width" value:width range:NSMakeRange(0, 1)];
                [imageAttributedString addAttribute:@"height" value:height range:NSMakeRange(0, 1)];
                [_mAttr appendAttributedString:imageAttributedString];
                
            }else if ([tag hasPrefix:@"a "]) {
                __block NSString *val;
                NSRegularExpression* regx = [[NSRegularExpression alloc] initWithPattern:@"(?<=href=)[^>|^\\s]+" options:0 error:NULL];
                [regx enumerateMatchesInString:tag options:0 range:NSMakeRange(0, [tag length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
                    val = [tag substringWithRange: match.range];
                }];
                
                [self.linkValue addObject:val];
                
                i++;
                NSTextCheckingResult *result = [matches objectAtIndex:i];
                NSArray *matches2 = [[_originString substringWithRange:result.range] componentsSeparatedByString:@"<"];
                NSString *content = [matches2 objectAtIndex:0];
                NSMutableAttributedString *linkAttr = [[NSMutableAttributedString alloc] initWithString:content];
                CTFontRef font = CTFontCreateWithName((CFStringRef)self.font, self.fontSize, NULL);
                NSDictionary *d2 = [[NSDictionary alloc] initWithObjectsAndKeys:(__bridge id)font, kCTFontAttributeName,
                                    (id)self.color.CGColor , kCTForegroundColorAttributeName,
                                    (id)self.strokeColor.CGColor, kCTStrokeColorAttributeName,
                                    (id)[NSNumber numberWithFloat:self.strokeWidth], kCTStrokeWidthAttributeName, nil];
                [linkAttr addAttribute:@"link" value:val range:NSMakeRange(0, [content length])];
                [linkAttr addAttributes:d2 range:NSMakeRange(0, [content length])];
                [_mAttr appendAttributedString:linkAttr];
                CFRelease(font);
            }
        }
    }
}

- (void)drawRect:(CGRect)rect {
    //设置NSMutableAttributedString的所有属性
    [self buildAttribute];
    NSLog(@"rect:%@",NSStringFromCGRect(rect));
    CGContextRef context = UIGraphicsGetCurrentContext();
    //设置context的ctm，用于适应core text的坐标体系
    CGContextSaveGState(context);
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, rect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    //设置CTFramesetter
    CTFramesetterRef framesetter =  CTFramesetterCreateWithAttributedString((CFAttributedStringRef)_mAttr);
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectMake(0, 0, rect.size.width, rect.size.height));
    //创建CTFrame
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, _mAttr.length), path, NULL);
    //把文字内容绘制出来
    CTFrameDraw(frame, context);
    //获取画出来的内容的行数
    CFArrayRef lines = CTFrameGetLines(frame);
    //获取每行的原点坐标
    CGPoint lineOrigins[CFArrayGetCount(lines)];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), lineOrigins);
    NSLog(@"line count = %ld",CFArrayGetCount(lines));
    for (int i = 0; i < CFArrayGetCount(lines); i++) {
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CGFloat lineAscent;
        CGFloat lineDescent;
        CGFloat lineLeading;
        //获取每行的宽度和高度
        CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, &lineLeading);
        NSLog(@"ascent = %f,descent = %f,leading = %f",lineAscent,lineDescent,lineLeading);
        //获取每个CTRun
        CFArrayRef runs = CTLineGetGlyphRuns(line);
        NSLog(@"run count = %ld",CFArrayGetCount(runs));
        for (int j = 0; j < CFArrayGetCount(runs); j++) {
            CGFloat runAscent;
            CGFloat runDescent;
            CGPoint lineOrigin = lineOrigins[i];
            //获取每个CTRun
            CTRunRef run = CFArrayGetValueAtIndex(runs, j);
            NSDictionary* attributes = (NSDictionary*)CTRunGetAttributes(run);
            CGRect runRect;
            //调整CTRun的rect
            runRect.size.width = CTRunGetTypographicBounds(run, CFRangeMake(0,0), &runAscent, &runDescent, NULL);
            NSLog(@"width = %f",runRect.size.width);
            
            runRect = CGRectMake(lineOrigin.x + CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL), lineOrigin.y - runDescent, runRect.size.width, runAscent + runDescent);
            
            NSString *imageName = [attributes objectForKey:@"imageName"];
            NSString *link = [attributes objectForKey:@"link"];
            
            //坐标转换，把每行的原点坐标转换为uiview的坐标体系 rect frame大小
            CGPathRef path = CTFrameGetPath(frame);
            //获取整个CTFrame的大小
            CGRect rect = CGPathGetBoundingBox(path);
            NSLog(@"rect:%@",NSStringFromCGRect(rect));
            //图片渲染逻辑，把需要被图片替换的字符位置画上图片
            if (imageName) {
                UIImage *image = [UIImage imageNamed:imageName];
                if (image) {
                    CGRect imageDrawRect;
                    CGFloat w = ((NSString *)[attributes objectForKey:@"width"]).floatValue;
                    CGFloat h = ((NSString *)[attributes objectForKey:@"height"]).floatValue;
                    imageDrawRect.size = CGSizeMake(w, h);
                    imageDrawRect.origin.x = runRect.origin.x + lineOrigin.x;
                    imageDrawRect.origin.y = lineOrigin.y;
                    CGContextDrawImage(context, imageDrawRect, image.CGImage);
                    //坐标系 转换
                    imageDrawRect.origin.y = rect.origin.y + rect.size.height - lineOrigin.y - imageDrawRect.size.height;
                    NSValue *value = [NSValue valueWithBytes:&imageDrawRect objCType:@encode(CGRect)];
                    
                    [self.imageRects addObject:value];
                }
            }else if (link){
                CGRect linkRect;
                linkRect.size = runRect.size;
                linkRect.origin.x = runRect.origin.x + lineOrigin.x;
                linkRect.origin.y = rect.origin.y + rect.size.height - lineOrigin.y - runRect.size.height;
                NSValue *value = [NSValue valueWithBytes:&linkRect objCType:@encode(CGRect)];
                [self.linkRects addObject:value];
            }
        }
    }
    
    
    CFRelease(framesetter);
    CFRelease(path);
    CFRelease(frame);
    CGContextRestoreGState(context);
}

//接受触摸事件
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    
    for (NSValue *value in self.imageRects) {
        CGRect rect;
        [value getValue:&rect];
        if (point.x >= rect.origin.x && point.x <= rect.origin.x + rect.size.width && point.y >= rect.origin.y && point.y <= rect.origin.y + rect.size.height ) {
            
            NSLog(@"img");
            return;
        }
    }
    
    for (NSValue *value in self.linkRects) {
        CGRect rect;
        [value getValue:&rect];
        if (point.x >= rect.origin.x && point.x <= rect.origin.x + rect.size.width && point.y >= rect.origin.y && point.y <= rect.origin.y + rect.size.height ) {
            
            NSLog(@"ttttt");
            return;
        }
    }
}

#pragma mark nscoding

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    return nil;
}

@end
