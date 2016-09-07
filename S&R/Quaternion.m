//
//  Quaternion.m
//  test
//
//  Created by Justin Moser on 6/16/14.
//  Copyright (c) 2014 Justin Moser. All rights reserved.
//

#import "Quaternion.h"

@implementation Quaternion {
    double _lastYaw;
}

#pragma mark - Class Methods

+(Quaternion *)copyQuaternion:(Quaternion *)q {
    Quaternion *quat = [[Quaternion alloc]initWithValues:q.w x:q.x y:q.y z:q.z];
    return quat;
}

+(Quaternion *)quaternionWithValues:(double)w x:(double)x y:(double)y z:(double)z {
    return [[Quaternion alloc]initWithValues:w x:x y:y z:z];
}

+(Quaternion *)xQuaternion {
    return [[Quaternion alloc]initWithValues:0.0 x:1.0 y:0.0 z:0.0];
}

+(Quaternion *)yQuaternion {
    return [[Quaternion alloc]initWithValues:0.0 x:0.0 y:1.0 z:0.0];
}

+(Quaternion *)zQuaternion {
    return [[Quaternion alloc]initWithValues:0.0 x:0.0 y:0.0 z:1.0];
}



#pragma mark - Instance Methods

-(instancetype)initWithCMQuaternion:(CMQuaternion)q {
    if (self = [super init]) {
        _x = q.x;
        _y = q.y;
        _z = q.z;
        _w = q.w;
    }
    return self;
}

-(instancetype)initWithValues:(double)w2 x:(double)x2 y:(double)y2 z:(double)z2 {
    if (self = [super init]) {
        _x = x2;
        _y = y2;
        _z = z2;
        _w = w2;
    }
    return self;
}

-(Quaternion*)multiply:(Quaternion*)q {
    double newW = _w * q.w - _x * q.x - _y * q.y - _z * q.z;
    double newX = _w * q.x + _x * q.w + _y * q.z - _z * q.y;
    double newY = _w * q.y + _y * q.w + _z * q.x - _x * q.z;
    double newZ = _w * q.z + _z * q.w + _x * q.y - _y * q.x;
    _w = newW;
    _x = newX;
    _y = newY;
    _z = newZ;
    return self;
}

-(Quaternion*)qMultiply:(Quaternion*)q {
    return [[Quaternion copyQuaternion:self]multiply:q];
}

-(Quaternion *)qX {
    Quaternion *q = [Quaternion copyQuaternion:self];
    [q multiply:[Quaternion xQuaternion]];
    [q multiply:[self qInverse]];
    return q;
}

-(Quaternion *)qY {
    Quaternion *q = [Quaternion copyQuaternion:self];
    [[q multiply:[Quaternion yQuaternion]]multiply:[self qInverse]];
    return q;
}

-(Quaternion *)qZ {
    Quaternion *q = [Quaternion copyQuaternion:self];
    [q multiply:[Quaternion zQuaternion]];
    [q multiply:[self qInverse]];
    return q;
}

-(double)norm {
    return sqrt(_w*_w + _x*_x + _y*_y + _z*_z);
}

-(void)normalize {
    double length = [self norm];
    _w /= length;
    _x /= length;
    _y /= length;
    _z /= length;
}

-(Quaternion *)qNormalize {
    Quaternion *q = [Quaternion copyQuaternion:self];
    [q normalize];
    return q;
}

-(Quaternion *)qInverse {
    Quaternion *q = [Quaternion new];
    q.w =_w;
    q.x = -_x;
    q.y = -_y;
    q.z = -_z;
    return q;
}

-(void)divideBy:(Quaternion *)r {
    Quaternion *t = [Quaternion new];
    double norm = [r norm];
    t.w = (r.w * _w + r.x * _x + r.y * _y + r.z * _z) / norm;
    t.x = (r.w * _x - r.x * _w - r.y * _z + r.z * _y) / norm;
    t.y = (r.w * _y + r.x * _z - r.y * _w - r.z * _x) / norm;
    t.y = (r.w * _z - r.x * _y + r.y * _x - r.z * _x) / norm;
    _w = t.w;
    _x = t.x;
    _y = t.y;
    _z = t.z;
}

-(Quaternion *)qDivideBy:(Quaternion *)r {
    Quaternion *t = [Quaternion new];
    double norm = [r norm];
    t.w = (r.w * _w + r.x * _x + r.y * _y + r.z * _z) / norm;
    t.x = (r.w * _x - r.x * _w - r.y * _z + r.z * _y) / norm;
    t.y = (r.w * _y + r.x * _z - r.y * _w - r.z * _x) / norm;
    t.y = (r.w * _z - r.x * _y + r.y * _x - r.z * _x) / norm;
    return t;
}

