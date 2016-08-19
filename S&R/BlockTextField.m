//
//  BlockTextField.m
//
//  Created by Justin Moser
//

#import "BlockTextField.h"



@interface BlockTextField() <UITextFieldDelegate>
@property (nonatomic, strong) UITapGestureRecognizer *tapGR;
@property (nonatomic, assign) BOOL registeredForKeyboard;
@property (nonatomic, strong) UIScrollView *parentScrollView;
@property (nonatomic, strong) UIScrollView *helperScrollView;
@end

@implementation BlockTextField

-(instancetype)init {
    self = [super init];
    if (self) {
        self.delegate = self;
        self.type = BlockTextFieldTypeString;
        [self setup];
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.delegate = self;
        self.type = BlockTextFieldTypeString;
        [self setup];
        [self setFrame:frame];
    }
    return self;
}

-(instancetype)initWithType:(BlockTextFieldType)type {
    if (self = [super init]) {
        self.delegate = self;
        self.type = type;
        [self setup];
    }
    return self;
}

-(void)dealloc {
    [self cleanup];
}

-(void)setup {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.autocorrectionType = UITextAutocorrectionTypeNo;
    self.clearsOnBeginEditing = NO;
    self.borderStyle = UITextBorderStyleRoundedRect;
    self.returnKeyType = UIReturnKeyDone;
    self.autocapitalizationType = UITextAutocapitalizationTypeNone;
    if (self.type == BlockTextFieldTypeString) {
        self.keyboardType = UIKeyboardTypeAlphabet;
    } else {
        self.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    }
}

+(BlockTextField *)textFieldWithType:(BlockTextFieldType)type {
    return [BlockTextField textFieldWithBegin:nil end:nil withType:type];
}

+(BlockTextField *)textFieldWithBegin:(void (^)(BlockTextField *))begin end:(void (^)(BlockTextField *))end withType:(BlockTextFieldType)type {
    BlockTextField *textField = [BlockTextField new];
    textField.type = type;
    [textField setup];
    [textField addEventHandler:begin forControlEvents:UIControlEventEditingDidBegin];
    [textField addEventHandler:end forControlEvents:UIControlEventEditingDidEnd];
    return textField;
}

-(void)setFrame:(CGRect)frame {
    self.translatesAutoresizingMaskIntoConstraints = YES;
    [super setFrame:frame];
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    BOOL(^check)(NSString *) = ^BOOL(NSString *acceptableChars) {
        NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:acceptableChars]invertedSet];
        NSArray *str = [[textField.text stringByReplacingCharactersInRange:range withString:string]componentsSeparatedByString:@"."];
        NSString *filteredString = [[string componentsSeparatedByCharactersInSet:cs]componentsJoinedByString:@""];
        if ([string isEqualToString:filteredString] && str.count < 3) {
            return YES;
        } else {
            return NO;
        }
    };
    
    BlockTextField *tf;
    if ([textField isKindOfClass:[BlockTextField class]]) {
        tf = (BlockTextField *)textField;
    }
    if (tf) {
        if (tf.type == BlockTextFieldTypeInteger) {
            return check(@"0123456789");
            
        } else if (tf.type == BlockTextFieldTypeFloat) {
            if (range.location == 0) {
                return check(@"-0123456789.");
            }
            return check(@"0123456789.");
            
        } else if (tf.type == BlockTextFieldTypeFloatPositive) {
            return check(@"0123456789.");
            
        } else if (tf.type == BlockTextFieldTypeString) {
            return YES;
        }
    }
    return NO;
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    [self findAndRegisterScrollView:textField];
    self.tapGR = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dismissTextField)];
    [self.superview addGestureRecognizer:self.tapGR];
    return YES;
}

-(void)dismissTextField {
    [self textFieldShouldReturn:self];
}

-(void)cleanup {
    if (self.tapGR) {
        [self.tapGR removeTarget:nil action:NULL];
        self.tapGR = nil;
    }
    if (self.registeredForKeyboard) {
        [[NSNotificationCenter defaultCenter]removeObserver:self];
        self.registeredForKeyboard = NO;
    }
    if (self.helperScrollView) {
        self.helperScrollView.scrollEnabled = NO;
    }
}

-(BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    [self cleanup];
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.2];
    [UIView setAnimationCurve:2];
    
    self.parentScrollView.contentInset = UIEdgeInsetsZero;
    self.parentScrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
    
    [UIView commitAnimations];
    
    [textField resignFirstResponder];
    return YES;
}

