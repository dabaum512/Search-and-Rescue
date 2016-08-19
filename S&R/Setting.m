//
//  Setting.m
//  SR1
//
//  Created by Justin Moser on 6/27/14.
//  Copyright (c) 2014 Justin Moser. All rights reserved.
//

#import "Setting.h"

@interface Setting()

@end

@implementation Setting

+(Setting *)settingWithName:(NSString *)name description:(NSString *)description defaultValue:(id)defaultValue type:(SettingType)type block:(void (^)(id))block {
    Setting *setting =[Setting new];
    setting.name = name;
    setting.settingDescription = description;
    setting.defaultValue = defaultValue;
    setting.type = type;
    setting.block = block;
    return setting;
}

@end
