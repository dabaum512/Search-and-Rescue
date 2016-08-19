//
//  SettingsViewController.m
//  SR1
//
//  Created by Justin Moser on 6/27/14.
//  Copyright (c) 2014 Justin Moser. All rights reserved.
//

#import "SettingsViewController.h"
#import "UIControl+Blocks.h"
#import "BlockTextField.h"
//#import "Setting.h"

@interface SettingsViewController () <UITableViewDataSource,UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *sectionTitles;
@property (nonatomic, strong) NSDictionary *settings;
@property (nonatomic, strong) UIView *activeView;
@property (nonatomic, strong) dispatch_queue_t queue;
@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.queue = dispatch_queue_create("settingsQueue", DISPATCH_QUEUE_SERIAL);
    self.tableView = [[UITableView alloc]initWithFrame:self.view.bounds];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    [self.tableView setScrollEnabled:YES];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    [self.view addSubview:self.tableView];
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

-(void)setupSettings:(SettingObject *)object sender:(id)sender {
    self.sectionTitles = [NSMutableArray new];
    NSMutableDictionary *temp = [NSMutableDictionary new];
    int sect = 0;
    
    for (SettingSection *section in object.sections) {
        int row = 0;
        [self.sectionTitles addObject:section.sectionDescription];
        for (Setting *setting in section.settings) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:sect];
            [temp setObject:setting forKey:indexPath];
            if (![[NSUserDefaults standardUserDefaults]objectForKey:setting.name]) {
                [[NSUserDefaults standardUserDefaults]setObject:setting.defaultValue forKey:setting.name];
                [[NSUserDefaults standardUserDefaults]synchronize];
            }
            id currentValue = [[NSUserDefaults standardUserDefaults]objectForKey:setting.name];
            if (setting.type != SettingTypeButton) {
                setting.block(currentValue);
            }
            ++row;
        }
        ++sect;
    }
    
    self.settings = temp;
    [self.tableView reloadData];
}


#pragma mark - Table View Delegate/DataSource

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [UITableViewCell new]; // No reuse
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

-(void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    
    Setting *setting = [self.settings objectForKey:indexPath];
    
    cell.backgroundColor = [UIColor whiteColor];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    cell.textLabel.text = [NSString stringWithFormat:@"%@",setting.settingDescription];
    
    [self addControlToCell:cell fromSetting:setting];
}

#pragma mark - UIControl

-(void)addControlToCell:(UITableViewCell *)cell fromSetting:(Setting *)setting {
    
    void(^begin)(UIView *) = ^(UIView *view){
        _activeView = view;
    };
    
//    void(^end)() = ^{
//        
//    };
    
    void(^end)() = nil;
    
    if (setting.type == SettingTypeBOOL) {
        [self addSwitch:[UISwitch new] toCell:cell withSetting:setting];
        
    } else if (setting.type == SettingTypeString) {
        BlockTextField *textField = [BlockTextField textFieldWithBegin:begin end:end withType:BlockTextFieldTypeString];
        [self addTextField:textField toCell:cell withSetting:setting];
        
    } else if (setting.type == SettingTypeInteger) {
        BlockTextField *textField = [BlockTextField textFieldWithBegin:begin end:end withType:BlockTextFieldTypeInteger];
        [self addTextField:textField toCell:cell withSetting:setting];
        
    } else if (setting.type == SettingTypeFloat) {
        BlockTextField *textField = [BlockTextField textFieldWithBegin:begin end:end withType:BlockTextFieldTypeFloat];
        [self addTextField:textField toCell:cell withSetting:setting];
    } else if (setting.type == SettingTypeButton) {
        cell.textLabel.text = @"";
        [self addButtonToCell:cell withSetting:setting];
    }
}

-(void)addButtonToCell:(UITableViewCell *)cell withSetting:(Setting *)setting {
    UIButton *button = [UIButton new];
    [button setTitle:setting.settingDescription forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button addEventHandler:setting.block forControlEvents:UIControlEventTouchUpInside];
    [cell.contentView addSubview:button];
    [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
    [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:20.0]];
}

