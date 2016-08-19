//
//  Vector.m
//  test
//
//  Created by Justin Moser on 6/18/14.
//  Copyright (c) 2014 Justin Moser. All rights reserved.
//

#import "Vector.h"

@implementation Vector

+(instancetype)vectorWithVector:(Vector *)vector {
    Vector *v = [Vector new];
    v.x = vector.x;
    v.y = vector.y;
    v.z = vector.z;
    return v;
}

+(instancetype)vectorWithValuesX:(double)x y:(double)y z:(double)z {
    Vector *v = [Vector new];
    v.x = x;
    v.y = y;
    v.z = z;
    return v;
}

-(double)norm {
    return sqrt(_x*_x + _y*_y + _z*_z);
}

-(void)normalize {
    double l = [self norm];
    _x /= l;
    _y /= l;
    _z /= l;
}

-(void)addVector:(Vector *)v {
    _x += v.x;
    _y += v.y;
    _z += v.z;
}

-(void)subtractVector:(Vector *)v {
    _x -= v.x;
    _y -= v.y;
    _z -= v.z;
}

-(double)dotProduct:(Vector *)v {
    return _x*v.x + _y*v.y + _z*v.z;
}

-(Vector *)vCrossProduct:(Vector *)v {
    Vector *v2 = [Vector new];
    v2.x = _y*v.z - _z*v.y;
    v2.y = _z*v.x - _x*v.z;
    v2.z = _x*v.y - _y*v.x;
    return v2;
}

-(double)angleInbetween:(Vector *)v {
    Vector *v1 = [Vector vectorWithVector:self];
    Vector *v2 = [Vector vectorWithVector:v];
    [v1 normalize];
    [v2 normalize];
    return acos([v1 dotProduct:v2]);
}

@end
