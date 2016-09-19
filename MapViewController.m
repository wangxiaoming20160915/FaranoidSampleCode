//
//  MapViewController.m
//  UberMapSdk
//
//  Created by Wang Xiaoming on 4/18/16.
//  Copyright © 2016 Wang Xiaoming. All rights reserved.
//

#import "MapViewController.h"
#import "RatingBar.h"
#import "PInDetailTableViewCell.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <MapKit/MapKit.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "AppDelegate.h"
#import "Constants.h"
#import "GetAllPinsOperation.h"
#import "Pin.h"
#import "CustomMKPointAnnotation.h"
#import "UIImage+Paranoid.h"
#import "PinChat.h"
#import "GetPinChatOperation.h"
#import "AddPinChatMessage.h"


@interface MapViewController () <MKMapViewDelegate, UISearchBarDelegate, UINavigationControllerDelegate, NSURLConnectionDelegate>{
    CLLocationManager *locationManager;
    NSDictionary* annotationDictionary;
    NSDictionary* imageDictionary;
    Boolean isLike;
    
    PinChat *selPinChat;
    Pin *selPin;
    
    NSMutableData * respData;
    UIImage *chosenImage;
    
    CLLocation *currentLocation;
    
    CGFloat keyboardHeight;
    
    NSString *currentReplyName;
}
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomViewBottom;

@property (weak, nonatomic) IBOutlet UIView *bottomView;

@property (weak, nonatomic) IBOutlet UIView *pinDetailView;

@property (weak, nonatomic) IBOutlet UIButton *btnLike;

@property (weak, nonatomic) IBOutlet UIButton *btnTopNumber;
@property (weak, nonatomic) IBOutlet UIButton *btnBottomNumber;

@property (weak, nonatomic) IBOutlet UISearchBar *topSearchBar;
@property (weak, nonatomic) IBOutlet UITableView *pinDetailTableView;

@property (weak, nonatomic) IBOutlet UIView *ratingView;
@property (weak, nonatomic) IBOutlet MKMapView *mkMapView;
@property (weak, nonatomic) IBOutlet UIImageView *imgPinAvatar;
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UILabel *lblDistance;
@property (weak, nonatomic) IBOutlet UIButton *btnFavorite;
@property (weak, nonatomic) IBOutlet UITextField *txtComment;

@property (nonatomic, strong)NSMutableArray *datasource;
@property (nonatomic, strong)NSMutableArray *pinChats;




@end

@implementation MapViewController

//+ (MapViewController*) getViewController {
//    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"UberMain" bundle:[NSBundle bundleWithIdentifier:@"googlemapsdk.ParanoidFramework"]];
//    MapViewController * viewController = (MapViewController*)[storyboard instantiateViewControllerWithIdentifier:@"MapViewController"];
//    viewController.queue = [[NSOperationQueue alloc] init];
//    return (MapViewController*) viewController;
//}

- (id) init {
    self = [super init];
    
    NSLog(@"MapViewController initialize is called");
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.queue = [[NSOperationQueue alloc] init];
    
    // Begin observing the keyboard notifications when the view is loaded.
    [self observeKeyboard];
    
    //input the array value into _datasource of tableview
    _datasource = [[NSMutableArray alloc] init];
    _pinChats = [[NSMutableArray alloc] init];
    
    // Ensure that you can view your own location in the map view.
    _mkMapView.delegate = self;
    
    [_mkMapView setShowsUserLocation:YES];
    _mkMapView.showsBuildings = YES;
//    [_mkMapView setMapType:MKMapTypeStandard];
    [_mkMapView setZoomEnabled:YES];
    [_mkMapView setScrollEnabled:YES];
    [_mkMapView setUserTrackingMode:YES];
  
    //create Location Manager
    locationManager = [[CLLocationManager alloc] init];
    
    // get the user location
    locationManager.delegate = self;
    locationManager.desiredAccuracy=kCLLocationAccuracyBest;
    locationManager.distanceFilter=kCLDistanceFilterNone;
    [locationManager requestWhenInUseAuthorization];
    [locationManager startMonitoringSignificantLocationChanges];
    [locationManager startUpdatingLocation];
    
    //get the all pins
    [self getAllPins];
    
    annotationDictionary = [self createAnnotationDictionary];
    imageDictionary = [self createImageDictionary];
   
    isLike = false;
    
#pragma dismiss keyboard when touch outside searchTextView
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    self.pinDetailTableView.estimatedRowHeight = 20; // for example. Set your average height
    self.pinDetailTableView.rowHeight = UITableViewAutomaticDimension;
    
#pragma setting Ratingview
    RatingBar *bar = [[RatingBar alloc] initWithFrame:CGRectMake(0, 0, 120, 30)];
    [self.ratingView addSubview:bar];
  
    
}

