//
//  Vector.h
//  test
//
//  Created by Justin Moser on 6/18/14.
//  Copyright (c) 2014 Justin Moser. All rights reserved.
//

#import <Foundation/Foundation.h>

#define Rad_To_Deg 180/M_PI
#define Deg_To_Rad M_PI/180

@interface Vector : NSObject {
    double _x;
    double _y;
    double _z;
}

@property (readwrite, assign) double x;
@property (readwrite, assign) double y;
@property (readwrite, assign) double z;

+(instancetype)vectorWithVector:(Vector *)vector;
+(instancetype)vectorWithValuesX:(double)x y:(double)y z:(double)z;

-(double)norm;
-(void)normalize;

-(double)dotProduct:(Vector *)v;
-(Vector *)vCrossProduct:(Vector *)v;

-(double)angleInbetween:(Vector *)v;


@end
