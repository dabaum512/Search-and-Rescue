//
//  UIControl+Blocks.h
//  SR1
//
//  Created by Justin Moser on 6/28/14.
//  Copyright (c) 2014 Justin Moser. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIControl (Blocks)

-(void)addEventHandler:(void(^)(id obj))handler forControlEvents:(UIControlEvents)controlEvents;
-(void)removeHandler:(void(^)(id))handler;
-(void)removeAllHandlers;
-(void)removeHandlerForControlEvent:(UIControlEvents)controlEvent;


@end