- (void)getAllPins{

    GetAllPinsOperation *getAllPinsOperation = [[GetAllPinsOperation alloc] init];
    getAllPinsOperation.latitude = @"34.05";
    getAllPinsOperation.longitude = @"118.03";
    
    getAllPinsOperation.onSuccess = ^(NSArray *pins) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (pins.count) {
                _datasource = [NSMutableArray arrayWithArray:pins];
                [self addAllPins];
            }
            else {
               
            }
        });
    };
    
    getAllPinsOperation.onFailure = ^(NSDictionary *failureDict) {
        dispatch_async(dispatch_get_main_queue(), ^{
         
        });
        
    };
    
    [self.queue addOperation:getAllPinsOperation];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
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

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
  
    // show the user currenct location
    
     _btnBottomNumber.layer.cornerRadius = 5.0f;
     _btnTopNumber.layer.cornerRadius = 5.0f;
     _btnFavorite.layer.cornerRadius = 5.0f;
     _topSearchBar.layer.cornerRadius = 5.0f;
     _topSearchBar.barTintColor = [UIColor whiteColor];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)addAllPins
{
    
    for(int i = 0; i < _datasource.count; i++)
    {
        Pin *pin = _datasource[i];
        
        [self addPinWithTitle:pin];
    }
}

-(void)addPinWithTitle:(Pin *)pin
{
    CustomMKPointAnnotation *mapPin = [[CustomMKPointAnnotation alloc] init];
    double latitude = [pin.mapPinLatitude doubleValue];
    double longitude = [pin.mapPinLongitude doubleValue];
    // setup the map pin with all data and add to map view
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
    
    mapPin.title = pin.mapPinTitle;
    mapPin.subtitle = pin.mapPinType;
    mapPin.pinId = pin.mapPinId;
    
    mapPin.pinType = pin.mapPinType;
    mapPin.coordinate = coordinate;
    
    [self.mkMapView addAnnotation:mapPin];
}

# pragma MKMapview delegate
-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if (!self.initialLocation) {
        self.initialLocation = userLocation.location;
        MKCoordinateRegion mapRegion;
        mapRegion.center = mapView.userLocation.coordinate;
        mapRegion.span.latitudeDelta = 0.2;
        mapRegion.span.longitudeDelta = 0.2;
        
        [mapView setRegion:mapRegion animated: YES];
    }
    
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    CustomMKPointAnnotation *pin = (CustomMKPointAnnotation *)view.annotation;
    NSString *pinId = pin.pinId;
    NSString *pinType = pin.pinType;
    
     selPin = [self getPinWithPinId:pinId];
    [_lblTitle setText: selPin.mapPinType];
    [_lblDistance setText: selPin.distance];
    
    [self tableViewReloadData];
    
    if (selPin.favorite) {
        [_btnLike setBackgroundImage:[UIImage imageNamedFromFramework:@"sdk_active_favorite.png"] forState:UIControlStateNormal];
    } else {
         [_btnLike setBackgroundImage:[UIImage imageNamedFromFramework:@"sdk_greyheart.png"] forState:UIControlStateNormal];
    }
   
    [self setImageViewForPinType:pinType imageView:_imgPinAvatar];
    
    _pinDetailView.hidden = NO;
}

