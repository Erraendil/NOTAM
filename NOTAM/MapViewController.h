//
//  ViewController.h
//  NOTAM
//
//  Created by Kostyantyn Bilyk on 07.05.16.
//  Copyright © 2016 Kostyantyn Bilyk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "notamService.h"

@interface MapViewController : UIViewController <CLLocationManagerDelegate, UISearchBarDelegate, GMSMapViewDelegate, notamBindingResponseDelegate, NSXMLParserDelegate>

@property (weak, nonatomic) IBOutlet GMSMapView *mapView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@property (strong, nonatomic) NSString *currentXMLElement;
@property (strong, nonatomic) NSError *parserError;
@property (strong, nonatomic) NSMutableArray *items;

@end

