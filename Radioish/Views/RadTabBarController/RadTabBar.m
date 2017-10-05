//
//  RadTabBar.m
//  Radioish
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
    
    CGFloat tabItemWidth = self.frame.size.width/ self.items.count;
    CGFloat tabRecordingWidth = TABBAR_RECORD_BUTTON_DIAMETER + 35;
    CGFloat tabItemIdealWidth = (self.frame.size.width - tabRecordingWidth)/ (self.items.count -1);
    CGFloat tapItemTopInset = 5.0f;
    CGFloat tapItemLeftInset = 0.0f;
    
    // Adjustment the point
    for (UITabBarItem *item in self.items) {
        switch (item.tag) {
            case 1001:
                tapItemLeftInset = tabItemIdealWidth * 0.5 - tabItemWidth * 0.5;
                break;
                
            case 1002:
                tapItemLeftInset = tabItemIdealWidth * 1.5 - tabItemWidth * 1.5;
                break;
                
            case 1004:
                tapItemLeftInset = tabItemIdealWidth * 2.5 + tabRecordingWidth - tabItemWidth * 3.5;
                break;
                
            case 1005:
                tapItemLeftInset = tabItemIdealWidth * 3.5 + tabRecordingWidth - tabItemWidth * 4.5;
                break;
                
            default:
                tapItemLeftInset = 0.0f;
                break;
        }
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
