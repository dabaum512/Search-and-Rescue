//
//  SRManager.h
//  SR1
//
//  Created by Justin Moser on 6/20/14.
//  Copyright (c) 2014 Justin Moser. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "Header.h"

@interface SRManager : NSObject {
    BOOL _sendData;
    BOOL _searchForRed;
}

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) dispatch_queue_t captureQueue;

@property (nonatomic, assign) BOOL sendData;
@property (nonatomic, assign) BOOL searchForRed;
@property (nonatomic, assign) BOOL shouldSlowProcessing;
@property (nonatomic, strong) NSString *serverAddress;
@property (nonatomic, assign) BOOL shouldPause;

@property (nonatomic, copy) void(^imageBlock)(UIImage *);
@property (nonatomic, copy) void(^callback)(CGPoint);
@property (nonatomic, copy) void(^gpsBlock)(PostData);

-(void)startWithCallback:(void(^)(CGPoint))callback gpsBlock:(void(^)(PostData))gpsBlock;

-(void)pauseWithBlock:(void(^)(UIImage *image))block;
-(void)unpauseWithBlock:(void(^)())block;

@end
