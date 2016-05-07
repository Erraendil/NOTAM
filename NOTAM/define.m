//
//  define.m
//  NOTAM
//
//  Created by Kostyantyn Bilyk on 07.05.16.
//  Copyright © 2016 Kostyantyn Bilyk. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark – Development Defines

#ifdef DEBUG
#define DLog(...) NSLog(__VA_ARGS__)
#else
#define DLog(...) while(0)
#endif

#pragma mark – Google Maps

#define GOOGLE_MAPS_API_KEY @"AIzaSyAEbcuoGfEoW0Ed66f2I6M0BaFcGRMYBWo"
#define GOOGLE_MAPS_INITIAL_ZOOM @6
#define GOOGLE_MAPS_INITIAL_LATITUDE 49.8333333
#define GOOGLE_MAPS_INITIAL_LONGTITUDE 24
