//
//  DemoLabel.h
//  app_demo
//
//  Created by zhangxinwei on 15/10/15.
//  Copyright (c) 2015年 张新伟. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

@interface DemoLabel : UIView <NSCoding>
@property (nonatomic, strong) NSMutableAttributedString *mAttr;

@property (nonatomic, copy) NSString *font;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) UIColor *strokeColor;
@property (nonatomic, assign) CGFloat fontSize;
@property (nonatomic, assign) CGFloat strokeWidth;
@property (nonatomic, strong) NSString *originString;
@property (nonatomic, strong) NSMutableArray *linkValue;
@property (nonatomic, strong) NSMutableArray *imageRects;
@property (nonatomic, strong) NSMutableArray *linkRects;
@end
