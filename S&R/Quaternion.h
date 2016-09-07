//
//  Quaternion.h
//  test
//
//  Created by Justin Moser on 6/16/14.
//  Copyright (c) 2014 Justin Moser. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import "Vector.h"

@interface Quaternion : Vector {
    double _w;
}

@property (readwrite, assign) double w;

+(Quaternion *)xQuaternion;
+(Quaternion *)yQuaternion;
+(Quaternion *)zQuaternion;

+(Quaternion *)copyQuaternion:(Quaternion *)q;
+(Quaternion *)quaternionWithValues:(double)w x:(double)x y:(double)y z:(double)z;

-(instancetype)initWithCMQuaternion:(CMQuaternion)q;

- (instancetype)initWithValues:(double)w2 x:(double)x2 y:(double)y2 z:(double)z2;

-(Quaternion*)multiply:(Quaternion*)q;
-(void)divideBy:(Quaternion *)q;
-(Quaternion *)qDivideBy:(Quaternion *)r;

-(Quaternion *)squared;
-(Quaternion *)qConjugate;

-(double)norm;
-(void)normalize;
-(double)yaw;
-(double)smoothYaw;
-(double)angleInbetween:(Quaternion *)q;
-(double)dotProduct:(Quaternion *)q;

-(double)imaginary;
-(double)real;

//very important methods!!
-(Quaternion *)qX;
-(Quaternion *)qY;
-(Quaternion *)qZ;

-(Quaternion *)qNormalize;
-(Quaternion *)qInverse;
-(Quaternion*)qMultiply:(Quaternion*)q;


//-(Vector *)rotateVector:(Vector *)v;
-(Vector *)rotatePoint:(Vector *)v;
-(Vector *)rotateFrame:(Vector *)v;

+(Quaternion *)quaternionFromRoll:(double)roll pitch:(double)pitch yaw:(double)yaw;


@end
