//
//  RadTabBarControllerViewController.m
//  Radioish
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
    
    // Center Post Button
    UIButton *centerButton = [[UIButton alloc] initWithFrame:CGRectMake((self.tabBar.frame.size.width - TABBAR_RECORD_BUTTON_DIAMETER)/2, TABBAR_RECORD_BUTTON_PADDING, TABBAR_RECORD_BUTTON_DIAMETER, TABBAR_RECORD_BUTTON_DIAMETER)];
    [centerButton setBackgroundImage:[UIImage imageNamed:@"tab_icon_record"] forState:UIControlStateNormal];
    [centerButton addTarget:self action:@selector(recordButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.tabBar addSubview:centerButton];
    [self.tabBar setSelectionIndicatorImage:[[UIImage alloc] init]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gotoProfileScreen:) name:@"gotoProfileScreen" object:nil];
    
}

-(void)gotoProfileScreen:(NSNotification *)notification {
    self.selectedIndex = 1;
    
    UINavigationController *nc = self.viewControllers[1];
    [nc dismissViewControllerAnimated:FALSE completion:nil];
    [nc popToRootViewControllerAnimated:false];
}

- (void)recordButtonPressed:(UIButton *)sender {
    self.selectedIndex = 2;
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
