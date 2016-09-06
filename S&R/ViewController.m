//
//  ViewController.m
//  S&R
//
//  Created by Justin Moser on 5/5/15.
//  Copyright (c) 2015 Justin Moser. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "ViewController.h"
#import "Header.h"
#import "SRManager.h"
#import "SettingsViewController.h"
#import "Setting.h"
#import "LocatorLayer.h"
#import "UIImage+ImageEffects.h"
#import "CameraView.h"
#import "UIImage+Category.h"

#import "UploadView.h"

// -----------------------------------------------------------------------------
//                           --- UI Macros ---

#define LOCATOR_DIAMETER 16.0f

#define LABEL_LEFT_PAD 10.0f
#define LABEL_HEIGHT 20.0f
#define LABEL_WIDTH 200.0f
#define LABEL_SEPARATION 5.0f
#define LABEL_TRANSLATION 25.0f

#define INFO_SIZE 18.0f
#define INFO_RIGHT_PAD 8.0f
#define INFO_TOP_PAD 8.0f

//
//------------------------------------------------------------------------------


@interface ViewController () <UIGestureRecognizerDelegate,UIAlertViewDelegate>

@property (nonatomic, strong) id settingsManager;

@property (nonatomic, assign) BOOL displayYawAndPitch;
@property (nonatomic, assign) BOOL displayLatAndLong;
@property (nonatomic, assign) BOOL hideInfoButton;
@property (nonatomic,strong) SRManager *manager;

@property (nonatomic, strong) UIView *cameraView;
@property (nonatomic, strong) UIView *locatorView;
@property (nonatomic, strong) MKMapView *mapView;

@property (nonatomic, strong) UIView *floatingView;
@property (nonatomic, strong) UILabel *yawLabel;
@property (nonatomic, strong) UILabel *pitchLabel;
@property (nonatomic, strong) UILabel *latitudeLabel;
@property (nonatomic, strong) UILabel *longitudeLabel;
@property (nonatomic, strong) UIButton *infoButton;

@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchGesture;

@property (nonatomic, assign) BOOL mapIsVisible;
@property (nonatomic, assign) double zoom;

@property (nonatomic, strong) NSLayoutConstraint *labelConstraint;

@property (nonatomic, strong) UIView *dimView;
@property (nonatomic, strong) UIImageView *pauseImageView;

@property (nonatomic, strong) LocatorLayer *locatorLayer;

@property (nonatomic, strong) UIButton *openButton;

@end

@implementation ViewController

#pragma mark - View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    if (![CLLocationManager locationServicesEnabled]) {
        [self showLocationsServicesAlert];
        return;
    }
    
    self.mapIsVisible = NO;
    
    [self registerForPanelChanges];
    
    self.manager = [SRManager new];
    
    [self setupPreviewLayer];
    [self setupLocatorView];
//    [self setupMap];
    [self setupGestureRecognizers];
    [self setupOverLayView];
    [self setupPauseAndBlurView];
    [self setupSettings];
    
    _openButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
    _openButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_openButton];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_openButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:-10.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_openButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-10.0]];
    
    [_openButton addTarget:self action:@selector(open:) forControlEvents:UIControlEventTouchUpInside];
    
    [self startSearch];
    
}

-(void)open:(id)control {
    [self displayUploader];
}

-(void)displayUploader {
    [self pause];
    
    UploadView *view = [UploadView new];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:view];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(view)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(view)]];
}

-(void)showLocationsServicesAlert {
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Location Issue" message:@"Location Services are disabled." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [alert show];
    });
}


#pragma mark - Preview View Setup

-(void)setupPreviewLayer {
    _cameraView = [[UIView alloc]initWithFrame:self.view.bounds];
    _cameraView.translatesAutoresizingMaskIntoConstraints = YES;
    _cameraView.frame = self.view.bounds;
    _cameraView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:_cameraView];
    
    AVCaptureSession *captureSession = _manager.session;
    AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
    previewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    previewLayer.frame = _cameraView.bounds;
    previewLayer.bounds = _cameraView.bounds;
    [_cameraView.layer addSublayer:previewLayer];
}


