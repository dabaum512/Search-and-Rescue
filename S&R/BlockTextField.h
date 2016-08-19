//
//  BlockTextField.h
//  SR1
//
//  Created by Justin Moser on 6/28/14.
//  Copyright (c) 2014 Justin Moser. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIControl+Blocks.h"

typedef NS_ENUM(NSUInteger, BlockTextFieldType){
    BlockTextFieldTypeString,
    BlockTextFieldTypeInteger,
    BlockTextFieldTypeIntegerPositive,
    BlockTextFieldTypeFloat,
    BlockTextFieldTypeFloatPositive
    
};

@interface BlockTextField : UITextField

@property (nonatomic, assign) BlockTextFieldType type;

+(BlockTextField *)textFieldWithType:(BlockTextFieldType)type;

+(BlockTextField *)textFieldWithBegin:(void(^)(BlockTextField *sender))begin end:(void(^)(BlockTextField *sender))end withType:(BlockTextFieldType)type;

-(instancetype)initWithType:(BlockTextFieldType)type;

-(void)setBeginBlock:(void(^)(BlockTextField *sender))begin;
-(void)setEndBlock:(void(^)(BlockTextField *sender))end;

@end
