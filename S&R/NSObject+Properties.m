//
//  NSObject+Properties.m
//  SR1
//
//  Created by Justin Moser on 6/30/14.
//  Copyright (c) 2014 Justin Moser. All rights reserved.
//

#import "NSObject+Properties.h"
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@implementation NSObject (Properties)

- (NSArray *)propertyList {
    Class currentClass = [self class];
    
    NSMutableArray *propertyInfo = [NSMutableArray new];
    // class_copyPropertyList does not include properties declared in super classes
    // so we have to follow them until we reach NSObject
    do {
        unsigned int outCount, i;
        objc_property_t *properties = class_copyPropertyList(currentClass, &outCount);
        
        for (i = 0; i < outCount; i++) {
            objc_property_t property = properties[i];
            
            NSString *propertyName = [NSString stringWithFormat:@"%s", property_getName(property)];
            
            [propertyInfo addObject:propertyName];
        }
        free(properties);
        currentClass = [currentClass superclass];
    } while ([currentClass superclass]);
    
    return propertyInfo;
}

@end
