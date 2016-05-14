//
//  ViewController.m
//  NOTAM
//
//  Created by Kostyantyn Bilyk on 07.05.16.
//  Copyright © 2016 Kostyantyn Bilyk. All rights reserved.
//

#import "MapViewController.h"

@interface MapViewController (){
    CLLocationManager *locationManager;
}

@end

@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Init Location Manager
    [self initLocationManager];
    
    // Set Initial Position for Map View with Current Location Marker
    [self initMapViewWithCurrentLocationMarker];
    
    self.searchBar.delegate = self;
    self.mapView.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillChange:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Google Maps

- (void)initMapViewWithCurrentLocationMarker{
    // Save Current Location for future use
    CLLocation *currentLocation = [self getCurrentLocation];
    
    [self setMapViewCameraPositionAndMarkerWithLocation:currentLocation
                                                andZoom:GOOGLE_MAPS_INITIAL_ZOOM];
    
}

- (CLLocation *)getCurrentLocation{
    CLLocation *location = [CLLocation new];
    if (locationManager.location) {
        location = locationManager.location;
    } else {
        location = [[CLLocation alloc] initWithLatitude:GOOGLE_MAPS_INITIAL_LATITUDE
                                              longitude:GOOGLE_MAPS_INITIAL_LONGTITUDE];
    }
    return location;
}

- (void)setMapViewCameraPositionAndMarkerWithLocation:(CLLocation *)location andZoom:(NSNumber *)zoom{
    [self setMapViewCameraPositionWithLocation:location andZoom:zoom];
    [self setMapViewMarkerWithLocation:location];
}

- (void)setMapViewCameraPositionWithLocation:(CLLocation *)location andZoom:(NSNumber *)zoom{
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:location.coordinate.latitude
                                                            longitude:location.coordinate.longitude
                                                                 zoom:[zoom floatValue]];
    self.mapView.camera = camera;
}

- (void)setMapViewMarkerWithLocation:(CLLocation *)location{
    GMSMarker *marker = [GMSMarker new];
    marker.position = CLLocationCoordinate2DMake(location.coordinate.latitude,
                                                 location.coordinate.longitude);
    marker.map = self.mapView;
}

- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate{
    [self.view endEditing:YES];
}

#pragma mark - Location Manager

- (void)initLocationManager{
    if (!locationManager) {
        locationManager = [[CLLocationManager alloc] init];
        
        locationManager.delegate = self;
        [locationManager requestWhenInUseAuthorization];
        
        locationManager.distanceFilter = kCLDistanceFilterNone;
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters; // 100 m
        
        [locationManager startUpdatingLocation];
    }
}

#pragma mark - Search Bar

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self.view endEditing:YES];
    [self performSearchAction];
}

- (void)performSearchAction{
    [self requestNOTAMWithAirportICAOCodeString:self.searchBar.text];
}

#pragma mark – Keyboard

- (void)keyboardWillChange:(NSNotification *)notification {
    
    // Animate the current view out of the way
    [self moveViewForKeyboardNotification:notification];
}


- (void)moveViewForKeyboardNotification:(NSNotification *)notification{
    NSDictionary* userInfo = [notification userInfo];
    
    // Get animation info from userInfo
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    
    CGRect keyboardEndFrame;
    
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    
    
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
    
    // Animate up or down
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    
    CGRect newFrame = self.view.frame;
    CGRect keyboardFrame = [self.view convertRect:keyboardEndFrame toView:nil];
    
    newFrame.origin.y -= keyboardFrame.size.height * (self.view.frame.origin.y < 0 ? -1 : 1);
    self.view.frame = newFrame;
    
    [UIView commitAnimations];
}

#pragma mark - NOTAM

- (void)requestNOTAMWithAirportICAOCodeString:(NSString *)string{
    notamBinding *binding = [notamService notamBinding];
    
    NSString *soapRequest = [NSString stringWithFormat:
                             NOTAM_REQUEST_STRING,
                             ROKET_ROUTE_LOGIN,
                             ROKET_ROUTE_PWORD,
                             string];
    
    [binding getNotamAsyncUsingRequest:soapRequest
                              delegate:self];
}

#pragma mark – NOTAM Binding Response Delegate

- (void)operation:(notamBindingOperation *)operation completedWithResponse:(notamBindingResponse *)response{
    DLog(@"Responce: %@", [response.bodyParts objectAtIndex:0]);
}

@end
