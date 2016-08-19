//
//  Orientation.h
//  test
//
//  Created by Justin Moser on 6/18/14.
//  Copyright (c) 2014 Justin Moser. All rights reserved.
//

#import "Quaternion.h"

@interface Orientation : Quaternion

-(double)primaryYaw;   //degrees
-(double)primaryPitch; //degrees
-(double)secondaryYaw; //degrees

-(Quaternion *)qNormal;

-(double)angleFromNadirInRadians;



@end
