//
//  SpatialManager.h
//  SR1
//
//  Created by Justin Moser on 6/20/14.
//  Copyright (c) 2014 Justin Moser. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Orientation.h"

typedef struct {
    double latitude;
    double longitude;
    double altitude;
}SpatialData;

@interface SpatialManager : NSObject

-(void)start;
-(void)stop;

-(Quaternion *)currentOrientation;
-(SpatialData)getSpatialData;

@end
