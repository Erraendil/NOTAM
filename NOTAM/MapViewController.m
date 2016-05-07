//
//  ViewController.m
//  NOTAM
//
//  Created by Kostyantyn Bilyk on 07.05.16.
//  Copyright © 2016 Kostyantyn Bilyk. All rights reserved.
//

#import "MapViewController.h"
#import <CoreLocation/CoreLocation.h>

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

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    
}



@end
