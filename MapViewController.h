//
//  MapViewController.h
//  UberMapSdk
//
//  Created by Wang Xiaoming on 4/18/16.
//  Copyright © 2016 Wang Xiaoming. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MapKit/MapKit.h"
#import <CoreLocation/CoreLocation.h>

@interface MapViewController : UIViewController <UIImagePickerControllerDelegate, CLLocationManagerDelegate>{
  
    UIImagePickerController *imagePicker;
    
}

@property (strong, nonatomic) CLLocation *initialLocation;
@property (nonatomic,strong) NSOperationQueue *queue;

+ (MapViewController*) getViewController;
@end
