//
//  Item.h
//  NOTAM
//
//  Created by Kostyantyn Bilyk on 14.05.16.
//  Copyright © 2016 Kostyantyn Bilyk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Item : NSObject

@property (nonatomic, strong) CLLocation *location;
@property (nonatomic, strong) NSString *infoString;

@end
