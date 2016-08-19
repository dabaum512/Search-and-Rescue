//
//  SettingObject.m
//  SR1
//
//  Created by Justin Moser on 11/2/14.
//  Copyright (c) 2014 Justin Moser. All rights reserved.
//

#import "SettingObject.h"

@implementation SettingSection

@end


@interface SettingObject()
@property (nonatomic,strong) NSMutableArray *internalSections;
@end

@implementation SettingObject

-(instancetype)init {
    if (self = [super init]) {
        self.internalSections = [NSMutableArray new];
    }
    return self;
}

-(void)addSettings:(NSArray *)settings withDescription:(NSString *)description {
    SettingSection *section = [SettingSection new];
    section.settings = settings;
    section.sectionDescription = description;
    [self.internalSections addObject:section];
}

-(NSArray *)sections {
    return [NSArray arrayWithArray:self.internalSections];
}



@end
