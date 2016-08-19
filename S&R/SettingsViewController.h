//
//  SettingsViewController.h
//  SR1
//
//  Created by Justin Moser on 6/27/14.
//  Copyright (c) 2014 Justin Moser. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingObject.h"

@interface SettingsViewController : UIViewController

-(void)setupSettings:(SettingObject *)object sender:(id)sender;

//-(void)setupSettings:(NSDictionary *)dict sender:(id)sender;

@end
