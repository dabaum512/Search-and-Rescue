//
//  Elevation.h
//  SR1
//
//  Created by Justin Moser on 6/22/14.
//  Copyright (c) 2014 Justin Moser. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct {
    double latitude;
    double longitude;
}Location;

@interface Elevation : NSObject

+(Elevation *)getElevationForLocation:(Location)location andCallback:(void(^)(double,NSDate *))callback;

@end
