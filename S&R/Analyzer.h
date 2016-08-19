//
//  Analyzer.h
//  SR1
//
//  Created by Justin Moser on 6/20/14.
//  Copyright (c) 2014 Justin Moser. All rights reserved.
//

#import <Foundation/Foundation.h>

CGPoint brightSpotFromBuffer(const unsigned char *buffer, size_t rows, size_t cols);
//CGPoint brightSpotFromBuffer(NSData *data, size_t rows, size_t cols);

CGPoint brightSpotFromLuma(const unsigned char *buffer, size_t rows, size_t cols);

@interface Analyzer : NSObject

-(CGPoint)brightSpotFromBuffer:(unsigned char *)buffer rows:(size_t)rows cols:(size_t)cols;

-(CGPoint)vectorRedSpotFromBuffer:(unsigned char *)buffer rows:(size_t)rows coloumns:(size_t)cols;
-(CGPoint)vectorBrightSpotFromBuffer:(unsigned char *)buffer rows:(size_t)rows coloumns:(size_t)cols;

@end
