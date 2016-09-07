//
//  DataHandler.m
//  SR1
//
//  Created by Justin Moser on 11/2/14.
//  Copyright (c) 2014 Justin Moser. All rights reserved.
//

#import "DataHandler.h"
#import <UIKit/UIKit.h>

@interface DataHandler()
@property (nonatomic, strong) NSMutableDictionary *recording;
@property (nonatomic, strong) dispatch_queue_t queue;
@end

@implementation DataHandler

+(DataHandler *)sharedHandler {
    static DataHandler *handler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        handler = [DataHandler new];
        handler.queue = dispatch_queue_create("com.datahandler.giraffe", DISPATCH_QUEUE_SERIAL);
    });
    return handler;
}

+(void)sendFile:(NSString *)file toURL:(NSURL *)url completion:(void(^)(NSError *error))completion {
    NSString *path = [[self documents]stringByAppendingPathComponent:file];
    NSData *data = [[NSFileManager defaultManager]contentsAtPath:path];
    [self sendData:data toURL:url completion:completion];
}

+(void)sendData:(NSData *)data toURL:(NSURL *)url completion:(void(^)(NSError *error))completion {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPBody = data;
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    [[[NSURLSession sharedSession]dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (completion) {
            completion(error);
        }
    }]resume];
}

//+(void)showError:(NSError *)error {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        
//        static UIWindow *window = nil;
//        
//        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
//        
//        window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
//        
//        UIViewController *c = [UIViewController new];
//        window.rootViewController = c;
//        
//        window.windowLevel = 2000;
//        window.alpha = 0.0;
//        
//        [window makeKeyAndVisible];
//        
//        [c presentViewController:alert animated:NO completion:^{
//            [UIView animateWithDuration:0.25 animations:^{
//                window.alpha = 1.0;
//            } completion:^(BOOL finished) {
//                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                    [UIView animateWithDuration:0.25 animations:^{
//                        window.alpha = 0.0;
//                    } completion:^(BOOL finished) {
//                        [window setHidden:YES];
//                        window.rootViewController = nil;
//                        window = nil;
//                    }];
//                });
//            }];
//        }];
//    });
//}

+(BOOL)handleData:(PostData)postData {
    DataHandler *handler = [DataHandler sharedHandler];
    if (handler.recording) {
        dispatch_async(handler.queue, ^{
            NSArray *array = @[@(postData.latitude1),
                               @(postData.longitude1),
                               @(postData.altitude),
                               @(postData.yaw),
                               @(postData.pitch)];
            NSString *key = [NSString stringWithFormat:@"p%lu",(unsigned long)handler.recording.count];
            [handler.recording setObject:array forKey:key];
        });
        return YES;
    }
    return NO;
}


+(BOOL)startNewRecording {
    DataHandler *handler = [DataHandler sharedHandler];
    if (handler.recording) {
        return NO;
    } else {
        handler.recording = [NSMutableDictionary new];
        return YES;
    }
}

+(void)cancel {
    DataHandler *handler = [DataHandler sharedHandler];
    dispatch_async(handler.queue, ^{
        handler.recording = nil;
    });
}

+(NSDictionary *)allFiles {
    NSString *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSError *error = nil;
    NSArray *contents = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:documents error:&error];
    if (error) {
        NSLog(@"%@",error);
    } else {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:contents.count];
        for (NSString *subpath in contents) {
            NSLog(@"%@",subpath);
            NSString *item = [documents stringByAppendingPathComponent:subpath];
            NSData *data = [[NSFileManager defaultManager]contentsAtPath:item];
            NSDictionary *file = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
            if (error) {
                NSLog(@"%@",error);
                return nil;
            } else {
                [dict setObject:file forKey:subpath];
            }
        }
        return [NSDictionary dictionaryWithDictionary:dict];
    }
    return nil;
}

+(void)deleteFile:(NSString *)file {
    NSString *path = [[self documents]stringByAppendingPathComponent:file];
    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager]removeItemAtPath:path error:&error];
    if (error) {
        NSLog(@"%@",error);
    } else if (!success) {
        NSLog(@"Delete not successful");
    }
}

+(BOOL)save:(void(^)(void))completion {
    
    NSDictionary *dict = [DataHandler sharedHandler].recording;
    
    if (!dict) {
        NSLog(@"No data to save");
        return NO;
    }
    
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        NSLog(@"%@",error);
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            
            NSDateFormatter *formatter = [NSDateFormatter new];
            [formatter setDateFormat:@"MM-dd-yyyy hh:mm:ss a"];
            NSString *date = [formatter stringFromDate:[NSDate date]];
            NSString *path = [[self documents] stringByAppendingPathComponent:date];
            
            BOOL success = [data writeToFile:path atomically:YES];
            if (!success) {
                NSLog(@"Error saving file");
            } else {
                NSLog(@"Save file success");
                [[DataHandler sharedHandler]setRecording:nil];
            }
            if (completion) {
                completion();
            }
        });
    }
    return YES;
}

+(NSString *)documents {
    return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
}

+(void)deleteAll {
    NSError *error = nil;
    NSArray *contents = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:[self documents] error:&error];
    if (error) {
        NSLog(@"%@",error);
    } else {
        for (NSString *file in contents) {
            [self deleteFile:file];
        }
    }
}

@end
