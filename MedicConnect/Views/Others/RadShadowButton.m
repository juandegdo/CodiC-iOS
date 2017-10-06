//
//  RadShadowButton.m
//  MedicConnect
//
//  Created by User on 10/4/16.
//  Copyright © 2016 Erik Hitta. All rights reserved.
//

#import "RadShadowButton.h"

@implementation RadShadowButton

#define COLOR_BUTTON_SHADOW [UIColor colorWithRed:133.0f/255 green:138.0f/255 blue:155.0f/255 alpha:1.f]

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        
    }
    
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    self.layer.shadowColor = COLOR_BUTTON_SHADOW.CGColor;
    self.layer.shadowRadius = 10.0f; // 30
    self.layer.shadowOpacity = 0.35f; // 0.59
    
}

@end