#pragma mark - Locator View Setup

-(void)setupLocatorView {
    _locatorLayer = [LocatorLayer new];
    _locatorLayer.fill = [[UIColor greenColor]colorWithAlphaComponent:0.75];
    _locatorLayer.trim = [UIColor grayColor];
    _locatorLayer.opacity = 1.0;
    _locatorLayer.anchorPoint = CGPointMake(0.5, 0.5);
    _locatorLayer.frame = CGRectMake(0, 0, LOCATOR_DIAMETER, LOCATOR_DIAMETER);
    _locatorLayer.contentsScale = [[UIScreen mainScreen]scale];
    [_cameraView.layer addSublayer:_locatorLayer];
    
    [_locatorLayer setNeedsDisplay];
}

#pragma mark - Overlay View Setup

-(void)setupOverLayView {
    
    _floatingView = [UIView new];
    [_floatingView setTranslatesAutoresizingMaskIntoConstraints:YES];
    [_floatingView setFrame:self.view.bounds];
    [_floatingView setAlpha:1.0];
    _floatingView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_floatingView];
    
    _yawLabel = [self createLabelWithParalax:YES addToView:_floatingView];
    _pitchLabel = [self createLabelWithParalax:YES addToView:_floatingView];
    _latitudeLabel = [self createLabelWithParalax:YES addToView:_floatingView];
    _longitudeLabel = [self createLabelWithParalax:YES addToView:_floatingView];
    
    _labelConstraint = [NSLayoutConstraint constraintWithItem:_longitudeLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_floatingView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-10.0];
    
    [_floatingView addConstraint:_labelConstraint];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_yawLabel,_pitchLabel,_latitudeLabel,_longitudeLabel);
    
    [_floatingView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-(%f)-[_yawLabel(%f)]",LABEL_LEFT_PAD,LABEL_WIDTH] options:0 metrics:nil views:views]];
    
    [_floatingView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-(%f)-[_pitchLabel(%f)]",LABEL_LEFT_PAD,LABEL_WIDTH] options:0 metrics:nil views:views]];
    
    [_floatingView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-(%f)-[_latitudeLabel(%f)]",LABEL_LEFT_PAD,LABEL_WIDTH] options:0 metrics:nil views:views]];
    
    [_floatingView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-(%f)-[_longitudeLabel(%f)]",LABEL_LEFT_PAD,LABEL_WIDTH] options:0 metrics:nil views:views]];
    
    [_floatingView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[_yawLabel(%f)]-(%f)-[_pitchLabel(%f)]-(%f)-[_latitudeLabel(%f)]-(%f)-[_longitudeLabel(%f)]",LABEL_HEIGHT,LABEL_SEPARATION,LABEL_HEIGHT,LABEL_SEPARATION,LABEL_HEIGHT,LABEL_SEPARATION,LABEL_HEIGHT] options:0 metrics:nil views:views]];
    
    CGRect infoButtonFrame = CGRectMake(self.view.bounds.size.width - (INFO_SIZE + INFO_RIGHT_PAD),
                                        INFO_TOP_PAD, INFO_SIZE, INFO_SIZE);
    
    _infoButton = [self createInfoButtonWithFrame:infoButtonFrame addToView:self.floatingView withParalax:YES];
}

-(UIButton *)createInfoButtonWithFrame:(CGRect)frame addToView:(UIView *)view withParalax:(BOOL)paralax {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeInfoDark];
    [button setFrame:frame];
    button.backgroundColor = [UIColor clearColor];
    [button addTarget:self action:@selector(infoButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    if (paralax) {
        [self addParalaxToView:button];
    }
    if (view) {
        [view addSubview:button];
    }
    return button;
}

-(UILabel *)createLabelWithParalax:(BOOL)paralax addToView:(UIView *)view {
    UILabel *label = [UILabel new];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = [UIFont systemFontOfSize:12.0];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentLeft;
    label.backgroundColor = [UIColor clearColor];
    label.text = @"";
    label.alpha = 0.0;
    if (paralax) {
        [self addParalaxToView:label];
    }
    if (view) {
        [view addSubview:label];
    }
    return label;
}

-(void)addParalaxToView:(UIView *)view {
    UIInterpolatingMotionEffect *horizontalMotionEffect = [[UIInterpolatingMotionEffect alloc]initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    horizontalMotionEffect.minimumRelativeValue = @(-5);
    horizontalMotionEffect.maximumRelativeValue = @(5);
    [view addMotionEffect:horizontalMotionEffect];
}

#pragma mark - Map View Setup

-(void)setupMap {
    self.zoom = 14.0;
    self.mapView = [MKMapView new];
    
    self.mapView.userInteractionEnabled = NO;
    self.mapView.alpha = 0.0;
    
    [self.view addSubview:self.mapView];
}

#pragma mark - Gesture Recognizers

-(void)setupGestureRecognizers {
    self.tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTapGesture:)];
    self.tapGesture.numberOfTapsRequired = 2;
    self.tapGesture.numberOfTouchesRequired = 1;
    [self.tapGesture setEnabled:YES];
    [self.view addGestureRecognizer:self.tapGesture];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

-(void)handleTapGesture:(UITapGestureRecognizer *)tgr {
    if (!self.mapIsVisible) {
        self.manager.shouldSlowProcessing = YES;
        _locatorLayer.opacity = 0.0;
        [UIView animateWithDuration:0.25 animations:^{
            self.labelConstraint.constant -= LABEL_TRANSLATION;
            self.mapView.alpha = 1.0;
            [self.floatingView layoutIfNeeded];
        }completion:^(BOOL finished) {
            self.mapIsVisible = YES;
        }];
        [self.pinchGesture setEnabled:YES];
    } else {
        self.manager.shouldSlowProcessing = NO;
        self.mapIsVisible = NO;
        [UIView animateWithDuration:0.25 animations:^{
            self.labelConstraint.constant += LABEL_TRANSLATION;
            self.mapView.alpha = 0.0;
            [self.floatingView layoutIfNeeded];
        } completion:^(BOOL finished) {
            _locatorLayer.opacity = 0.0;
        }];
        [self.pinchGesture setEnabled:NO];
    }
}

#pragma mark - Start Search

-(void)startSearch {
    
    void(^mapBlock)(PostData) = ^(PostData data) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_displayYawAndPitch) {
                _yawLabel.text = [NSString stringWithFormat:@"Yaw: %3.2f°",data.yaw];
                _pitchLabel.text = [NSString stringWithFormat:@"Pitch: %3.2f°",data.pitch];
            }
            if (_displayLatAndLong) {
                _latitudeLabel.text = [NSString stringWithFormat:@"Latitude: %3.8f°",data.latitude2];
                _longitudeLabel.text = [NSString stringWithFormat:@"Longitude: %3.8f°",data.longitude2];
            }
        });
        if (self.mapIsVisible) {
            dispatch_async(dispatch_get_main_queue(), ^{
                CLLocationCoordinate2D c = CLLocationCoordinate2DMake(data.latitude1, data.longitude1);
                
                MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(c, 100, 100);
                
                [self.mapView setRegion:region animated:YES];
            });
        }
    };
    
    [_manager startWithCallback:nil gpsBlock:mapBlock];
    [self resetLocatorBlock];
}

-(void)resetLocatorBlock {
    void(^locatorBlock)(CGPoint) = ^(CGPoint point) {
        if (!self.mapIsVisible) {
            dispatch_async(dispatch_get_main_queue(), ^{
                CGRect imageBounds = _cameraView.frame;
                if (point.x >= 0 && point.y >= 0) {
                    
                    if (_locatorLayer.opacity != 1.0) {
                        _locatorLayer.opacity = 1.0;
                        [self animate:_locatorLayer path:@"opacity" to:@(1.0) from:@(0.0) duration:0.4];
                    }
                    
                    CGPoint p = CGPointMake(imageBounds.origin.x + point.x * imageBounds.size.width,
                                            imageBounds.origin.y + point.y * imageBounds.size.height);
                    
                    _locatorLayer.position = p;
                    
                } else {
                    if (_locatorLayer.opacity != 0.0) {
                        _locatorLayer.opacity = 0.0;
                        [self animate:_locatorLayer path:@"opacity" to:@(0.0) from:@(1.0) duration:0.4];
                    }
                }
            });
        }
    };
    _manager.callback = locatorBlock;
}


#pragma mark - Info

-(void)infoButtonPressed:(id)sender {
    
    [self pause];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Basic Info" message:@"Double tap to switch between the camera view and the map view.\nSwipe to the left to acess the settings.\nPinch the map to zoom.\nIt is normal for your device to rise in temperature during use." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        alert.delegate = self;
        alert.tag = 101;
        [alert show];
    });
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 101) {
        [self unpause];
    }
}

