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

#pragma mark - Singleton

#define SINGLETON_FOR_CLASS(classname)\
+ (id) shared##classname {\
static dispatch_once_t pred = 0;\
__strong static id _sharedObject = nil;\
dispatch_once(&pred, ^{\
_sharedObject = [[self alloc] init];\
});\
return _sharedObject;\
}

#pragma mark – Google Maps

#define GOOGLE_MAPS_API_KEY @"AIzaSyAEbcuoGfEoW0Ed66f2I6M0BaFcGRMYBWo"
#define GOOGLE_MAPS_INITIAL_ZOOM @6
#define GOOGLE_MAPS_INITIAL_LATITUDE 49.8333333
#define GOOGLE_MAPS_INITIAL_LONGTITUDE 24

#pragma mark - Search

#define AIRPORT_ICAO_CODE_PATTERN @"^[A-z]{4}$"

#pragma mark – NOTAM

#define ROKET_ROUTE_LOGIN @"kos.bilyk@gmail.com"
#define ROKET_ROUTE_PWORD @"a8cfe0bd7dd07badfa57f64c97b7d7e3"

#define NOTAM_REQUEST_STRING @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"\
"<REQNOTAM>"\
"<USR>%@</USR>"\
"<PASSWD>%@</PASSWD>"\
"<ICAO>%@</ICAO>"\
"</REQNOTAM>"