- (void) tableViewReloadData{
    
    //load pinchats array data
    GetPinChatOperation *getPinChatOperation = [[GetPinChatOperation alloc] init];
    getPinChatOperation.pinId = selPin.mapPinId;
    getPinChatOperation.userId = selPin.userId;
    
    getPinChatOperation.onSuccess = ^(NSArray *pins) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (pins.count) {
                
                _pinChats = [NSMutableArray arrayWithArray:pins];
                 [_pinDetailTableView reloadData];
                
            }
            else {
                
            }
        });
    };
    
    getPinChatOperation.onFailure = ^(NSDictionary *failureDict) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
        });
        
    };
    
    [self.queue addOperation:getPinChatOperation];
    
    
   

    
}


- (NSDictionary*) createAnnotationDictionary {
    NSDictionary* dict = [[NSDictionary alloc] initWithObjectsAndKeys:
                          [self createAnnotationImage:@"sdk_menu_v2_MedicalCare.png"], kMedical,
                          [self createAnnotationImage:@"sdk_menu_v2_Broadcast.png"], kBroadcast,
                          [self createAnnotationImage:@"sdk_menu_v2_EntryExit.png"], kEntry,
                          [self createAnnotationImage:@"sdk_menu_v2_Celebrity.png"], kCelebrity,
                          [self createAnnotationImage:@"sdk_menu_v2_Music.png"], kMusic,
                          [self createAnnotationImage:@"sdk_menu_v2_Treasure.png"], kTreasure,
                          [self createAnnotationImage:@"sdk_menu_v2_Note.png"], kNote,
                          [self createAnnotationImage:@"sdk_menu_v2_Parking.png"], kParkingFull,
                          [self createAnnotationImage:@"sdk_menu_v2_Parking.png"], kParkingAvailable,
                          [self createAnnotationImage:@"sdk_menu_v2_Tailgate.png"], kTailgate,
                          [self createAnnotationImage:@"sdk_menu_v2_Police.png"], kPolice,
                          [self createAnnotationImage:@"sdk_menu_v2_Beer.png"], kBeer,
                          [self createAnnotationImage:@"sdk_menu_v2_Parking.png"], kParking,
                          [self createAnnotationImage:@"sdk_menu_v2_Ticket.png"], kTicket,
                          [self createAnnotationImage:@"sdk_menu_v2_Apparel.png"], kApparel,
                          [self createAnnotationImage:@"sdk_menu_v2_FoodDrinks.png"], kFoodDrink,
                          [self createAnnotationImage:@"sdk_menu_v2_WatchParty.png"], kWatchParty,
                          [self createAnnotationImage:@"sdk_menu_v2_Playing.png"], kPlaying,
                          [self createAnnotationImage:@"sdk_menu_v2_GameShowing.png"], kGameShowing,
                          [self createAnnotationImage:@"sdk_menu_v2_Partying.png"], kPartying,
                          [self createAnnotationImage:@"sdk_menu_v2_Ticket.png"], kTent,
                          [self createAnnotationImage:@"sdk_menu_v2_Restroom.png"], kRestroom,
                          [self createAnnotationImage:@"sdk_menu_v2_Ticket.png"], kEntrance,
                          [self createAnnotationImage:@"sdk_menu_v2_Rickshaw.png"], kRickShaw,
                          [self createAnnotationImage:@"sdk_menu_v2_Uber.png"], kUber,
                          [self createAnnotationImage:@"sdk_menu_v2_Ticket.png"], kHole1, nil];
    return dict;
}

