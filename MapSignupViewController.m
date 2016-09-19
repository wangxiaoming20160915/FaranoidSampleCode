//
//  SignupViewController.m
//  UberMapSdk
//
//  Created by Wang Xiaoming on 5/3/16.
//  Copyright © 2016 Wang Xiaoming. All rights reserved.
//

#import "MapSignupViewController.h"
#import "MapLoginViewController.h"
#import "MapViewController.h"
#import "SignupOperation.h"


@implementation MapSignupViewController


+ (MapSignupViewController*) getViewController {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"UberMain" bundle:[NSBundle bundleWithIdentifier:@"googlemapsdk.ParanoidFramework"]];
    MapSignupViewController * viewController = (MapSignupViewController*)[storyboard instantiateViewControllerWithIdentifier:@"MapSignupViewController"];
    viewController.queue = [[NSOperationQueue alloc] init];
    return (MapSignupViewController*) viewController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.queue = [[NSOperationQueue alloc] init];
    
    // Begin observing the keyboard notifications when the view is loaded.
    [self observeKeyboard];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignOnTap:)];
    [singleTap setNumberOfTapsRequired:1];
    [singleTap setNumberOfTouchesRequired:1];
    [self.view addGestureRecognizer:singleTap];
    
    UIDatePicker *datePicker = [[UIDatePicker alloc] init];
    [datePicker setDate:[NSDate date]];
    datePicker.datePickerMode = UIDatePickerModeDate;
    [datePicker addTarget:self action:@selector(updateTextField:) forControlEvents:UIControlEventValueChanged];
    [self.txtBirthday setInputView:datePicker];
    
    self.txtPassword.secureTextEntry = true;

}

-(void)updateTextField:(id)sender
{
    UIDatePicker *picker = (UIDatePicker*)self.txtBirthday.inputView;
    
    [picker setMaximumDate:[NSDate date]];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    NSDate *eventDate = picker.date;
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    
    NSString *dateString = [dateFormat stringFromDate:eventDate];
    
    self.txtBirthday.text = [NSString stringWithFormat:@"%@",dateString];
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


- (IBAction)signupButtonSection:(id)sender {
    
    if (![self.txtName.text isEqualToString:@""] && ![self.txtEmail.text isEqualToString:@""] && ![self.txtPassword.text isEqualToString:@""] && ![self.txtBirthday.text isEqualToString:@""]){
        
        SignupOperation *signupOperation = [[SignupOperation alloc] init];
        NSString *username = self.txtName.text;
        NSString *email = self.txtEmail.text;
        NSString *password = self.txtPassword.text;
        NSString *dob = self.txtBirthday.text;
        
        signupOperation.username = username;
        signupOperation.useremail = email;
        signupOperation.password = password;
        signupOperation.userdob = dob;
        
    
        signupOperation.onSuccess = ^(NSArray *pins) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"UberMain"
                                                                         bundle:[NSBundle bundleWithIdentifier:@"googlemapsdk.ParanoidFramework"]];
                MapViewController *viewController = (MapViewController*)[mainStoryboard
                                                                             instantiateViewControllerWithIdentifier: @"MapViewController"];
                
                [self presentViewController:viewController animated:YES completion:nil];
            });
        };
        
        signupOperation.onFailure = ^(NSDictionary *failureDict) {
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
        
        [self.queue addOperation:signupOperation];

        
    }
    
}

- (IBAction)backButtonSection:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
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


