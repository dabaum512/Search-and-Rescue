//
//  UIImage+Category.h
//  S&R
//
//  Created by Justin Moser on 5/11/15.
//  Copyright (c) 2015 Justin Moser. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage(Category)
- (UIImage *)blurredImageWithRadius:(CGFloat)radius iterations:(NSUInteger)iterations tintColor:(UIColor *)tintColor;
@end