- (NSDictionary*) createImageDictionary {
    NSDictionary* dict = [[NSDictionary alloc] initWithObjectsAndKeys:
                          [self createOriginalImage:@"sdk_menu_v2_MedicalCare.png"], kMedical,
                          [self createOriginalImage:@"sdk_menu_v2_Broadcast.png"], kBroadcast,
                          [self createOriginalImage:@"sdk_menu_v2_EntryExit.png"], kEntry,
                          [self createOriginalImage:@"sdk_menu_v2_Celebrity.png"], kCelebrity,
                          [self createOriginalImage:@"sdk_menu_v2_Music.png"], kMusic,
                          [self createOriginalImage:@"sdk_menu_v2_Treasure.png"], kTreasure,
                          [self createOriginalImage:@"sdk_menu_v2_Note.png"], kNote,
                          [self createOriginalImage:@"sdk_menu_v2_Parking.png"], kParkingFull,
                          [self createOriginalImage:@"sdk_menu_v2_Parking.png"], kParkingAvailable,
                          [self createOriginalImage:@"sdk_menu_v2_Tailgate.png"], kTailgate,
                          [self createOriginalImage:@"sdk_menu_v2_Police.png"], kPolice,
                          [self createOriginalImage:@"sdk_menu_v2_Beer.png"], kBeer,
                          [self createOriginalImage:@"sdk_menu_v2_Parking.png"], kParking,
                          [self createOriginalImage:@"sdk_menu_v2_Ticket.png"], kTicket,
                          [self createOriginalImage:@"sdk_menu_v2_Apparel.png"], kApparel,
                          [self createOriginalImage:@"sdk_menu_v2_FoodDrinks.png"], kFoodDrink,
                          [self createOriginalImage:@"sdk_menu_v2_WatchParty.png"], kWatchParty,
                          [self createOriginalImage:@"sdk_menu_v2_Playing.png"], kPlaying,
                          [self createOriginalImage:@"sdk_menu_v2_GameShowing.png"], kGameShowing,
                          [self createOriginalImage:@"sdk_menu_v2_Partying.png"], kPartying,
                          [self createOriginalImage:@"sdk_menu_v2_Ticket.png"], kTent,
                          [self createOriginalImage:@"sdk_menu_v2_Restroom.png"], kRestroom,
                          [self createOriginalImage:@"sdk_menu_v2_Ticket.png"], kEntrance,
                          [self createOriginalImage:@"sdk_menu_v2_Rickshaw.png"], kRickShaw,
                          [self createOriginalImage:@"sdk_menu_v2_Uber.png"], kUber,
                          [self createOriginalImage:@"sdk_menu_v2_Ticket.png"], kHole1, nil];
    return dict;
}

- (UIImage*) createOriginalImage: (NSString*) imageName {
    
    UIImage* pinImage = [UIImage imageNamedFromFramework:imageName];
    return pinImage;
}