#pragma mark - Notification

-(void)registerForPanelChanges {
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(panelChangeNotification:) name:@"VisiblePanelChange" object:nil];
}

#pragma mark - Transition Effects

-(void)setupPauseAndBlurView {
    _pauseImageView = [UIImageView new];
    _pauseImageView.translatesAutoresizingMaskIntoConstraints = NO;
    _pauseImageView.alpha = 0.0;
    _pauseImageView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_pauseImageView];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_pauseImageView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_pauseImageView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_pauseImageView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_pauseImageView)]];
    
    
    _dimView = [UIView new];
    _dimView.translatesAutoresizingMaskIntoConstraints = NO;
    _dimView.backgroundColor = [UIColor blackColor];
    _dimView.alpha = 0.0;
    [self.view addSubview:_dimView];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_dimView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_dimView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_dimView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_dimView)]];
    
}

-(void)pause {
    
    _manager.callback = nil;
    
    [UIView animateWithDuration:0.5 animations:^{
        self.dimView.alpha = 0.1;
    }];
    
    _locatorLayer.opacity = 0.0;
    [self animate:_locatorLayer path:@"opacity" to:@(0.0) from:@(1.0) duration:0.4];
    
    [_manager pauseWithBlock:^(UIImage *image) {
        UIColor *tint = [UIColor colorWithWhite:0.5 alpha:0.2];
        image = [image blurredImageWithRadius:20 iterations:10 tintColor:tint];
        dispatch_async(dispatch_get_main_queue(), ^{
            _pauseImageView.image = image;
            _pauseImageView.alpha = 0.0;
            [_pauseImageView setHidden:NO];
            [UIView animateWithDuration:0.8 animations:^{
                _pauseImageView.alpha = 1.0;
            }];
        });
    }];
}

