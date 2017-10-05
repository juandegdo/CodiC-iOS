//
//  RadPopUpVC.h
//  Radioish
//
//  Created by User on 9/30/16.
//  Copyright © 2016 Erik Hitta. All rights reserved.
//
#import <UIKit/UIKit.h>

@interface RadPopUpVC : UIViewController

- (id)initWithPopupMessage:(NSString *)message okButtonTitle:(NSString *)okButtonTitle cancelButtonTitle:(NSString *)cancelButtonTitle okCompletionBlock:(void(^) (void))okCompletionBlock  cancelCompletionBlock:(void(^) (void))cancelCompletionBlock;
@end
