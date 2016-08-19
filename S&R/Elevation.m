//
//  Elevation.m
//  SR1
//
//  Created by Justin Moser on 6/22/14.
//  Copyright (c) 2014 Justin Moser. All rights reserved.
//

#import "Elevation.h"

@interface Elevation() <NSURLConnectionDataDelegate>
@property (nonatomic, strong) void (^callback)(double,NSDate *);

@end

@implementation Elevation

+(Elevation *)getElevationForLocation:(Location)location andCallback:(void(^)(double,NSDate *))callback {
    Elevation *elevation = [Elevation new];
    elevation.callback = callback;

    NSString *gpsStr = [NSString stringWithFormat:@"%f,%f",location.latitude,location.longitude];
    NSString *url = [NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/elevation/json?locations="];
    NSURL *myURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",url,gpsStr]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]init];
    [request setURL:myURL];
    
    NSURLConnection *connection = [[NSURLConnection alloc]initWithRequest:request delegate:elevation];
    [connection start];
    
    return elevation;
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (self.callback) {
        NSError *error = nil;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
        if (error) {
            NSLog(@"%@",data);
        } else {
            if (dict[@"results"]) {
                Class class = [dict[@"results"] class];
                if ([NSStringFromClass(class) isEqualToString:@"__NSCFArray"]) {
                    NSArray *array = dict[@"results"];
                    for (id obj in array) {
                        if ([obj isKindOfClass:[NSDictionary class]]) {
                            NSDictionary *objDict = obj;
                            if (objDict[@"elevation"]) {
                                class = [objDict[@"elevation"] class];
                                NSNumber *elevation;
                                if ([NSStringFromClass(class) isEqualToString:@"__NSCFString"]) {
                                    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
                                    [f setNumberStyle:NSNumberFormatterDecimalStyle];
                                    elevation = [f numberFromString:objDict[@"elevation"]];
                                } else if ([NSStringFromClass(class) isEqualToString:@"__NSCFNumber"]) {
                                    elevation = objDict[@"elevation"];
                                }
                                if (elevation) {
                                    self.callback([elevation doubleValue],[NSDate date]);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}


@end
