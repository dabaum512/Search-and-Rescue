//
//  Orientation.m
//  test
//
//  Created by Justin Moser on 6/18/14.
//  Copyright (c) 2014 Justin Moser. All rights reserved.
//

#import "Orientation.h"

@implementation Orientation

-(double)primaryYaw {

    //normal is literally the vector that points out the back of the phone
    Quaternion *normal = [self qNormal];
    
    //this essentially projects the 3D vector onto the XY plane
    normal.z = 0;
    
    double angleInbetweenX = [normal angleInbetween:[Quaternion xQuaternion]]*Rad_To_Deg;
    double angleInbetweenY = [normal angleInbetween:[Quaternion yQuaternion]]*Rad_To_Deg;
    if (angleInbetweenY < 90) {
        angleInbetweenX = 360 - angleInbetweenX;
    }
    return angleInbetweenX;
}

-(double)primaryPitch {
    Quaternion *q = [self qNormal];
    Orientation *o = [[Orientation alloc]initWithValues:q.w x:q.x y:q.y z:q.z];
    return [o angleInbetween:[Quaternion quaternionWithValues:0.0 x:0.0 y:0.0 z:-1.0]] * Rad_To_Deg;
}

//This method is essentially the same as quaternion's yaw method and
//executes approximately 8 times faster than slowSecondaryYaw method
-(double)secondaryYaw {
    return -[super yaw] * Rad_To_Deg;
}

-(double)slowSecondaryYaw {
    Quaternion *qX = [self qX];
    Quaternion *flatQ = [Quaternion quaternionWithValues:0.0 x:qX.x y:qX.y z:0.0];
    [qX normalize];
    [flatQ normalize];
    double angle = [qX angleInbetween:flatQ]*Rad_To_Deg;
    if (qX.z > 0) {
        return -angle;
    }
    return angle;
}



#pragma mark - Helper Methods

-(Quaternion *)qNormal {
    Quaternion *q = [Quaternion copyQuaternion:self];                          //q
    Quaternion *e = [Quaternion quaternionWithValues:0.0 x:0.0 y:0.0 z:-1.0];  //e
    Quaternion *qi = [self qInverse];                                          //q'
    Quaternion *normal = [[q multiply:e]multiply:qi];                          //n = q*e*q'
    return normal;
}

-(double)angleFromNadirInRadians {
    return [self angleInbetween:[Quaternion quaternionWithValues:0.0 x:0.0 y:0.0 z:-1.0]];
}



@end
