//
//  SignupViewController.h
//  UberMapSdk
//
//  Created by Wang Xiaoming on 5/3/16.
//  Copyright © 2016 Wang Xiaoming. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MapSignupViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic,strong) NSOperationQueue *queue;

@property (weak, nonatomic) IBOutlet UIView *bottomView;


+ (MapSignupViewController*) getViewController;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomViewBottom;
@property (weak, nonatomic) IBOutlet UITextField *txtName;
@property (weak, nonatomic) IBOutlet UITextField *txtEmail;
@property (weak, nonatomic) IBOutlet UITextField *txtPassword;
@property (weak, nonatomic) IBOutlet UITextField *txtBirthday;
@property (nonatomic, assign) id currentResponder;
@end
