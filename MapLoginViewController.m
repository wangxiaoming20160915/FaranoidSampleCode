//
//  LoginViewController.m
//  UberMapSdk
//
//  Created by Wang Xiaoming on 5/3/16.
//  Copyright © 2016 Wang Xiaoming. All rights reserved.
//

#import "MapLoginViewController.h"
#import "LoginOperation.h"
#import "MapViewController.h"
#import "MapSignupViewController.h"
#import "ForgotPasswordOperation.h"

@implementation MapLoginViewController


+ (MapLoginViewController*) getViewController {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"UberMain" bundle:[NSBundle bundleWithIdentifier:@"googlemapsdk.ParanoidFramework"]];
    MapLoginViewController * viewController = (MapLoginViewController*)[storyboard instantiateViewControllerWithIdentifier:@"MapLoginViewController"];
    viewController.queue = [[NSOperationQueue alloc] init];
    return (MapLoginViewController*) viewController;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Begin observing the keyboard notifications when the view is loaded.
    [self observeKeyboard];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignOnTap:)];
    [singleTap setNumberOfTapsRequired:1];
    [singleTap setNumberOfTouchesRequired:1];
    [self.view addGestureRecognizer:singleTap];
    
    self.txtPassword.secureTextEntry = true;
    
}

- (IBAction)forgotPasswordButtonSection:(id)sender {
    
    if (![self.txtEmail.text isEqualToString:@""]){
        
        ForgotPasswordOperation *forgotPasswordOperation = [[ForgotPasswordOperation alloc] init];
        
        NSString *email = self.txtEmail.text;
        
        forgotPasswordOperation.useremail = email;
        
        forgotPasswordOperation.onSuccess = ^(NSArray *pins) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSString *message = @"Password has been sent to email address.";
                UIAlertView *toast = [[UIAlertView alloc] initWithTitle:nil
                                    message:message
                                    delegate:nil
                                    cancelButtonTitle:nil
                                    otherButtonTitles:nil, nil];
                toast.backgroundColor=[UIColor blackColor];
                [toast show];
                int duration = 2; // duration in seconds
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, duration * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [toast dismissWithClickedButtonIndex:0 animated:YES];
                });
            });
        };
        
        forgotPasswordOperation.onFailure = ^(NSDictionary *failureDict) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSString *message = [failureDict objectForKey:@"message"];
                UIAlertView *toast = [[UIAlertView alloc] initWithTitle:nil
                                                                message:message
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:nil, nil];
                toast.backgroundColor=[UIColor blackColor];
                [toast show];
                int duration = 2; // duration in seconds
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, duration * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [toast dismissWithClickedButtonIndex:0 animated:YES];
                });

                
            });
            
        };
        
        [self.queue addOperation:forgotPasswordOperation];
        
        
    }

    
}

- (IBAction)loginButtonSection:(id)sender {
    
    if (![self.txtEmail.text isEqualToString:@""] && ![self.txtPassword.text isEqualToString:@""]){
        
        LoginOperation *loginOperation = [[LoginOperation alloc] init];
     
        NSString *email = self.txtEmail.text;
        NSString *password = self.txtPassword.text;
    
        loginOperation.useremail = email;
        loginOperation.password = password; 
        
        loginOperation.onSuccess = ^(NSArray *pins) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"UberMain"
                                                                         bundle:[NSBundle bundleWithIdentifier:@"googlemapsdk.ParanoidFramework"]];
                MapViewController *viewController = (MapViewController*)[mainStoryboard
                                                                         instantiateViewControllerWithIdentifier: @"MapViewController"];
                
                [self presentViewController:viewController animated:YES completion:nil];
            });
        };
        
        loginOperation.onFailure = ^(NSDictionary *failureDict) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSString *message = [failureDict objectForKey:@"message"];
                UIAlertView *toast = [[UIAlertView alloc] initWithTitle:nil
                                                                message:message
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:nil, nil];
                toast.backgroundColor=[UIColor blackColor];
                [toast show];
                int duration = 2; // duration in seconds
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, duration * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [toast dismissWithClickedButtonIndex:0 animated:YES];
                });

                
            });
            
        };
        
        [self.queue addOperation:loginOperation];
        
        
    }

}

- (IBAction)backButtonSection:(id)sender {
    
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"UberMain"
                                                             bundle:[NSBundle bundleWithIdentifier:@"googlemapsdk.ParanoidFramework"]];
    MapSignupViewController *viewController = (MapSignupViewController*)[mainStoryboard
                                                                 instantiateViewControllerWithIdentifier: @"MapSignupViewController"];
    [self presentViewController:viewController animated:YES completion:nil];
    
}

-(BOOL) textFieldShouldReturn: (UITextField *) textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.currentResponder = textField;
}

//Implement resignOnTap:

- (void)resignOnTap:(id)iSender {
    [self.currentResponder resignFirstResponder];
}



- (void)observeKeyboard {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

// The callback for frame-changing of keyboard
- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    NSValue *kbFrame = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect keyboardFrame = [kbFrame CGRectValue];
    
    CGFloat height = keyboardFrame.size.height;
    
    NSLog(@"Updating constraints.");
    // Because the "space" is actually the difference between the bottom lines of the 2 views,
    // we need to set a negative constant value here.
    self.bottomViewBottom.constant = height;
    
    [UIView animateWithDuration:animationDuration animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    self.bottomViewBottom.constant = 0;
    [UIView animateWithDuration:animationDuration animations:^{
        [self.view layoutIfNeeded];
    }];
}


@end
