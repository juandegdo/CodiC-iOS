//
//  RadPopUpVC.m
//  MedicConnect
//
//  Created by User on 9/30/16.
//  Copyright © 2016 Erik Hitta. All rights reserved.
//

#import "RadPopUpVC.h"
#import "RadShadowButton.h"

@interface RadPopUpVC (){
    
    void (^_okCompletionBlock)(void);
    void (^_cancelCompletionBlock)(void);
    
    NSString *_message;
    NSString *_okButtonTitle;
    NSString *_cancelButtonTitle;
    
    BOOL isShown;
}

@property (weak, nonatomic) IBOutlet UIView *popupView;
@property (weak, nonatomic) IBOutlet UILabel *lblMessage;
@property (weak, nonatomic) IBOutlet RadShadowButton *btnCancel;
@property (weak, nonatomic) IBOutlet UIButton *btnOk;


@end

@implementation RadPopUpVC

- (id)initWithPopupMessage:(NSString *)message okButtonTitle:(NSString *)okButtonTitle cancelButtonTitle:(NSString *)cancelButtonTitle okCompletionBlock:(void(^) (void))okCompletionBlock  cancelCompletionBlock:(void(^) (void))cancelCompletionBlock {
    
    if (self = [super init]) {
        
        _message = message;
        _okButtonTitle = okButtonTitle;
        _cancelButtonTitle = cancelButtonTitle;
        _okCompletionBlock = okCompletionBlock;
        _cancelCompletionBlock = cancelCompletionBlock;
        
        self.providesPresentationContextTransitionStyle = YES;
        self.definesPresentationContext = YES;
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
        
    self.lblMessage.text = _message;
    [self.btnOk setTitle:_okButtonTitle forState:UIControlStateNormal];
    [self.btnCancel setTitle:_cancelButtonTitle forState:UIControlStateNormal];
}

-(void)viewDidAppear:(BOOL)animated {
    
    if (!isShown) {
        
        isShown = YES;
        
        [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.popupView.transform = CGAffineTransformMakeScale(1.f, 1.f);
            self.view.alpha = 1.0;
            
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                self.popupView.transform = CGAffineTransformMakeScale(1.f, 1.f);
                
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                    self.popupView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
                } completion:^(BOOL finished) {
                    isShown = YES;
                }];
            }];
        }];
    }
}

-(void) closeWithBlock:(void(^) (void))block animated:(BOOL)animated {
   
    if (animated) {
        
        [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.popupView.layer.affineTransform = CGAffineTransformMakeScale(1.05f, 1.05f);
            
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                self.popupView.layer.affineTransform = CGAffineTransformMakeScale(0.3f, 0.3f);
                
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                    self.popupView.layer.affineTransform = CGAffineTransformMakeScale(0.0f, 0.0f);
                    
                } completion:^(BOOL finished) {
                    isShown = NO;
                    [self dismissViewControllerAnimated:NO completion:block];
                }];
            }];
        }];
        
        
        
    }else{
        [self dismissViewControllerAnimated:NO completion:block];
    }
}

#pragma mark - IBActions
- (IBAction)onClose:(id)sender {
    [self closeWithBlock:nil animated:NO];
}

- (IBAction)onCancel:(id)sender {
    [self closeWithBlock:_cancelCompletionBlock animated:NO];
}

- (IBAction)onOk:(id)sender {
    [self closeWithBlock:_okCompletionBlock animated:NO];
}

#pragma mark - Status Bar
- (BOOL)prefersStatusBarHidden {
    return YES;
}


#pragma mark - Warning
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
