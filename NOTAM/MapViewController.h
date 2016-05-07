//
//  ViewController.h
//  NOTAM
//
//  Created by Kostyantyn Bilyk on 07.05.16.
//  Copyright © 2016 Kostyantyn Bilyk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MapViewController : UIViewController <CLLocationManagerDelegate, UISearchBarDelegate, GMSMapViewDelegate>

@property (weak, nonatomic) IBOutlet GMSMapView *mapView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@end

