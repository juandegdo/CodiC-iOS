//
//  RadTabBarControllerViewController.m
//  MedicConnect
//
//  Created by User on 9/21/16.
//  Copyright © 2016 Erik Hitta. All rights reserved.
//

#import "RadTabBarController.h"
#import "RadTabBar.h"

@interface RadTabBarController ()

@end

@implementation RadTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Add border on top
    UIView *borderTop = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 0.5)];
    borderTop.backgroundColor = [UIColor colorWithRed:229/255.0 green:229/255.0 blue:229/255.0 alpha:1.0];
    [self.tabBar addSubview:borderTop];
    
    // Tab Selected Image Color
    self.tabBar.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
    [self.tabBar setTintColor:COLOR_TABBAR_TINT];
    
}

-(void)gotoProfileScreen:(NSNotification *)notification {
    self.selectedIndex = 1;
    
    UINavigationController *nc = self.viewControllers[1];
    [nc dismissViewControllerAnimated:FALSE completion:nil];
    [nc popToRootViewControllerAnimated:false];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
