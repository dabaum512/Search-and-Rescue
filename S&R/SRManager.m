//
//  SRManager.m
//  SR1
//
//  Created by Justin Moser on 6/20/14.
//  Copyright (c) 2014 Justin Moser. All rights reserved.
//

#import "SRManager.h"
#import "Analyzer.h"
#import "SpatialManager.h"
#import "POSTer.h"
#import "Elevation.h"

#include <sys/types.h>
#include <sys/sysctl.h>

#import "DataHandler.h"
#import <UIKit/UIImage.h>

typedef struct {
    double x,y,z;
} Vector3;

typedef struct {
    double m00,m01,m02;
    double m10,m11,m12;
    double m20,m21,m22;
} Matrix3x3;

static double iphone6focal[2] = {1125.26,1124.44};
static double iphone5focal[2] = {1385.39,1387.03};

static double fx = 0;
static double fy = 0;

@interface SRManager() <AVCaptureVideoDataOutputSampleBufferDelegate> {
    BOOL _switch;
}

@property (nonatomic, strong) AVCaptureDeviceInput *input;
@property (nonatomic, strong) AVCaptureVideoDataOutput *output;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *preview;
@property (nonatomic, strong) SpatialManager *spatialManager;

@property (nonatomic, strong) Analyzer *analyzer;

@property (nonatomic, strong) dispatch_queue_t dataQueue;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@property (nonatomic, strong) POSTer *poster;
@property (nonatomic, strong) Elevation *elevation;
@property (nonatomic, assign) double currentElevation;

@end

@implementation SRManager

-(instancetype)init {
    if (self = [super init]) {
        _shouldSlowProcessing = NO;
        _switch = NO;

        _sendData = NO;
        _searchForRed = NO;
        
        _currentElevation = -1;
        
        _spatialManager = [SpatialManager new];
        
        _captureQueue = dispatch_queue_create("com.capturemanager.sr1", DISPATCH_QUEUE_SERIAL);
        _dataQueue = dispatch_queue_create("com.capturedata.sr1", DISPATCH_QUEUE_SERIAL);
        _semaphore = dispatch_semaphore_create(1);
        
        _analyzer = [Analyzer new];
        
        [self setupElevation];
        
        [self setupVideoCamera];
        
        [self setupFocus];
        
    }
    return self;
}

- (NSString *)platform{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}


-(void)setupFocus {
    if ([[self platform]isEqualToString:@"iPhone5,1"]) {
        fx = iphone5focal[0];
        fy = iphone5focal[1];
    } else {
        fx = iphone6focal[0];
        fy = iphone6focal[1];
    }
}

-(void)setSendData:(BOOL)sendData {
    _sendData = sendData;
    if (sendData) {
        [DataHandler startNewRecording];
    } else {
        [DataHandler save:^{
//            NSLog(@"%@",[DataHandler allFiles]);
        }];
    }
}

-(void)startWithCallback:(void(^)(CGPoint))callback gpsBlock:(void(^)(PostData))gpsBlock {
    _callback = callback;
    _gpsBlock = gpsBlock;
    [_session startRunning];
}

//-(void)setupVideoCamera {
//    _session = [AVCaptureSession new];
//    _session.sessionPreset = AVCaptureSessionPresetInputPriority;
//    _backgroundRecordingID = UIBackgroundTaskInvalid;
//    
//    AVCaptureDevice *device = [SRManager deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
//    if (!device) {
//        return;
//    }
//    
//    NSError *error = nil;
//    if ([device lockForConfiguration:&error]) {
//        [device setFocusModeLockedWithLensPosition:1.0 completionHandler:nil];
//        [device unlockForConfiguration]; // apparently I can put this outside of the block
//    }
//
//    _input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
//    
//    if (error) {
//        NSLog(@"%@", error);
//    }
//    if ([_session canAddInput:_input]) {
//        [_session addInput:_input];
//    }
//    if (error){
//        NSLog(@"%@", error);
//    }
//    _output = [AVCaptureVideoDataOutput new];
//    NSLog(@"%@",_output.availableVideoCVPixelFormatTypes);
//    [self test];
//    _output.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
//    [_output setAlwaysDiscardsLateVideoFrames:YES];
//    [_output setSampleBufferDelegate:self queue:_captureQueue];
//    if ([_session canAddOutput:_output]) {
//        [_session addOutput:_output];
//        AVCaptureConnection *connection = [_output connectionWithMediaType:AVMediaTypeVideo];
//        if ([connection isVideoStabilizationSupported]) {
//            [connection setPreferredVideoStabilizationMode:AVCaptureVideoStabilizationModeOff];
//        }
//        if ([connection isVideoOrientationSupported]) {
//            AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationLandscapeRight;
//            [connection setVideoOrientation:orientation];
//        }
//    }
//    return;
//}

