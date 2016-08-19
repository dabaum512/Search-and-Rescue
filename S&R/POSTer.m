//
//  POSTer.m
//  SR1
//
//  Created by Justin Moser on 6/20/14.
//  Copyright (c) 2014 Justin Moser. All rights reserved.
//

#import "POSTer.h"

@interface POSTer() <NSURLConnectionDataDelegate>
@property (nonatomic, strong) NSMutableDictionary *JSONDictionary;

@end

@implementation POSTer

+(instancetype)shared {
    static POSTer *poster = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        poster = [POSTer new];
    });
    return poster;
}

-(void)handlePostData:(PostData)postData {
    NSArray *array = @[@(postData.latitude1),
                       @(postData.longitude1),
                       @(postData.altitude),
                       @(postData.yaw),
                       @(postData.pitch)];
    
    NSString *key = [NSString stringWithFormat:@"p%i",(int)self.JSONDictionary.count];
    [self.JSONDictionary setObject:array forKey:key];
    if (self.JSONDictionary.count >= 100) {
        [self sendData];
    }
}

-(void)sendData {
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.JSONDictionary options:0 error:&error];
    if (error) {
        NSLog(@"%@",error);
        return;
    }
//    NSURL *myURL = [NSURL URLWithString:@"http://davidawehr.com/php_upload/json.php"];
    
    NSURL *myURL;
    if (self.serverAddress.length > 0) {
        myURL = [NSURL URLWithString:self.serverAddress];
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]init];
    [request setURL:myURL];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%ld",(long)[jsonData length]] forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPBody:jsonData];
    
    NSURLConnection *connection = [[NSURLConnection alloc]initWithRequest:request delegate:self];
    [connection start];
    [self.JSONDictionary removeAllObjects];
}

+(void)upload:(NSData *)data to:(NSString *)address progress:(void (^)(double))block {
    
    NSURL *url = [NSURL URLWithString:address];
    
    if (url) {
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc]init];
        
        [request setURL:url];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"%ld",(long)[data length]] forHTTPHeaderField:@"Content-Length"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [request setHTTPBody:data];
        
        [[[NSURLConnection alloc]initWithRequest:request delegate:[self shared]]start];
        
//        [[[NSURLSession sharedSession]uploadTaskWithRequest:request fromData:data completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
//            if (block) {
//                block(1.0);
//            }
//        }]resume];
    }
}

-(void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
//    double progress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
    
}

-(BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    if([[protectionSpace authenticationMethod] isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        return YES;
    }
    return NO;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    NSLog(@"%@",response);
    int code = (int)[httpResponse statusCode];
    NSLog(@"%i",code);
}

- (void) connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]
             forAuthenticationChallenge:challenge];
    }
    
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"%@",error);
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    NSLog(@"%@",[[NSString alloc]initWithData:data encoding:NSASCIIStringEncoding]);
}

-(NSMutableDictionary *)JSONDictionary {
    if (_JSONDictionary) {
        return _JSONDictionary;
    }
    _JSONDictionary = [NSMutableDictionary dictionaryWithCapacity:100];
    return _JSONDictionary;
}

@end
