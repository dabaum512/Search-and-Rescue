//
//  DataHandler.h
//  SR1
//
//  Created by Justin Moser on 11/2/14.
//  Copyright (c) 2014 Justin Moser. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Header.h"

@interface DataHandler : NSObject

+(void)sendFile:(NSString *)file toURL:(NSURL *)url;

+(BOOL)startNewRecording;

+(BOOL)handleData:(PostData)data;

+(BOOL)save:(void(^)(void))completion;

+(void)cancel;

+(NSDictionary *)allFiles;

+(void)deleteFile:(NSString *)file;

+(void)deleteAll;

@end
