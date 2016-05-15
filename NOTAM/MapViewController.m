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

- (id)init{
    if (!self) {
        self = [super init];
    }
    
    // Init Parameters
    self.items = [NSMutableArray new];
    self.parserError = nil;
    self.currentXMLElement = @"";
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Init Location Manager
    [self initLocationManager];
    [self initMapViewWithCurrentLocation];
    
    // Setup Delegates
    self.searchBar.delegate = self;
    self.mapView.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Register for keyboard notifications
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

- (void)initMapViewWithCurrentLocation{
    [self setMapViewCameraPositionWithLocation:[self getCurrentLocation]
                                       andZoom:GOOGLE_MAPS_INITIAL_ZOOM];
}

- (CLLocation *)getCurrentLocation{
    
    // Create Location to return
    CLLocation *location = [CLLocation new];
    
    // Check if Location Manager can provide Curren Location
    if (locationManager.location) {
        location = locationManager.location;
    } else {
        
        // If Location Manager can't provide Current Location return Lviv Location
        location = [[CLLocation alloc] initWithLatitude:GOOGLE_MAPS_INITIAL_LATITUDE
                                              longitude:GOOGLE_MAPS_INITIAL_LONGTITUDE];
    }
    return location;
}

- (void)setMapViewCameraPositionWithLocation:(CLLocation *)location andZoom:(NSNumber *)zoom{
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:location.coordinate.latitude
                                                            longitude:location.coordinate.longitude
                                                                 zoom:[zoom floatValue]];
    self.mapView.camera = camera;
}

- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate{
    
    // Hide Keyboard if User tap on Map
    [self.view endEditing:YES];
}

- (void)mapView:(GMSMapView *)mapView didTapInfoWindowOfMarker:(GMSMarker *)marker{
    
    // If NOTAM Info does not fit marker.snippet on tap Alert with full info is shown
    if ([marker.snippet length] > 160 || [[marker.snippet componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] count] > 3) {
        
        // Present NOTAM Info Details in Alert
        [self presentAlertWithTitle:@"NOTAM Details"
                             button:@"Ok"
                         andMessage:marker.snippet];
    }
}

#pragma mark - Location Manager

- (void)initLocationManager{
    if (!locationManager) {
        locationManager = [[CLLocationManager alloc] init];
        
        locationManager.delegate = self;
        if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [locationManager requestWhenInUseAuthorization];
        }
        
        locationManager.distanceFilter = kCLDistanceFilterNone;
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters; // 100 m
        
        [locationManager startMonitoringSignificantLocationChanges];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    
    // Set Camera Location when Location Manager update location
    [self setMapViewCameraPositionWithLocation:[locations lastObject]
                                       andZoom:GOOGLE_MAPS_INITIAL_ZOOM];
}

#pragma mark - Search Bar

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    // Hide Keyboard
    [self.view endEditing:YES];
    
    // Start Seraching Process
    [self performSearchAction];
}

- (void)performSearchAction{
    if ([self isValidAirportICAOCodeWithString:self.searchBar.text]) {
        
        // Clera Map View to display new search results
        [self.mapView clear];
        self.items = [NSMutableArray new];
        
        // Display progress hud
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        // Perfor NOTAM request
        [self requestNOTAMForAirportICAOCodeWithString:self.searchBar.text];
    }
}

- (BOOL)isValidAirportICAOCodeWithString:(NSString *)string{
    
    // Load Regexp Pattern
    NSString *pattern = AIRPORT_ICAO_CODE_PATTERN;
    
    // Prepare Validation Error
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    NSString *errorLocalizedDescriptionString = @"ICAO Airport Code must contain 4 letters. Try again.";
    [userInfo setValue:errorLocalizedDescriptionString forKey:NSLocalizedDescriptionKey];
    
    NSError *error = [NSError errorWithDomain:@"Search"
                                         code:0
                                     userInfo:userInfo];

    // Set Regexp
    NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                                       options:0
                                                                                         error:&error];
    // Validate Code
    NSArray  *validCodes = [regularExpression matchesInString:string
                                                      options:0
                                                        range:NSMakeRange(0, [string length])];
    // Check if there is valid ICAO Code
    if ([validCodes count] > 0) {
        return YES;
    } else {
        
        // Present Validation Error
        [self presentErrorAlertWithError:error];
    }
    return NO;
}

#pragma mark - Keyboard

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
    
    // Get Keyaboard Frame in the end of animation
    CGRect keyboardFrame = [self.view convertRect:keyboardEndFrame toView:nil];
    
    // Move View up or down on height of Keyboard base on y position
    newFrame.origin.y -= keyboardFrame.size.height * (self.view.frame.origin.y < 0 ? -1 : 1);
    
    // Set new Frame for View
    self.view.frame = newFrame;
    
    [UIView commitAnimations];
}

#pragma mark - NOTAM

- (void)requestNOTAMForAirportICAOCodeWithString:(NSString *)string{
    
    // Crate NOTAM Binding
    notamBinding *binding = [notamService notamBinding];
    
    // Set Reques String
    NSString *soapRequest = [NSString stringWithFormat:
                             NOTAM_REQUEST_STRING,
                             ROKET_ROUTE_LOGIN,
                             ROKET_ROUTE_PWORD,
                             string];
    
    // Run NOTAM Request
    [binding getNotamAsyncUsingRequest:soapRequest
                              delegate:self];
}