-(void)unpause {
    [_manager unpauseWithBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.5 animations:^{
                _pauseImageView.alpha = 0.0;
            } completion:^(BOOL finished) {
                _pauseImageView.image = nil;
                [self resetLocatorBlock];
            }];
        });
    }];
    
    [UIView animateWithDuration:0.5 animations:^{
        _dimView.alpha = 0.0;
    }];
}

-(void)panelChangeNotification:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[SettingsViewController class]]) {
        [self pause];
    } else if ([notification.object isKindOfClass:[ViewController class]]) {
        [self unpause];
    }
}

-(void)animate:(CALayer *)layer path:(NSString *)path to:(id)to from:(id)from duration:(CFTimeInterval)duration {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:path];
    animation.toValue = to;
    animation.fromValue = from;
    animation.duration = duration;
    [layer addAnimation:animation forKey:path];
}

#pragma mark - Settings

-(void)setupSettings {
    
    //    if (!self.settingsManager) {
    //        return;
    //    }
    //
    //    NSMutableDictionary *dict = [NSMutableDictionary new];
    //    NSError *error = nil;
    //
    //    Setting *sendDataSetting = [Setting settingWithName:@"sendData" description:@"Send Data To Server" defaultValue:@NO type:SettingTypeBOOL block:^(id value) {
    //        self.manager.sendData = [value boolValue];
    //    }];
    //
    //    Setting *serverAddressSetting = [Setting settingWithName:@"serverAddress" description:@"Server Address" defaultValue:@"" type:SettingTypeString block:^(id value) {
    //        self.manager.serverAddress = value;
    //    }];
    //
    //    if (![dict addSectionWithSettings:@[sendDataSetting,serverAddressSetting] withDescription:@"Send JSON  Transfer" error:&error]) {
    //        NSLog(@"%@",[error valueForKey:@"description"]);
    //        abort();
    //    }
    //
    //    Setting *searchForRedSetting = [Setting settingWithName:@"searchForRed" description:@"Search White or Red" defaultValue:@NO type:SettingTypeBOOL block:^(id value) {
    //        self.manager.searchForRed = [value boolValue];
    //    }];
    //
    //    if (![dict addSectionWithSettings:@[searchForRedSetting] withDescription:@"Image Analysis" error:&error]) {
    //        NSLog(@"%@",[error valueForKey:@"description"]);
    //        abort();
    //    }
    //
    //    Setting *yawPitchSetting = [Setting settingWithName:@"displayYawAndPitch" description:@"Display Yaw and Pitch" defaultValue:@NO type:SettingTypeBOOL block:^(id value) {
    //        _displayYawAndPitch = [value boolValue];
    //        if ([value boolValue]) {
    //            self.yawLabel.text = @"Yaw:";
    //            self.pitchLabel.text = @"Pitch:";
    //            [UIView animateWithDuration:0.25 animations:^{
    //                self.yawLabel.alpha = 1.0;
    //                self.pitchLabel.alpha = 1.0;
    //            }];
    //        } else {
    //            [UIView animateWithDuration:0.25 animations:^{
    //                self.yawLabel.alpha = 0.0;
    //                self.pitchLabel.alpha = 0.0;
    //            }];
    //        }
    //    }];
    //
    //    Setting *latLongSetting = [Setting settingWithName:@"displayLatAndLong" description:@"Display Approx. GPS Coordinates" defaultValue:@NO type:SettingTypeBOOL block:^(id value) {
    //        _displayLatAndLong = [value boolValue];
    //        if ([value boolValue]) {
    //            self.latitudeLabel.text = @"Latitude:";
    //            self.longitudeLabel.text = @"Longitude:";
    //            [UIView animateWithDuration:0.25 animations:^{
    //                self.latitudeLabel.alpha = 1.0;
    //                self.longitudeLabel.alpha = 1.0;
    //            }];
    //        } else {
    //            [UIView animateWithDuration:0.25 animations:^{
    //                self.latitudeLabel.alpha = 0.0;
    //                self.longitudeLabel.alpha = 0.0;
    //            }];
    //        }
    //    }];
    //
    //    Setting *hideInfoSetting = [Setting settingWithName:@"hideInfoButton" description:@"Hide Info Button" defaultValue:@NO type:SettingTypeBOOL block:^(id value) {
    //        _hideInfoButton = [value boolValue];
    //        if (![value boolValue]) {
    //            self.infoButton.enabled = YES;
    //            [UIView animateWithDuration:0.25 animations:^{
    //                self.infoButton.alpha = 1.0;
    //            }];
    //        } else {
    //            self.infoButton.enabled = NO;
    //            [UIView animateWithDuration:0.25 animations:^{
    //                self.infoButton.alpha = 0.0;
    //            }];
    //        }
    //    }];
    //
    //    if (![dict addSectionWithSettings:@[yawPitchSetting,latLongSetting,hideInfoSetting] withDescription:@"Display" error:&error]) {
    //        NSLog(@"%@",[error valueForKey:@"description"]);
    //        abort();
    //    }
    //    
    //    NSDictionary *settings = [NSDictionary dictionaryWithDictionary:dict];
    //    [self.settingsManager setupSettings:settings sender:self];
}

@end

