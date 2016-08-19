//
//  CameraView.m
//  S&R
//
//  Created by Justin Moser on 5/5/15.
//  Copyright (c) 2015 Justin Moser. All rights reserved.
//

#import "CameraView.h"

@implementation CameraView {
    AVCaptureVideoPreviewLayer *_captureLayer;
}

+(instancetype)cameraViewWithLayer:(AVCaptureVideoPreviewLayer *)layer {
    CameraView *view = [self new];
    view->_captureLayer = layer;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [view.layer addSublayer:layer];
    });
    return view;
}

-(void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    _captureLayer.frame = self.bounds;
}

@end