- (void)setNOTAMMarkerWithItem:(Item *)item{
    
    // Create new Marker
    GMSMarker *marker = [GMSMarker new];
    
    // Set Marker details from NOTAM Item
    marker.position = item.location.coordinate;
    marker.snippet = item.infoString;
    
    // Set icon and place Marker on Map
    marker.icon = [UIImage imageNamed:@"WarningIcon"];
    marker.map = self.mapView;
}

#pragma mark - NOTAM Binding Response Delegate

- (void)operation:(notamBindingOperation *)operation completedWithResponse:(notamBindingResponse *)response{
    DLog(@"Responce: %@", [response.bodyParts objectAtIndex:0]);
    
    // Save Responce XML to NSData object in order to parse it
    NSData *responceXMLData = [response.bodyParts[0] dataUsingEncoding:NSASCIIStringEncoding];
    
    // Create Parser Instance
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:responceXMLData];
    parser.delegate = self;
    
    // Start parsing process
    [parser parse];
}

#pragma mark - NSXML Parser Delegate Methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{
    
    // Save Current XML Elemet to work with
    self.currentXMLElement = elementName;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
    
    // Pocessing Responce Status
    if ([self.currentXMLElement isEqualToString:@"RESULT"])
    {
        NSNumberFormatter *numberFormatter = [NSNumberFormatter new];
        numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        NSNumber *resultNumber = [numberFormatter numberFromString:string];
        
        if ([resultNumber integerValue] != 0) {
            
            // Prepare Responce Error Code
            NSMutableDictionary *userInfo = [NSMutableDictionary new];
            [userInfo setValue:@"Unknown error!" forKey:NSLocalizedDescriptionKey];
            
            self.parserError = [NSError errorWithDomain:@"NOTAM" code:[resultNumber integerValue] userInfo:userInfo];
        } else {
            self.parserError = nil;
        }
    } else if ([self.currentXMLElement isEqualToString:@"MESSAGE"]) {
        
        // Prepare Responce Error Message
        NSMutableDictionary *userInfo = [NSMutableDictionary new];
        [userInfo setValue:string forKey:NSLocalizedDescriptionKey];
        
        // Save Error to show after Parser end XML Document
        self.parserError = [NSError errorWithDomain:@"NOTAM" code:self.parserError.code userInfo:userInfo];
    }
    
    // Processing NOTAM Item Coordinates and Info
    if ([self.currentXMLElement isEqualToString:@"ItemQ"]) {
        
        Item *newItem = [Item new];
        [self.items addObject:newItem];
        
        [[self.items lastObject] setLocation:[self locationFromItemQString:string]];
    } else if ([self.currentXMLElement isEqualToString:@"ItemE"])
    {
        [[self.items lastObject] setInfoString:string];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
    
    // Clear Current XML Elemet
    self.currentXMLElement = @"";
}

- (void) parserDidEndDocument:(NSXMLParser *)parser{
    
    // Check if there were Error
    if (self.parserError){
        [self presentErrorAlertWithError:self.parserError];
    }
    
    // Place NOTAM Markers on Map
    [self setNOTAMMarkersWithItemsArray:self.items];
    
    // Remove Progress HUD after processing XML Responce
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

- (void)setNOTAMMarkersWithItemsArray:(NSArray *)array{
    
    // Check if there any NOTAM Items in Array
    if ([array count] !=0) {
        
        // Set NOTAM Markres on Map for every NOTAM in Array
        for (Item *item in array) {
            
            [self setNOTAMMarkerWithItem:item];
            
            // Move Camera Postition to last NOTAM location
            if ([item isEqual:[array lastObject]]) {
                
                [self setMapViewCameraPositionWithLocation:item.location
                                                   andZoom:GOOGLE_MAPS_INITIAL_ZOOM];
            }
        }
    } else {
        
        // Prepare Error for empty NOTAM on ICAO Code
        NSMutableDictionary *userInfo = [NSMutableDictionary new];
        NSString *errorLocalizedDescriptionString = [NSString stringWithFormat:@"There is no NOTAM for \"%@\" ICAO Airport Code. Try again.", self.searchBar.text];
        [userInfo setValue:errorLocalizedDescriptionString forKey:NSLocalizedDescriptionKey];
        
        NSError *error = [NSError errorWithDomain:@"NOTAM"
                                             code:0
                                         userInfo:userInfo];
        
        [self presentErrorAlertWithError:error];
    }
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
    self.searchBar.text = @"";
    
    [self presentAlertWithTitle:ALERT_TITLE
                         button:ALERT_BUTTON
                     andMessage:error.localizedDescription];
}

- (void)presentAlertWithTitle:(NSString *)title button:(NSString *)button andMessage:(NSString *)message{
    if ([UIAlertController class]){
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                                 message:message
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *buttonAction = [UIAlertAction actionWithTitle:button
                                                               style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                               }];
        
        [alertController addAction:buttonAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:title
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:button
                                              otherButtonTitles:nil, nil];
        [alert show];
    }
}


@end
