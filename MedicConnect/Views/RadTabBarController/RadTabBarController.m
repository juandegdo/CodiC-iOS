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
    
    // Tab Selected Image Color
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
