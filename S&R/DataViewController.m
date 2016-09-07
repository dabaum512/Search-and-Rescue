//
//  DataViewController.m
//  SR1
//
//  Created by Justin Moser on 11/2/14.
//  Copyright (c) 2014 Justin Moser. All rights reserved.
//

#import "DataViewController.h"
#import "BlockTextField.h"
#import "UIControl+Blocks.h"
#import "DataHandler.h"

NSString *lastURLkey = @"lastURLkey";

@interface TransferView : UIView
-(instancetype)initWithFile:(NSString *)file callback:(void(^)())callback;
@end

@implementation TransferView

-(instancetype)initWithFile:(NSString *)file callback:(void(^)())callback {
    if (self = [super init]) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.8];

        BlockTextField *tf = [BlockTextField textFieldWithBegin:nil end:nil withType:BlockTextFieldTypeString];
        tf.placeholder = [NSString stringWithFormat:@"Enter URL to send file: %@",file];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [tf becomeFirstResponder];
        });
        
        
        
        UIButton *close = [UIButton new];
        close.translatesAutoresizingMaskIntoConstraints = NO;
        [close setTitle:@"Cancel" forState:UIControlStateNormal];
        [close setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [close setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
        
        [close addEventHandler:^(id obj) {
            [tf resignFirstResponder];
            callback();
        } forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *send = [UIButton new];
        send.translatesAutoresizingMaskIntoConstraints = NO;
        [send setTitle:@"Send" forState:UIControlStateNormal];
        [send setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [send setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
        
        [send addEventHandler:^(id obj) {
            [DataHandler sendFile:file toURL:[NSURL URLWithString:tf.text] completion:nil];
            [tf resignFirstResponder];
            callback();
        } forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:tf];
        [self addSubview:close];
        [self addSubview:send];

        UIView *center = [self centerView];
        
        NSDictionary *views = NSDictionaryOfVariableBindings(tf,close,send,center);
        
        NSString *format = @"H:|-5-[tf]-5-|";
        NSArray *h1 = [NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:nil views:views];
        
        format = @"H:[close]-20-[center]-20-[send]";
        NSArray *h2 = [NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:nil views:views];
        
        format = @"V:|-5-[tf]-5-[send]";
        NSArray *v1 = [NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:nil views:views];
        
        NSLayoutConstraint *c = [NSLayoutConstraint constraintWithItem:close attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:send attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];
        
        [self addConstraints:h1];
        [self addConstraints:h2];
        [self addConstraints:v1];
        [self addConstraint:c];
    }
    return self;
}

-(UIView *)centerView {
    UIView *center = [UIView new];
    center.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:center];
    center.opaque = NO;
    center.backgroundColor = [UIColor clearColor];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:center attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:center attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
    [center addConstraint:[NSLayoutConstraint constraintWithItem:center attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:1.0]];
    [center addConstraint:[NSLayoutConstraint constraintWithItem:center attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:1.0]];
    return center;
}


@end


@interface CloseButton : UIControl
@property (nonatomic, strong) UIBezierPath *path;
@end

@implementation CloseButton

static NSString *identifier = @"cellIdentifier";

-(instancetype)initWithEvent:(void(^)(id obj))event {
    if (self = [super init]) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        
        self.path = [UIBezierPath new];
        
        
        CGFloat size = 30.0;
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:size]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:size]];
        
        [self addEventHandler:event forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

-(void)drawRect:(CGRect)rect {
    
    CGFloat x,y;
    x = rect.size.width;
    y = rect.size.height;
    [self.path moveToPoint:CGPointMake(0, 0)];
    [self.path addLineToPoint:CGPointMake(x, y)];
    [self.path moveToPoint:CGPointMake(x, 0)];
    [self.path addLineToPoint:CGPointMake(0, y)];
    [self.path setLineCapStyle:kCGLineCapSquare];
    [self.path setLineWidth:2.0];
    
    
    if (self.highlighted) {
        [[UIColor lightGrayColor]setStroke];
    } else {
        [[UIColor blueColor]setStroke];
    }
    
    [self.path stroke];
}

-(void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    [self setNeedsDisplay];
}

@end



@interface DataViewController ()
@property (nonatomic, strong) NSDictionary *data;
@property (nonatomic, strong) NSArray *tableData;
@end

@implementation DataViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self swapRootView];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:identifier];
    [self resetData];
    
    __weak DataViewController *weakSelf = self;
    
    CloseButton *cancel = [[CloseButton alloc]initWithEvent:^(id obj) {
        __strong DataViewController *strongSelf = weakSelf;
        [strongSelf dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [self.view addSubview:cancel];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:cancel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:10.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:cancel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:-10.0]];
}

-(void)swapRootView {
    UIView *view = self.view;
    
    [self.view removeFromSuperview];
    
    UIView *newView = [UIView new];
    self.view = newView;
    
    [self.view addSubview:view];
}

-(void)resetData {
    self.data = [DataHandler allFiles];
    self.tableData = self.data.allKeys;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tableData.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    cell.textLabel.text = self.tableData[indexPath.row];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    tableView.userInteractionEnabled = NO;
    
    __block TransferView *transferView = [[TransferView alloc]initWithFile:self.tableData[indexPath.row] callback:^{
        [UIView animateWithDuration:0.5 animations:^{
            transferView.alpha = 0.0;
        } completion:^(BOOL finished) {
            [transferView removeFromSuperview];
        }];
        tableView.userInteractionEnabled = YES;
    }];
    
    transferView.alpha = 0.0;
    
    [self.view addSubview:transferView];
    
    NSLayoutConstraint *c1 = [NSLayoutConstraint constraintWithItem:transferView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:0.9 constant:0.0];
    NSLayoutConstraint *c2 = [NSLayoutConstraint constraintWithItem:transferView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:0.9 constant:0.0];
    NSLayoutConstraint *c3 = [NSLayoutConstraint constraintWithItem:transferView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
    NSLayoutConstraint *c4 = [NSLayoutConstraint constraintWithItem:transferView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];
    
    [self.view addConstraints:@[c1,c2,c3,c4]];
    
    [self.view layoutIfNeeded];
    
    [UIView animateWithDuration:0.5 animations:^{
        transferView.alpha = 1.0;
    }];
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}


-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [DataHandler deleteFile:[self.tableData objectAtIndex:indexPath.row]];
        [self resetData];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

@end