-(void)setupVideoCamera {
    _session = [AVCaptureSession new];
    _session.sessionPreset = AVCaptureSessionPresetInputPriority;
    
    AVCaptureDevice *device = [SRManager deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
    if (!device) {
        return;
    }
    NSError *error = nil;
    if ([device lockForConfiguration:&error]) {
        [device setFocusModeLockedWithLensPosition:1.0 completionHandler:nil];
        [device unlockForConfiguration];
    }
    _input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if ([_session canAddInput:_input]) {
        [_session addInput:_input];
    }
    _output = [AVCaptureVideoDataOutput new];
    _output.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)};
    [_output setAlwaysDiscardsLateVideoFrames:YES];
    [_output setSampleBufferDelegate:self queue:_captureQueue];
    if ([_session canAddOutput:_output]) {
        [_session addOutput:_output];
        AVCaptureConnection *connection = [_output connectionWithMediaType:AVMediaTypeVideo];
        if ([connection isVideoStabilizationSupported]) {
            [connection setPreferredVideoStabilizationMode:AVCaptureVideoStabilizationModeOff];
        }
        if ([connection isVideoOrientationSupported]) {
            AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationLandscapeRight;
            [connection setVideoOrientation:orientation];
        }
    }
    return;
}


-(void)test {
    
    NSDictionary *dict = @{@"kCVPixelFormatType_1Monochrome":@(kCVPixelFormatType_1Monochrome),
                          @"kCVPixelFormatType_2Indexed":@(kCVPixelFormatType_2Indexed),
                          @"kCVPixelFormatType_4Indexed":@(kCVPixelFormatType_4Indexed),
                           @"kCVPixelFormatType_8Indexed":@(kCVPixelFormatType_8Indexed),
                           @"kCVPixelFormatType_1IndexedGray_WhiteIsZero":@(kCVPixelFormatType_1IndexedGray_WhiteIsZero),
                           @"kCVPixelFormatType_2IndexedGray_WhiteIsZero":@(kCVPixelFormatType_2IndexedGray_WhiteIsZero),
                           @"kCVPixelFormatType_4IndexedGray_WhiteIsZero":@(kCVPixelFormatType_4IndexedGray_WhiteIsZero),
                           @"kCVPixelFormatType_8IndexedGray_WhiteIsZero":@(kCVPixelFormatType_8IndexedGray_WhiteIsZero),
                           @"kCVPixelFormatType_16BE555":@(kCVPixelFormatType_16BE555),
                           @"kCVPixelFormatType_16LE555":@(kCVPixelFormatType_16LE555),
                           @"kCVPixelFormatType_16LE5551":@(kCVPixelFormatType_16LE5551),
                           @"kCVPixelFormatType_16BE565":@(kCVPixelFormatType_16BE565),
                           @"kCVPixelFormatType_16LE565":@(kCVPixelFormatType_16LE565),
                           @"kCVPixelFormatType_24RGB":@(kCVPixelFormatType_24RGB),
                           @"kCVPixelFormatType_24BGR":@(kCVPixelFormatType_24BGR),
                           @"kCVPixelFormatType_32ARGB":@(kCVPixelFormatType_32ARGB),
                           @"kCVPixelFormatType_32BGRA":@(kCVPixelFormatType_32BGRA),
                           @"kCVPixelFormatType_32ABGR":@(kCVPixelFormatType_32ABGR),
                           @"kCVPixelFormatType_32RGBA":@(kCVPixelFormatType_32RGBA),
                           @"kCVPixelFormatType_64ARGB":@(kCVPixelFormatType_64ARGB),
                           @"kCVPixelFormatType_48RGB":@(kCVPixelFormatType_48RGB),
                           @"kCVPixelFormatType_32AlphaGray":@(kCVPixelFormatType_32AlphaGray),
                           @"kCVPixelFormatType_16Gray":@(kCVPixelFormatType_16Gray),
                           @"kCVPixelFormatType_30RGB":@(kCVPixelFormatType_30RGB),
                           @"kCVPixelFormatType_422YpCbCr8":@(kCVPixelFormatType_422YpCbCr8),
                           @"kCVPixelFormatType_4444YpCbCrA8":@(kCVPixelFormatType_4444YpCbCrA8),
                           @"kCVPixelFormatType_4444YpCbCrA8R":@(kCVPixelFormatType_4444YpCbCrA8R),
                           @"kCVPixelFormatType_4444AYpCbCr8":@(kCVPixelFormatType_4444AYpCbCr8),
                           @"kCVPixelFormatType_4444AYpCbCr16":@(kCVPixelFormatType_4444AYpCbCr16),
                           @"kCVPixelFormatType_444YpCbCr8":@(kCVPixelFormatType_444YpCbCr8),
                           @"kCVPixelFormatType_422YpCbCr16":@(kCVPixelFormatType_422YpCbCr16),
                           @"kCVPixelFormatType_422YpCbCr10":@(kCVPixelFormatType_422YpCbCr10),
                           @"kCVPixelFormatType_444YpCbCr10":@(kCVPixelFormatType_444YpCbCr10),
                           @"kCVPixelFormatType_420YpCbCr8Planar":@(kCVPixelFormatType_420YpCbCr8Planar),
                           @"kCVPixelFormatType_420YpCbCr8PlanarFullRange":@(kCVPixelFormatType_420YpCbCr8PlanarFullRange),
                           @"kCVPixelFormatType_422YpCbCr_4A_8BiPlanar":@(kCVPixelFormatType_422YpCbCr_4A_8BiPlanar),
                           @"kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange":@(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange),
                           @"kCVPixelFormatType_420YpCbCr8BiPlanarFullRange":@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange),
                           @"kCVPixelFormatType_422YpCbCr8_yuvs":@(kCVPixelFormatType_422YpCbCr8_yuvs),
                           @"kCVPixelFormatType_422YpCbCr8FullRange":@(kCVPixelFormatType_422YpCbCr8FullRange),
                           @"kCVPixelFormatType_OneComponent8":@(kCVPixelFormatType_OneComponent8),
                           @"kCVPixelFormatType_TwoComponent8":@(kCVPixelFormatType_TwoComponent8),
                           @"kCVPixelFormatType_OneComponent16Half":@(kCVPixelFormatType_OneComponent16Half),
                           @"kCVPixelFormatType_OneComponent32Float":@(kCVPixelFormatType_OneComponent32Float),
                           @"kCVPixelFormatType_TwoComponent16Half":@(kCVPixelFormatType_TwoComponent16Half),
                           @"kCVPixelFormatType_TwoComponent32Float":@(kCVPixelFormatType_TwoComponent32Float),
                           @"kCVPixelFormatType_64RGBAHalf":@(kCVPixelFormatType_64RGBAHalf),
                           @"kCVPixelFormatType_128RGBAFloat":@(kCVPixelFormatType_128RGBAFloat)};
    
    NSLog(@"%@",dict);
}

