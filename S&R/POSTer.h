//
//  POSTer.h
//  SR1
//
//  Created by Justin Moser on 6/20/14.
//  Copyright (c) 2014 Justin Moser. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "Header.h"

@interface POSTer : NSObject

@property (nonatomic, strong) NSString *serverAddress;

-(void)handlePostData:(PostData)postData;

@end
