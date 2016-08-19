//
//  LocatorLayer.m
//  S&R
//
//  Created by Justin Moser on 5/5/15.
//  Copyright (c) 2015 Justin Moser. All rights reserved.
//

#import "LocatorLayer.h"

@implementation LocatorLayer

-(id<CAAction>)actionForKey:(NSString *)event {
    return nil;
}

-(void)setTrim:(UIColor *)trim {
    _trim = trim;
    [self setNeedsDisplay];
}

-(void)setFill:(UIColor *)fill {
    _fill = fill;
    [self setNeedsDisplay];
}

-(void)drawInContext:(CGContextRef)ctx {
    CGFloat width, height, lineWidth;
    width = self.bounds.size.width;
    height = self.bounds.size.height;
    lineWidth = 1.0;
    CGFloat radius = width < height ? (width - lineWidth) / 2.0 : (height - lineWidth) / 2.0;
    
    CGContextBeginPath(ctx);
    CGContextAddArc(ctx, width / 2.0, height / 2.0, radius, 0, 2 * M_PI, YES);
    CGContextClosePath(ctx);
    
    CGContextSetLineWidth(ctx, lineWidth);
    CGContextSetStrokeColorWithColor(ctx, _trim.CGColor);
    CGContextSetFillColorWithColor(ctx, _fill.CGColor);
    CGContextDrawPath(ctx, kCGPathFillStroke);
}

@end