-(void)setupElevation {
    SpatialData data = [self.spatialManager getSpatialData];
    Location location;
    location.latitude = data.latitude;
    location.longitude = data.longitude;
    self.elevation = [Elevation getElevationForLocation:location andCallback:^(double elevation, NSDate *date){
        self.currentElevation = elevation;
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [NSTimer scheduledTimerWithTimeInterval:4.0 target:self selector:@selector(elevation:) userInfo:nil repeats:YES];
    });
}

-(void)elevation:(NSTimer *)timer {
    
    _elevation = nil;
    
    SpatialData data = [_spatialManager getSpatialData];
    Location location;
    location.latitude = data.latitude;
    location.longitude = data.longitude;
    
    self.elevation = [Elevation getElevationForLocation:location andCallback:^(double elevation, NSDate *date){
        self.currentElevation = elevation;
    }];
}

-(void)pauseWithBlock:(void (^)(UIImage *))block {
    dispatch_async(_captureQueue, ^{
        _shouldPause = YES;
        _imageBlock = block;
    });
}

-(void)unpauseWithBlock:(void (^)())block {
    dispatch_async(_captureQueue, ^{
        _shouldPause = NO;
        [_session startRunning];
        if (block) {
            block();
        }
    });
}

//static double _time = 0;

//-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
//    
////    printf("%f\n",1 / (CACurrentMediaTime() - _time));
////    _time = CACurrentMediaTime();
//    
//    if (_shouldPause) {
//        [_session stopRunning];
//        if (_imageBlock) {
//            _imageBlock([self imageFromSampleBuffer:sampleBuffer]);
//        }
//    }
//    
//    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//    CVPixelBufferLockBaseAddress(imageBuffer, 0);
//    unsigned char *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
//    size_t cols = CVPixelBufferGetWidth(imageBuffer);
//    size_t rows = CVPixelBufferGetHeight(imageBuffer);
//    
//    
//    START_CLOCK
//    CGPoint point;
//    
//    if (_searchForRed) {
//        point = [self.analyzer vectorRedSpotFromBuffer:baseAddress rows:rows coloumns:cols];
//    } else {
//        //            point = [self.analyzer vectorBrightSpotFromBuffer:baseAddress rows:rows coloumns:cols];
//        point = brightSpotFromBuffer(baseAddress, rows, cols);
//        
//    }
//
//    END_CLOCK
//   
//    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
//    
//    if (self.callback) {
//        self.callback(point);
//    }
//    
//    Quaternion *quaternion = [self.spatialManager currentOrientation];
//    
//    if (!quaternion) {
//        return;
//    }
//    
//    SpatialData spatialData = [self.spatialManager getSpatialData];
//    
//    NSDate *date = [NSDate date];
//    
//    if (point.x >= 0.001 && point.y >= 0.001 ) {
//        dispatch_async(self.dataQueue,^{
//            [self finalWithDate:date quaternion:quaternion spatialData:spatialData brightSpotPoint:point];
//        });
//    }
//}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    if (_shouldPause) {
        [_session stopRunning];
        if (_imageBlock) {
            _imageBlock([self imageFromSampleBuffer:sampleBuffer]);
        }
    }
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
    unsigned char *baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    size_t cols = CVPixelBufferGetWidth(imageBuffer);
    size_t rows = CVPixelBufferGetHeight(imageBuffer);
    