-(void)addSwitch:(UISwitch *)switchButton toCell:(UITableViewCell *)cell withSetting:(Setting *)setting {
    
    void(^saveBlock)(id) = ^(id value) {
        dispatch_async(self.queue, ^{
            [[NSUserDefaults standardUserDefaults]setObject:value forKey:setting.name];
            [[NSUserDefaults standardUserDefaults]synchronize];
        });
    };
    
    [switchButton addEventHandler:setting.block forControlEvents:UIControlEventValueChanged];
    [switchButton addEventHandler:saveBlock forControlEvents:UIControlEventValueChanged];
    
    NSNumber *currentValue = [[NSUserDefaults standardUserDefaults]objectForKey:setting.name];
    [switchButton setOn:[currentValue boolValue] animated:NO];
    
    [switchButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [cell.contentView addSubview:switchButton];
    NSDictionary *views = NSDictionaryOfVariableBindings(switchButton);
    NSString *horizontal1 = @"H:[switchButton(51)]-180-|";
    NSString *vertical1 = @"V:|-12-[switchButton]";
    
    [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:horizontal1 options:0 metrics:nil views:views]];
    [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:vertical1 options:0 metrics:nil views:views]];
}

-(void)addTextField:(BlockTextField *)textField toCell:(UITableViewCell *)cell withSetting:(Setting *)setting {
    
    void(^saveBlock)(id) = ^(NSString *text) {
        dispatch_async(self.queue, ^{
            [[NSUserDefaults standardUserDefaults]setObject:text forKey:setting.name];
            [[NSUserDefaults standardUserDefaults]synchronize];
        });
    };
    
    [textField addEventHandler:setting.block forControlEvents:UIControlEventEditingDidEnd];
    [textField addEventHandler:saveBlock forControlEvents:UIControlEventEditingDidEnd];
    
    id currentValue = [[NSUserDefaults standardUserDefaults]objectForKey:setting.name];
    if ([currentValue isKindOfClass:[NSNumber class]]) {
        NSNumberFormatter *formatter = [NSNumberFormatter new];
        formatter.numberStyle = NSNumberFormatterDecimalStyle;
        formatter.maximumFractionDigits = 6;
        currentValue = [formatter stringFromNumber:currentValue];
    }
    [textField setText:currentValue];
    [textField setTranslatesAutoresizingMaskIntoConstraints:NO];
    [cell.contentView addSubview:textField];
    UILabel *label = cell.textLabel;
    UIView *superView = cell.textLabel.superview;
    
    [label removeFromSuperview];
    [label setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [superView addSubview:label];
    NSDictionary *views = NSDictionaryOfVariableBindings(textField,label);
    NSString *horizontal1 = @"H:|-(15)-[label(300)]";
    NSString *horizontal2 = [NSString stringWithFormat:@"H:|-(15)-[textField(%f)]",self.view.bounds.size.width - 192];
    NSString *vertical1 = @"V:|-(8)-[label(30)]-(5)-[textField(30)]";
    [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:horizontal1 options:0 metrics:nil views:views]];
    [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:horizontal2 options:0 metrics:nil views:views]];
    [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:vertical1 options:0 metrics:nil views:views]];
    [cell setNeedsUpdateConstraints];
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *array = [self.settings allKeys];
    int i = 0;
    for (NSIndexPath *indexPath in array) {
        if (indexPath.section == section) {
            ++i;
        }
    }
    return i;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sectionTitles.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Setting *setting = [self.settings objectForKey:indexPath];
    if (setting.type == SettingTypeBOOL) {
        return 55.0;
    } else if (setting.type == SettingTypeButton) {
        return 55.0;
    }
    return 90.0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30.0;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self.sectionTitles objectAtIndex:section];
}

#pragma mark - Keyboard Notification

//- (NSUInteger)supportedInterfaceOrientations {
//    return UIInterfaceOrientationMaskLandscapeRight;
//}

-(BOOL)shouldAutorotate {
    return YES;
}


@end