- (UIImage*) createAnnotationImage: (NSString*) imageName {
    
    UIImage* pinImage = [UIImage imageNamedFromFramework:imageName];
    
//    CGSize size = CGSizeMake(30, 30);
//    UIGraphicsBeginImageContext(size);
//    [pinImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
//    UIImage* resizedImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
    
    return pinImage;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {

    static NSString* AnnotationIdentifier = @"Annotation";
    MKAnnotationView *pinView = (MKAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:AnnotationIdentifier];

    if (annotation == mapView.userLocation)
    {
        if (!pinView)
        {
            pinView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationIdentifier];
        }
        else
        {
            if ([pinView tag] == 101)
                [[pinView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        }
        
        [pinView addSubview:[self getUserLocationPinCustomImage]];
        [pinView setTag:101];
    }
    else
    {
        if (!pinView)
        {
            pinView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationIdentifier];
        }
        else {
            if ([pinView tag] == 101)
                [[pinView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        }
        
        if ([annotation isKindOfClass:[CustomMKPointAnnotation class]] != YES)
            pinView = nil;
        else {
            pinView.annotation = annotation;
            NSString *pinType = ((CustomMKPointAnnotation *)annotation).pinType;
            
            CGRect  viewRect = CGRectMake(-20, -20, 40, 40);
            UIImageView* imageView = [[UIImageView alloc] initWithFrame:viewRect];
            
            // keeps the image dimensions correct
            // so if you have a rectangle image, it will show up as a rectangle,
            // instead of being resized into a square
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            
            [imageView setImage:[annotationDictionary objectForKey:pinType]];
           
            [pinView addSubview:imageView];
            
            
        }
    }
    
    return pinView;
    
}

- (Pin *)getPinWithPinId:(NSString *)pinId{
    Pin *selelectPin = [[Pin alloc] init];
    for (Pin *pin in _datasource) {
        if (pinId == pin.mapPinId) {
            selelectPin = pin;
        }
    }
    return selelectPin;
}



- (UIImageView *)getUserLocationPinCustomImage{
    
    NSArray *imageNames = @[@"sdk_img-1.png", @"sdk_img-2.png", @"sdk_img-3.png", @"sdk_img-4.png",
                            @"sdk_img-5.png", @"sdk_img-6.png"];
    
    NSMutableArray *images = [[NSMutableArray alloc] init];
    for (int i = 0; i < imageNames.count; i++) {
        [images addObject:[UIImage imageNamedFromFramework:[imageNames objectAtIndex:i]]];
    }
    
   
    
    CGRect  viewRect = CGRectMake(-30, -30, 60, 60);
    UIImageView* imageView = [[UIImageView alloc] initWithFrame:viewRect];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    
    imageView.animationImages = images;
    imageView.animationDuration = 1;
    
    [imageView startAnimating];
    
    return imageView;

}


- (void) dismissKeyboard
{
    // add self
    [self.txtComment resignFirstResponder];
}

-(BOOL) textFieldShouldReturn: (UITextField *) textField {
    [textField resignFirstResponder];
    return YES;
}

- (IBAction)btnZoomInAction:(id)sender {
    
    MKCoordinateRegion region = self.mkMapView.region;
    region.span.latitudeDelta /= 2.0;
    region.span.longitudeDelta /= 2.0;
    [self.mkMapView setRegion:region animated:YES];
}
- (IBAction)btnZoomOutInAction:(id)sender {
    
    MKCoordinateRegion region = self.mkMapView.region;
    region.span.latitudeDelta  = MIN(region.span.latitudeDelta  * 2.0, 180.0);
    region.span.longitudeDelta = MIN(region.span.longitudeDelta * 2.0, 180.0);
    [self.mkMapView setRegion:region animated:YES];
}
- (IBAction)btnGoToOriginalLocationSection:(id)sender {
   
    NSLog(@"%f", self.mkMapView.userLocation.location.coordinate.latitude);
    NSLog(@"%f", self.mkMapView.userLocation.location.coordinate.longitude);
    [_mkMapView setCenterCoordinate:_initialLocation.coordinate animated:YES];
}




#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError: %@", error);
   
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *newLocation = locations[[locations count] -1];
    currentLocation = newLocation;
    NSString *longitude = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude];
    NSString *latitude = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude];
    
    NSLog(@"%@", longitude);
     NSLog(@"%@", latitude);
}