//    CFTimeInterval time = CACurrentMediaTime();
    
    CGPoint point = brightSpotFromLuma(baseAddress, rows, cols);
    
//    printf("%.5f\n",CACurrentMediaTime() - time);
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
    
    if (self.callback) {
        self.callback(point);
    }
    
    Quaternion *quaternion = [self.spatialManager currentOrientation];
    
    if (!quaternion) {
        return;
    }
    
    SpatialData spatialData = [self.spatialManager getSpatialData];
    
    NSDate *date = [NSDate date];
    
    if (point.x >= 0.001 && point.y >= 0.001 ) {
        dispatch_async(self.dataQueue,^{
            [self finalWithDate:date quaternion:quaternion spatialData:spatialData brightSpotPoint:point];
        });
    }
}

-(void)finalWithDate:(NSDate *)date quaternion:(Quaternion *)quaternion spatialData:(SpatialData)spatialData brightSpotPoint:(CGPoint)point {
    
    double b = -(1280 * point.x - 640);
    double a = -(720 * point.y - 360);
    
    double x = a / fy;
    double y = b / fx;
    
    Quaternion *normal = [Quaternion quaternionWithValues:0.0 x:x y:y z:-1];
    Quaternion *v3 = [[quaternion qMultiply:normal]qMultiply:[quaternion qInverse]];
    
    if (v3.z > 0) {
        return;
    }
  
    double yaw = [[Vector vectorWithValuesX:v3.x y:v3.y z:0.0] angleInbetween:[Vector vectorWithValuesX:1.0 y:0.0 z:0.0]]* Rad_To_Deg;
    
    if (yaw != yaw) {
        return;
    }
    
    if (v3.y > 0.0) {
        yaw = 360 - yaw;
    }
    
    double pitch = acos(-v3.z) * Rad_To_Deg;
    
    if (pitch != pitch) {
        pitch = 0;
    }
    
    PostData postData;
    postData.yaw = yaw;
    postData.pitch = pitch;
    postData.latitude1 = spatialData.latitude;
    postData.longitude1 = spatialData.longitude;
    postData.altitude = spatialData.altitude;
    postData.time = [date timeIntervalSinceReferenceDate];
    postData.elevation = self.currentElevation;
    double lat2,long2,dist;
    [self findLocation:postData latitude2:&lat2 longitude2:&long2 distance:&dist];
    postData.horizontalDistance = dist;
    postData.latitude2 = lat2;
    postData.longitude2 = long2;
    
    if (self.gpsBlock) {
        self.gpsBlock(postData);
    }
    
    if (_sendData) {
//        [self.poster handlePostData:postData];
        [DataHandler handleData:postData];
    }
}