//-(Vector *)rotateVector:(Vector *)v {
//    double x = (1.0 - 2.0 * _y * _y - 2.0 * _z * _z) * v.x + 2.0 * (_x * _y + _w * _z) * v.y + 2.0 * (_x * _z - _w * _y) *v.z;
//    double y = 2*(_x*_y-_w*_z)*v.x + (1-2*_x*_x-2*_z*_z)*v.y + 2*(_y*_z-_w*_y)*v.z;
//    double z = 2*(_y*_z+_w*_y)*v.x + 2*(_y*_z-_w*_x)*v.y + (1-2*_x*_x-2*_y*_y)*v.z;
//    v.x = x;
//    v.y = y;
//    v.z = z;
//    return v;
//}


-(Quaternion *)qConjugate {
    return [self qInverse];
}

-(Quaternion *)squared {
    Quaternion *q = [Quaternion copyQuaternion:self];
    q.w = _w * _w - _x * _x - _y * _y - _z * _z;;
    q.x = 2.0 * _w * _x;
    q.y = 2.0 * _w * _y;
    q.z = 2.0 * _w * _z;
    return q;
}

-(double)real {
    return _w;
}

-(double)imaginary {
    return _x*_x + _y*_y + _z*_z;
}

-(double)dotProduct:(Quaternion *)q {
    double q1q2 = _w * q.w + _x * q.x + _y * q.y + _z * q.z;
    return q1q2 / ([self norm] * [q norm]);
}

-(double)angleInbetween:(Quaternion *)q {
    return acos([self dotProduct:q]);
}


#pragma mark - Euler

-(double)yaw {
    return asin(2.0 * (_x * _z - _w * _y));
}

-(double)smoothYaw {
    double yaw = [self yaw];
    static float q = 0.1;
    static float r = 0.1;
    static float p = 0.1;
    static float k = 0.1;
    
    if (!_lastYaw) {
        _lastYaw = 0;
    }
    
    float smoothYaw = _lastYaw;
    p = p + q;
    k = p / (p + r);
    smoothYaw = smoothYaw + k*(yaw - smoothYaw);
    p = (1 - k)*p;
    _lastYaw = smoothYaw;
    
    return smoothYaw;
}

#pragma mark - Vector Manipulation

-(Vector *)rotatePoint:(Vector *)v {
    Quaternion *q = [Quaternion copyQuaternion:self];
    Quaternion *e = [Quaternion quaternionWithValues:0.0 x:v.x y:v.y z:v.z];
    Quaternion *qi = [self qInverse];
    Quaternion *q2 = [[q multiply:e]multiply:qi];
    return [Vector vectorWithValuesX:q2.x y:q2.y z:q2.z];
}

-(Vector *)rotateFrame:(Vector *)v {
    Quaternion *q = [Quaternion copyQuaternion:self];
    Quaternion *e = [Quaternion quaternionWithValues:0.0 x:v.x y:v.y z:v.z];
    Quaternion *qi = [self qInverse];
    Quaternion *q2 = [[qi multiply:e]multiply:q];
    return [Vector vectorWithValuesX:q2.x y:q2.y z:q2.z];
}

+(Quaternion *)quaternionFromRoll:(double)roll pitch:(double)pitch yaw:(double)yaw {
    double w,x,y,z;
    roll /= 2;
    pitch /= 2;
    yaw /= 2;
    
    w = cos(roll) * cos(pitch) * cos(yaw) - sin(roll) * cos(pitch) * sin(yaw);
    x = cos(roll) * cos(yaw) * sin(pitch) + sin(roll) * sin(pitch) * sin(yaw);
    y = cos(roll) * sin(pitch) * sin(yaw) - sin(roll) * cos(yaw) * sin(pitch);
    z = cos(roll) * cos(pitch) * sin(yaw) + cos(pitch) * cos(yaw) * sin(roll);
    
    return [Quaternion quaternionWithValues:w x:x y:y z:z];
}


#pragma mark - In Progress, however, probably not useful

-(double)rotationAroundX {
    double angle;
    return angle;
}

-(double)rotationAroundY {
    double angle;
    return angle;
}

-(double)rotationAroundZ {
    double angle;
    return angle;
}



@end



