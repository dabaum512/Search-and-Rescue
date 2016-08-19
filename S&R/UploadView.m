//
//  UploadView.m
//  S&R
//
//  Created by Justin Moser on 5/17/15.
//  Copyright (c) 2015 Justin Moser. All rights reserved.
//

#import "UploadView.h"

@interface UploadView() <UITextFieldDelegate, NSURLSessionTaskDelegate>
@property (nonatomic, strong) NSURLSession *session;
@end

@implementation UploadView

-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

-(void)setup {
    
    self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
    self.backgroundColor = [UIColor whiteColor];
    
    self.mainLabel = [UILabel new];
    self.serverField = [UITextField new];
    self.activityIndicator = [UIActivityIndicatorView new];
    self.progressBar = [UIProgressView new];
    self.button = [UIButton new];
    
    self.mainLabel.text = @"Send data to server";
    self.serverField.placeholder = @"Enter server address";
    self.progressBar.progress = 0.2;
    [self.button setTitle:@"Button" forState:UIControlStateNormal];
    [self.button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    
    self.activityIndicator.alpha = 0.0;
    self.progressBar.alpha = 0.0;
    
    [self.button addTarget:self action:@selector(sendData:) forControlEvents:UIControlEventTouchUpInside];
    
    NSArray *views = @[_mainLabel,_serverField,_activityIndicator,_progressBar,_button];
    
    for (UIView *view in views) {
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:view];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    }
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.activityIndicator attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.serverField attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.activityIndicator attribute:NSLayoutAttributeTop multiplier:1.0 constant:-10.0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.mainLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.serverField attribute:NSLayoutAttributeTop multiplier:1.0 constant:-10.0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.progressBar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.activityIndicator attribute:NSLayoutAttributeBottom multiplier:1.0 constant:10.0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.button attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.progressBar attribute:NSLayoutAttributeBottom multiplier:1.0 constant:10.0]];
    
    
    [self.progressBar addConstraint:[NSLayoutConstraint constraintWithItem:self.progressBar attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:100]];
    [self.serverField addConstraint:[NSLayoutConstraint constraintWithItem:self.serverField attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:150]];
    
    self.serverField.delegate = self;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self checkValid];
    });
    return YES;
}

-(void)checkValid {
    NSURLComponents *comps = [NSURLComponents componentsWithString:self.serverField.text];
    if (!comps.scheme) {
        comps.scheme = @"http";
    }
    NSURL *url = [comps URL];
    if (url) {
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        if (request) {
            [[[NSURLSession sharedSession]dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                        NSLog(@"%@",error);
                        [self setServerFieldValid:NO];
                    } else {
                        NSLog(@"VALID!!!");
                        [self setServerFieldValid:YES];
                    }
                    printf("\n\n");
                });
            }]resume];
        } else {
            [self setServerFieldValid:NO];
        }
    } else {
        [self setServerFieldValid:NO];
    }
}

-(void)setServerFieldValid:(BOOL)valid {
    if (valid) {
        self.serverField.backgroundColor = [[UIColor greenColor]colorWithAlphaComponent:0.2];
    } else {
        self.serverField.backgroundColor = [[UIColor redColor]colorWithAlphaComponent:0.2];
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

-(void)sendData:(id)caller {
    
//    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
//    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue new]];
    
    
    
//    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
//    
//    request.HTTPMethod = @"POST";
//    request.HTTPBody = nil;
    
    
    NSURL *file = nil;
    NSURL *url = [NSURL URLWithString:self.serverField.text];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    [[self.session uploadTaskWithRequest:request fromFile:file completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            //
        }
        [self displayUpload:NO];
    }]resume];
    
    [self displayUpload:YES];
}

-(void)displayUpload:(BOOL)display {
    if (display) {
        [self.activityIndicator startAnimating];
    } else {
        [self.activityIndicator stopAnimating];
    }
    double alpha = display ? 1.0 : 0.0;
    [UIView animateWithDuration:0.4 animations:^{
        self.activityIndicator.alpha = alpha;
        self.progressBar.alpha = alpha;
    }];
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    double progress = (double)totalBytesSent / (double)totalBytesExpectedToSend;
    [self.progressBar setProgress:progress animated:YES];
}


@end