#pragma UItableview delegates -

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _pinChats.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"PInDetailTableViewCell";
    UINib *nib = [UINib nibWithNibName:@"PInDetailTableViewCell"  bundle:[NSBundle bundleWithIdentifier:@"googlemapsdk.ParanoidFramework"]];
    [tableView registerNib:nib forCellReuseIdentifier:CellIdentifier];
    
    PInDetailTableViewCell *cell = (PInDetailTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    selPinChat = _pinChats[_pinChats.count - indexPath.row - 1];
    
    [cell.lblCommentView setText:selPinChat.pinChatMessage];
    cell.selPinChat = selPinChat;
    [cell.nameLable setText:selPinChat.fullname];
    [cell.lblImageDate setText: [NSString stringWithFormat:@"%@%@",selPinChat.pinChatPhoto, selPinChat.PinChatDateCreated]];
    if (selPinChat.profileAvatar != [NSNull null]) {
        
        NSURL *profileAvatarURL = [NSURL URLWithString:selPinChat.profileAvatar];
        [self downloadImageWithURL:profileAvatarURL completionBlock:^(BOOL succeeded, UIImage *image) {
            if (succeeded) {
                
                UIImage *avatarImage = image;
                [cell.userAvatar setImage:avatarImage];
            }
        }];
        
    }

    cell.queue = self.queue;
    
    
    Boolean isPinChatLike = selPinChat.isliked;
    if (isPinChatLike) {
        [cell.btnLike setBackgroundImage:[UIImage imageNamedFromFramework:@"sdk_active_favorite.png"] forState:UIControlStateNormal];
    } else{
        [cell.btnLike setBackgroundImage:[UIImage imageNamedFromFramework:@"sdk_favorite.png"] forState:UIControlStateNormal];
    }
    
    NSString *imagename = selPinChat.pinChatPhoto;
    
    if (imagename != nil) {
        if ([imagename isEqualToString: @""]) {
            
        } else {
            
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imagename]]];
            
            [cell.imgFeedbackView setImage: image];
            
            float aspectRatio = image.size.height / image.size.width;
            NSLayoutConstraint *photoHeightConstraint = [NSLayoutConstraint constraintWithItem:cell.imgFeedbackView
                                                                                     attribute:NSLayoutAttributeHeight
                                                                                     relatedBy:NSLayoutRelationEqual
                                                                                        toItem:cell.imgFeedbackView
                                                                                     attribute:NSLayoutAttributeWidth
                                                                                    multiplier:aspectRatio
                                                                                      constant:0];
            [cell.imgFeedbackView addConstraint:photoHeightConstraint];
            
        }

    }
    
    cell.replyButton.tag = indexPath.row;
    currentReplyName = [NSString stringWithFormat:@"%@%@", @"@ ",selPinChat.fullname];
    
    [cell.replyButton addTarget:self action:@selector(cellReplyButtonSection:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
    
}


-(void) cellReplyButtonSection:(UIButton*)sender
{
//    if (sender.tag == 0)
//    {
//        [self.txtComment setText:currentReplyName];
//        
//    }
    
    [self.txtComment setText:currentReplyName];
    [self.txtComment becomeFirstResponder];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    chosenImage = info[UIImagePickerControllerEditedImage];
//    self.imageView.image = chosenImage;
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}

- (IBAction)btnTakePhotoAction:(id)sender {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    [self presentViewController:picker animated:YES completion:NULL];
}


- (IBAction)btnCaptureVideoSection:(id)sender {
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = YES;
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
        
        [self presentViewController:picker animated:YES completion:NULL];
    }
}

- (IBAction)btnfavoriteClickSection:(id)sender {
    
}

- (IBAction)btnTopNumberClickSection:(id)sender {
    
}

- (IBAction)btnBottomNumberClickSection:(id)sender {
    
}

- (IBAction)btnSwitchMapViewSection:(id)sender {
    _pinDetailView.hidden = YES;
}

- (IBAction)btnFavoriteSection:(id)sender {
    
}

- (IBAction)btnUploadSection:(id)sender {
   
//    NSString *textToShare = @"Look at this awesome website for aspiring iOS Developers!";
//    NSURL *myWebsite = [NSURL URLWithString:@"http://www.codingexplorer.com/"];
//    
//    NSArray *objectsToShare = @[textToShare, myWebsite];
//    
    NSString *faceBook = @"FaceBook";
    NSURL *faceBookSite = [NSURL URLWithString:@"http://www.facebook.com/"];
    
    NSArray *objectsToShare = @[faceBook, faceBookSite];
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:nil];
    
//    NSArray *excludeActivities = @[UIActivityTypeAirDrop,
//                                   UIActivityTypePrint,
//                                   UIActivityTypeAssignToContact,
//                                   UIActivityTypeSaveToCameraRoll,
//                                   UIActivityTypeAddToReadingList,
//                                   UIActivityTypePostToFlickr,
//                                   UIActivityTypePostToVimeo,
//                                   UIActivityTypePostToFacebook
//                                   ];
//    
//    activityVC.excludedActivityTypes = excludeActivities;
    
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (IBAction)btnLikeSection:(id)sender {
    isLike = !isLike;
    if (isLike) {
        [_btnLike setBackgroundImage:[UIImage imageNamedFromFramework:@"sdk_active_favorite.png"] forState:UIControlStateNormal];
    } else {
        [_btnLike setBackgroundImage:[UIImage imageNamedFromFramework:@"sdk_greyheart.png"] forState:UIControlStateNormal];
    }
}

- (IBAction)btnSendsSection:(id)sender {
    
    if (_txtComment.text != nil) {
        if (![_txtComment.text isEqualToString:@""]) {
            [self addNewPinChatOperation:selPinChat];
        
        }

    }
        
}

- (void)setImageViewForPinType : (NSString *)pinType imageView:(UIImageView *)imageView{
    
    [imageView setImage:[imageDictionary objectForKey:pinType]];
}


