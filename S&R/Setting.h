//
//  Setting.h
//  SR1
//
//  Created by Justin Moser on 6/27/14.
//  Copyright (c) 2014 Justin Moser. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SettingType){
    SettingTypeBOOL,       //UISwitch
    SettingTypeString,     //UITextField
    SettingTypeLongString, //UITextView
    SettingTypeInteger,    //UITextField - limited to numbers
    SettingTypeFloat,      //UITextField - limited to numbers and decimal
    SettingTypeButton
};

@interface Setting : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *selName;
@property (nonatomic, strong) NSString *settingDescription;
@property (nonatomic, strong) NSNumber *defaultValue;
@property (nonatomic, assign) SettingType type;
@property (nonatomic, copy) void(^block)(id);

+(Setting *)settingWithName:(NSString *)name description:(NSString *)description defaultValue:(id)defaultValue type:(SettingType)type block:(void(^)(id))block;

@end
