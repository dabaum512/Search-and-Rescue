//
//  SettingObject.h
//  SR1
//
//  Created by Justin Moser on 11/2/14.
//  Copyright (c) 2014 Justin Moser. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Setting.h"

@interface SettingSection : NSObject

@property (nonatomic, strong) NSArray *settings;
@property (nonatomic, strong) NSString *sectionDescription;

@end



@interface SettingObject : NSObject

@property (nonatomic,strong) NSArray *sections;

-(void)addSettings:(NSArray *)settings withDescription:(NSString *)description;

@end
