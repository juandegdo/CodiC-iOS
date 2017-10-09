//
//  RadTabBar.m
//  MedicConnect
//
//  Created by User on 9/21/16.
//  Copyright © 2016 Erik Hitta. All rights reserved.
//

#import "RadTabBar.h"

@implementation RadTabBar

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
 */
- (void)drawRect:(CGRect)rect {
    // Drawing code
    [super drawRect:rect];
    
    CGFloat tapItemTopInset = 7.0f;
    CGFloat tapItemLeftInset = 0.0f;
    
    // Adjustment the point
    for (UITabBarItem *item in self.items) {
        item.imageInsets = UIEdgeInsetsMake(tapItemTopInset, tapItemLeftInset, -tapItemTopInset, -tapItemLeftInset);
        item.titlePositionAdjustment = UIOffsetZero;
    }
    
}

-(CGSize)sizeThatFits:(CGSize)size {
    
    CGSize sizeThatFits = [super sizeThatFits:size];
    sizeThatFits.height = TABBAR_HEIGHT;
    
    return sizeThatFits;
}

@end
