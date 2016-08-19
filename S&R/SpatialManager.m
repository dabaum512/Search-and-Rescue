//
//  SpatialManager.m
//  SR1
//
//  Created by Justin Moser on 6/20/14.
//  Copyright (c) 2014 Justin Moser. All rights reserved.
//

#import "SpatialManager.h"
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>

CMAttitudeReferenceFrame frame = CMAttitudeReferenceFrameXTrueNorthZVertical;


@interface SpatialManager() <CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CMMotionManager *motionManager;
@end

@implementation SpatialManager

-(instancetype)init {
    if (self = [super init]) {
        [self startInternal];
    }
    return self;
}

-(void)start {
    [self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:frame];
    [self.locationManager startUpdatingLocation];
}

-(void)stop {
    [self.motionManager stopDeviceMotionUpdates];
    [self.locationManager stopUpdatingLocation];
}

-(Quaternion *)currentOrientation {
    return [[Quaternion alloc]initWithCMQuaternion:_motionManager.deviceMotion.attitude.quaternion];
}

-(SpatialData)getSpatialData {
    SpatialData data;
    data.latitude = self.locationManager.location.coordinate.latitude;
    data.longitude = self.locationManager.location.coordinate.longitude;
    data.altitude = self.locationManager.location.altitude;
    return data;
}

-(void)startInternal {
    
    if (!self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
    }
    [self.locationManager requestWhenInUseAuthorization];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    self.locationManager.pausesLocationUpdatesAutomatically = NO;
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    self.locationManager.headingFilter = kCLHeadingFilterNone;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //    [self.locationManager startUpdatingHeading];
        [self.locationManager startUpdatingLocation];
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!self.motionManager) {
            self.motionManager = [CMMotionManager new];
            self.motionManager.showsDeviceMovementDisplay = YES;
            [self.motionManager setDeviceMotionUpdateInterval:0.02];
            
            [self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:frame];
            
//            [self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:frame toQueue:[NSOperationQueue new] withHandler:^(CMDeviceMotion *motion, NSError *error) {
//                //
//                if (error) {
//                    NSLog(@"%@",error);
//                }
//                NSLog(@"%f",motion.attitude.yaw);
//                NSLog(@"%f",self.motionManager.deviceMotion.attitude.yaw);
//            }];
        }
    });
}

@end