- (void) addNewPinChatOperation :(PinChat *)selectPinChat {
    
    NSString *requestString = [NSString stringWithFormat:@"%@%@",kBaseUrl,kAddNewPinChatAPI];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    
    NSString *longitude = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude];
    NSString *latitude = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude];
    
    NSString *userid = [[NSUserDefaults standardUserDefaults]
                            stringForKey:@"userid"];

        NSMutableDictionary* _params = [[NSMutableDictionary alloc] init];
        [_params setObject:userid forKey:@"userid"];
        [_params setObject:selectPinChat.mapPinId forKey:@"pin_id"];
        [_params setObject:_txtComment.text forKey:@"message"];
        [_params setObject:latitude forKey:@"latitude"];
        [_params setObject:longitude forKey:@"longitude"];
    
    
        
        // the boundary string : a random string, that will not repeat in post data, to separate post data fields.
        NSString *BoundaryConstant = @"----------V2ymHFg03ehbqgZCaKO6jy";
        
        NSURL* requestURL = [NSURL URLWithString:requestString];
        
        // create request
        
        [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
        [request setHTTPShouldHandleCookies:NO];
//        [request setTimeoutInterval:30];
        [request setHTTPMethod:@"POST"];
        
        NSString *authToken = @"SCta}*XTV1R6SCta}*XTV1R6";
        [request setValue:authToken forHTTPHeaderField:kAuthToken];
        
        // set Content-Type in HTTP header
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", BoundaryConstant];
        [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
        
        // post body
        NSMutableData *body = [NSMutableData data];
        
        // add params (all params are strings)
        for (NSString *param in _params) {
            [body appendData:[[NSString stringWithFormat:@"--%@\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", param] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"%@\r\n", [_params objectForKey:param]] dataUsingEncoding:NSUTF8StringEncoding]];
        }
    
        if (chosenImage) {
        
                UIImage *imageToPost = [UIImage imageNamedFromFramework:@"sdk_active_favorite.png"];
                NSData *imageData = UIImagePNGRepresentation(imageToPost);
                if (imageData) {
                    [body appendData:[[NSString stringWithFormat:@"%@\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
                    [body appendData:[@"Content-Disposition: form-data; name=\"photo\"; filename=\"sdk_favorite.png\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                    [body appendData:[@"Content-Type: image/png\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                    [body appendData:imageData];
                    [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
                }
        }
    
        [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
        
        // setting the body of the post to the reqeust
        [request setHTTPBody:body];
        
        // set the content-length
        NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[body length]];
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        
        // set URL
        [request setURL:requestURL];
        
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];

}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
  
     respData = [[NSMutableData alloc] init];

    NSLog(@"@@@@@@@@@Data is:%@",response);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [respData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSError *errInfo;
    
    NSDictionary *mainDict= [NSJSONSerialization JSONObjectWithData:respData options:kNilOptions error:&errInfo];
    
    NSLog(@"maindictionary is %@",mainDict);
    
    NSError *jsonParsingError = nil;
    id object = [NSJSONSerialization JSONObjectWithData:respData options:0 error:&jsonParsingError];
    
    
    NSArray* latestLoans = [mainDict objectForKey:@"status"];
    
//    NSLog(@"loans: %@", latestLoans);
//    if (jsonParsingError)
//    {
//        NSLog(@"JSON ERROR: %@", [jsonParsingError localizedDescription]);
//    }
//    else
//    {
//        NSLog(@"OBJECT: %@", [object class]);
//    }

    if (latestLoans) {
        [self tableViewReloadData];
        
        [self dismissKeyboard];
        
        self.txtComment.text = @"";
        
    }
    
    chosenImage = nil;
    
}

- (void)downloadImageWithURL:(NSURL *)url completionBlock:(void (^)(BOOL succeeded, UIImage *image))completionBlock
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if ( !error )
                               {
                                   UIImage *image = [[UIImage alloc] initWithData:data];
                                   completionBlock(YES,image);
                               } else{
                                   completionBlock(NO,nil);
                               }
                           }];
}

@end