#pragma mark - Geodetic and ECEF Methods

-(void)findLocation:(PostData)data latitude2:(double *)lat2 longitude2:(double *)long2 distance:(double *)dist {
    
    double t = (data.altitude - data.elevation) * tan(data.pitch * Deg_To_Rad);
    double e = t * sin(data.yaw * Deg_To_Rad);
    double n = t * cos(data.yaw * Deg_To_Rad);
    double u = data.elevation - data.altitude;
    
    *dist = t;
    
    if (e != e || n != n) {
        return;
    }
    
    Matrix3x3 matrix = [self enuToECEFgetMatrixFromLatitude:data.latitude1 longitude:data.longitude1];
    
    Vector3 v = multiply(matrix,e,n,u);
    
    double x1,y1,z1,x2,y2,z2,height;
    
    [self convertLat:data.latitude1 longitude:data.longitude1 altitude:data.altitude toECEFwithX:&x1 y:&y1 z:&z1];
    
    x2 = x1 + v.x;
    y2 = y1 + v.y;
    z2 = z1 + v.z;

    [self convertX:x2 y:y2 z:z2 toLatitude:lat2 longitude:long2 height:&height];
}

Vector3 multiply(Matrix3x3 m, double x, double y, double z) {
    Vector3 v;
    v.x = m.m00 * x + m.m01 * y + m.m02 * z;
    v.y = m.m10 * x + m.m11 * y + m.m12 * z;
    v.z = m.m20 * x + m.m21 * y + m.m22 * z;
    return v;
}

-(Matrix3x3)enuToECEFgetMatrixFromLatitude:(double)latitude longitude:(double)longitude {
    
    Matrix3x3 matrix;
    double lat = latitude;
    double lon = longitude;
    
    lat *= Deg_To_Rad;
    lon *= Deg_To_Rad;
    
    matrix.m00 = - sin(lon);
    matrix.m01 = -sin(lat)*cos(lon);
    matrix.m02 = cos(lat)*cos(lon);
    
    matrix.m10 = cos(lon);
    matrix.m11 = - sin(lat)*sin(lon);
    matrix.m12 = cos(lat)*sin(lon);
    
    matrix.m20 = 0;
    matrix.m21 = cos(lat);
    matrix.m22 = sin(lat);
    
    return matrix;
}

