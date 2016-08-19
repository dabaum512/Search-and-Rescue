//
//  UploadView.h
//  S&R
//
//  Created by Justin Moser on 5/17/15.
//  Copyright (c) 2015 Justin Moser. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UploadView : UIView

//@property (weak, nonatomic) IBOutlet UILabel *mainLabel;
//@property (weak, nonatomic) IBOutlet UITextField *serverField;
//@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
//@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
//@property (weak, nonatomic) IBOutlet UIButton *button;

@property (strong, nonatomic) UILabel *mainLabel;
@property (strong, nonatomic) UITextField *serverField;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) UIProgressView *progressBar;
@property (strong, nonatomic) UIButton *button;

@end
