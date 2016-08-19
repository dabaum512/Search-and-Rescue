//
//  Header.h
//  SR1
//
//  Created by Justin Moser on 6/20/14.
//  Copyright (c) 2014 Justin Moser. All rights reserved.
//

typedef struct {
    double latitude1, longitude1;
    double latitude2, longitude2;
    double altitude, pitch, yaw;
    double horizontalDistance;
    double time, elevation;
}PostData;

//==========================================================

#define TIME_PROFILE 0

//----------------------------------------------------------

#define IMAGE_WIDTH 1280
#define IMAGE_HEIGHT 720

//----------------------------------------------------------

#define VERTICAL_FOV  35 //31.913458 //29.21625
#define HORIZONTAL_FOV 53.889999 //51.94

//----------------------------------------------------------

#define SHOW_VIDEO_FORMATS 0

//----------------------------------------------------------

#define save_image 0

//==========================================================



#if TIME_PROFILE == 1
static double totaltime = 0;
static long int n = 0;
static double start;
#define START_CLOCK start = clock();
#define END_CLOCK \
totaltime += (clock() - start) / CLOCKS_PER_SEC; \
n += 1; \
printf("%f\n",totaltime/n);
#else
#define START_CLOCK
#define END_CLOCK
#endif


// Geodetic Datum constants
#define wgs84_a (6378137.0)
#define wgs84_e (8.1819190842622e-2)
#define wgs84_e2 wgs84_e*wgs84_e
#define wgs84_ep2 wgs84_e2 / (1 - wgs84_e2)
#define wgs84_f 1 - sqrt(1 - wgs84_e2)
#define wgs84_b wgs84_a * (1 - wgs84_f)


// Camera Parameters
#define sensor_v_length 4.54
#define sensor_h_length 3.42
#define focal_length 4.1