-(void)convertX:(double)x y:(double)y z:(double)z toLatitude:(double *)lat longitude:(double *)lon height:(double *)h {
 
    double p = hypot(x, y);
    *lat = atan2(z, p * (1 - wgs84_e2));
    *lon = atan2(y, x);
    double v = wgs84_a / sqrt(1 - wgs84_e2 * sin(*lat) * sin(*lat));
    
    for (int i = 0; i < 3; ++i) {
        *lat = atan2(z + wgs84_e2 * v * sin(*lat), p);
        v = wgs84_a / sqrt(1 - wgs84_e2 * sin(*lat) * sin(*lat));
    }
    *h = p / cos(*lat) - v;
    *lat *= Rad_To_Deg;
    *lon *= Rad_To_Deg;
}

-(void)convertLat:(double)lat longitude:(double)lon altitude:(double)altitude toECEFwithX:(double *)x y:(double *)y z:(double *)z {
    
    double clat = cos(lat * Deg_To_Rad);
    double slat = sin(lat * Deg_To_Rad);
    double clon = cos(lon * Deg_To_Rad);
    double slon = sin(lon * Deg_To_Rad);
    
    double N = wgs84_a / sqrt(1.0 - wgs84_e2 * slat * slat);
    *x = (N + altitude) * clat * clon;
    *y = (N + altitude) * clat * slon;
    *z = (N * (1.0 - wgs84_e2) + altitude) * slat;
}

#pragma mark - ECEF and ENU Methods

//void ecefToEnu(double lat, double lon, double x, double y, double z, double xr, double yr, double zr, double *e, double *n, double *u)
//{
//    double clat = cos(lat * Deg_To_Rad);
//    double slat = sin(lat * Deg_To_Rad);
//    double clon = cos(lon * Deg_To_Rad);
//    double slon = sin(lon * Deg_To_Rad);
//    
//    double dx = x - xr;
//    double dy = y - yr;
//    double dz = z - zr;
//    
//    *e = -slon*dx  + clon*dy;
//    *n = -slat*clon*dx - slat*slon*dy + clat*dz;
//    *u = clat*clon*dx + clat*slon*dy + slat*dz;
//}

#pragma mark - Initializing Methods

-(Analyzer *)analyzer {
    if (_analyzer) {
        return _analyzer;
    }
    _analyzer = [Analyzer new];
    return _analyzer;
}

-(POSTer *)poster {
    if (_poster) {
        return _poster;
    }
    _poster = [POSTer new];
    return _poster;
}

+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position {
    for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:mediaType]) {
        if (device.position == position) {
            NSError *error = nil;
            if ([device lockForConfiguration:&error]) {
                for (AVCaptureDeviceFormat *format in [device formats]) {
                    AVFrameRateRange *range = format.videoSupportedFrameRateRanges.firstObject;
                    if (range.maxFrameRate == 60) {
                        FourCharCode code = CMFormatDescriptionGetMediaSubType(format.formatDescription);
                        uint32_t valSwapped = CFSwapInt32HostToBig(code);
                        NSString *str = [NSString stringWithFormat:@"%.4s", (char *)&valSwapped];
                        if ([str isEqualToString:@"420f"]) {
                            [device setActiveFormat:format];
                            [device setActiveVideoMaxFrameDuration:range.maxFrameDuration];
                            [device setActiveVideoMinFrameDuration:range.maxFrameDuration];
                        }
                    }
                }
                [device unlockForConfiguration];
            }
            return device;
        }
    }
    return nil;
}

#pragma mark - Setters

-(void)setSearchForRed:(BOOL)searchForRed {
    _searchForRed = searchForRed;
}

-(void)setServerAddress:(NSString *)serverAddress {
    _serverAddress = serverAddress;
    dispatch_async(self.dataQueue, ^{
        self.poster.serverAddress = serverAddress;
    });
}

#pragma mark - Image Block

-(UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
    CGContextRelease(newContext);
    
    CGColorSpaceRelease(colorSpace);
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    return [UIImage imageWithCGImage:newImage];
}

@end



