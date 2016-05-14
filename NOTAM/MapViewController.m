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
    
    self.items = [NSMutableArray new];
    self.parserError = nil;
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
    [self.mapView clear];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self requestNOTAMForAirportICAOCodeWithString:self.searchBar.text];
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

- (void)requestNOTAMForAirportICAOCodeWithString:(NSString *)string{
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
    
    NSData *responceXMLData = [response.bodyParts[0] dataUsingEncoding:NSASCIIStringEncoding];
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:responceXMLData];
    parser.delegate = self;
    [parser parse];
}

#pragma mark - NOTAM XML Parser

#pragma mark - NSXML Parser Delegate Methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{
    self.currentXMLElement = elementName;
    DLog(@"Current Elemt: %@", self.currentXMLElement);
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
    self.currentXMLElement = @"";
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
    if ([self.currentXMLElement isEqualToString:@"RESULT"])
    {
        NSNumberFormatter *numberFormatter = [NSNumberFormatter new];
        numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        NSNumber *resultNumber = [numberFormatter numberFromString:string];
        
        if ([resultNumber integerValue] != 0) {
            NSMutableDictionary *userInfo = [NSMutableDictionary new];
            [userInfo setValue:@"Unknown error!" forKey:NSLocalizedDescriptionKey];
            
            self.parserError = [NSError errorWithDomain:@"NOTAM" code:[resultNumber integerValue] userInfo:userInfo];
        } else {
            self.parserError = nil;
        }
    } else if ([self.currentXMLElement isEqualToString:@"MESSAGE"]) {
        NSMutableDictionary *userInfo = [NSMutableDictionary new];
        [userInfo setValue:string forKey:NSLocalizedDescriptionKey];
        
        self.parserError = [NSError errorWithDomain:@"NOTAM" code:self.parserError.code userInfo:userInfo];
    }
    
    if ([self.currentXMLElement isEqualToString:@"ItemQ"]) {
        
        Item *newItem = [Item new];
        [self.items addObject:newItem];
        
        [[self.items lastObject] setLocation:[self locationFromItemQString:string]];
    } else if ([self.currentXMLElement isEqualToString:@"ItemE"])
    {
        [[self.items lastObject] setInfoString:string];
    }
}

- (void) parserDidEndDocument:(NSXMLParser *)parser{
    self.parserError ? [self presentErrorAlertWithError:self.parserError] : DLog(@"Items: %@", self.items);
    
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    [self setNOTAMMarkersWithItemsArray:self.items];
}

- (void)setNOTAMMarkersWithItemsArray:(NSArray *)array{
    if ([array count] !=0) {
        for (Item *item in array) {
            [self setNOTAMMarkerWithItem:item];
            if ([item isEqual:[array lastObject]]) {
                [self setMapViewCameraPositionWithLocation:item.location andZoom:GOOGLE_MAPS_INITIAL_ZOOM];
            }
        }
    } else {
        // Place here an Alert!
    }
}

- (void)setNOTAMMarkerWithItem:(Item *)item{
    GMSMarker *marker = [GMSMarker new];
    marker.position = item.location.coordinate;
    marker.snippet = item.infoString;
    marker.icon = [UIImage imageNamed:@"WarningIcon"];
    marker.map = self.mapView;
}

#pragma mark - Location Formatting

- (CLLocation *)locationFromItemQString:(NSString *)string{
    CLLocation *location = [CLLocation new];
    
    NSString *locationString = [string lastPathComponent];
    NSString *degreeString = [self notamLocationStringToDegreeSting:locationString];
    NSString *lattitudeString = degreeString.pathComponents[0];
    NSString *longtitudeString = degreeString.pathComponents[1];
    double latitude = [self degreesStringToDecimal:lattitudeString];
    double longitude = [self degreesStringToDecimal:longtitudeString];
    
    location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
    
    return location;
}

-(NSString *)notamLocationStringToDegreeSting:(NSString *)notamLocation
{
    NSString *degreesLat = [notamLocation substringToIndex:2];
    notamLocation = [notamLocation substringFromIndex:2];
    NSString *minuteLat = [notamLocation substringToIndex:2];
    notamLocation = [notamLocation substringFromIndex: 2];
    NSString *directionLat = [notamLocation substringToIndex:1];
    notamLocation = [notamLocation substringFromIndex:1];
    
    NSString *latitudeString = [NSString stringWithFormat:@"%@\u00B0%@'%@/",degreesLat, minuteLat, directionLat];
    
    NSString *degreesLon = [notamLocation substringToIndex:3];
    notamLocation = [notamLocation substringFromIndex:3];
    NSString *minuteLon = [notamLocation substringToIndex:2];
    notamLocation = [notamLocation substringFromIndex: 2];
    NSString *directionLon = [notamLocation substringToIndex:1];
    notamLocation = [notamLocation substringFromIndex:1];
    
    NSString *longitudeString = [NSString stringWithFormat:@"%@\u00B0%@'%@",degreesLon, minuteLon, directionLon];
    NSString *degreeString = [latitudeString stringByAppendingString:longitudeString];
    
    return degreeString;
}

- (double)degreesStringToDecimal:(NSString*)string
{
    NSArray *splitDegs = [string componentsSeparatedByString:@"\u00B0"];
    NSArray *splitMins = [splitDegs[1] componentsSeparatedByString:@"'"];
    NSArray *splitSecs = [splitMins[1] componentsSeparatedByString:@"\""];
    
    NSString *degreesString = splitDegs[0];
    NSString *minutesString = splitMins[0];
    NSString *direction = splitSecs[0];
    
    double degrees = [degreesString doubleValue];
    double minutes = [minutesString doubleValue] / 60;
    double decimal = degrees + minutes;
    
    if ([direction.uppercaseString isEqualToString:@"W"] || [direction.uppercaseString isEqualToString:@"S"])
    {
        decimal = -decimal;
    }
    return decimal;
}

#pragma mark - Alert

- (void)presentErrorAlertWithError:(NSError *)error{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Error Code %i!", (int)error.code]
                                                                             message:error.localizedDescription
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *buttonAction = [UIAlertAction actionWithTitle:@"Ok"
                                                           style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                               // Add Button Action here
                                                           }];
    
    [alertController addAction:buttonAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}


@end