-(void)setDelegate:(id<UITextFieldDelegate>)delegate {
    // BlockTextField is its own delegate
    [super setDelegate:self];
}


#pragma mark - ScrollView Registration

-(void)findAndRegisterScrollView:(UITextField *)textField {
    
    //Credit: http://stackoverflow.com/a/18780157/3055415
    UIView *view = textField;

    while (view) {
        view = view.superview;
        if ([view isKindOfClass:[UIScrollView class]]) {
            while (view.superview && [view.superview isKindOfClass:[UIScrollView class]]) {
                view = view.superview;
            }
            self.parentScrollView = (UIScrollView *)view;
//            if ([self.parentScrollView isEqual:self.helperScrollView]) {
//                self.helperScrollView.scrollEnabled = YES;
//            }
            [self registerForKeyboardNotifications];
            return;
        }
    }
}

- (void)registerForKeyboardNotifications
{
    self.registeredForKeyboard = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification*)notification
{
    // Credit: http://stackoverflow.com/a/15165548/3055415
    
    CGPoint modPoint1 = [self.window convertPoint:CGPointMake(0.0, 0.0) fromView:self.parentScrollView];
    CGFloat mod = self.parentScrollView.contentOffset.y + modPoint1.y;

    NSDictionary *userInfo = [notification userInfo];
    
    CGRect keyboardFrameInWindow;
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrameInWindow];

    CGRect keyboardFrameInView = [self.parentScrollView.window convertRect:keyboardFrameInWindow fromView:nil];
    
    CGRect scrollViewKeyboardIntersection = CGRectIntersection(self.parentScrollView.frame, keyboardFrameInView);
    UIEdgeInsets newContentInsets = UIEdgeInsetsMake(0, 0, scrollViewKeyboardIntersection.size.height + mod, 0);
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:[[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
    
    self.parentScrollView.contentInset = newContentInsets;
    self.parentScrollView.scrollIndicatorInsets = newContentInsets;
    
    CGRect controlFrameInScrollView = [self.parentScrollView convertRect:self.bounds fromView:self];
    
    controlFrameInScrollView = CGRectInset(controlFrameInScrollView, 0, 0);
    
    CGFloat controlVisualOffsetToTopOfScrollview = controlFrameInScrollView.origin.y - self.parentScrollView.contentOffset.y;
    CGFloat controlVisualBottom = controlVisualOffsetToTopOfScrollview + controlFrameInScrollView.size.height;
    
    CGFloat scrollViewVisibleHeight = self.parentScrollView.frame.size.height - scrollViewKeyboardIntersection.size.height;
    
    if (controlVisualBottom > scrollViewVisibleHeight) {
        
        CGPoint newContentOffset = self.parentScrollView.contentOffset;
        newContentOffset.y += (controlVisualBottom - scrollViewVisibleHeight);
        
        newContentOffset.y = MIN(newContentOffset.y, self.parentScrollView.contentSize.height - scrollViewVisibleHeight);
        
        [self.parentScrollView setContentOffset:newContentOffset animated:NO];
        
    } else if (controlFrameInScrollView.origin.y < self.parentScrollView.contentOffset.y) {
        
        CGPoint newContentOffset = self.parentScrollView.contentOffset;
        newContentOffset.y = controlFrameInScrollView.origin.y;
        
        [self.parentScrollView setContentOffset:newContentOffset animated:NO];
    }
    
    [UIView commitAnimations];
}

- (void)keyboardWillBeHidden:(NSNotification*)notification
{
    NSDictionary *userInfo = notification.userInfo;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:[[userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[[userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
    
    self.parentScrollView.contentInset = UIEdgeInsetsZero;
    self.parentScrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
    
    [UIView commitAnimations];
}

-(void)setBeginBlock:(void(^)(BlockTextField *sender))begin {
    [self removeHandlerForControlEvent:UIControlEventEditingDidBegin];
    [self addEventHandler:begin forControlEvents:UIControlEventEditingDidBegin];
}
-(void)setEndBlock:(void(^)(BlockTextField *sender))end {
    [self removeHandlerForControlEvent:UIControlEventEditingDidEnd];
    [self addEventHandler:end forControlEvents:UIControlEventEditingDidEnd];
}

@end



