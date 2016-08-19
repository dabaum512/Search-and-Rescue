//
//  UIControl+Blocks.m
//  SR1
//
//  Created by Justin Moser on 6/28/14.
//  Copyright (c) 2014 Justin Moser. All rights reserved.
//

//Right now only works with UISwitch Class

#import "UIControl+Blocks.h"
#import <objc/runtime.h>

@interface BlockActionWrapper : NSObject
@property (nonatomic, copy) void (^blockAction)(id);
-(void)invokeBlock:(id)sender;
@end

@implementation BlockActionWrapper
@synthesize blockAction;

-(void)dealloc {
    [self setBlockAction:nil];
}

-(void)invokeBlock:(id)sender {
    if (self.blockAction) {
        if ([sender isKindOfClass:[UISwitch class]]) {
            UISwitch *_switch = sender;
            self.blockAction(@(_switch.on));
        } else if ([sender isKindOfClass:[UITextField class]]) {
            UITextField *textField = sender;
            self.blockAction(textField.text);
        }  else if ([sender isKindOfClass:[UISegmentedControl class]]) {
            UISegmentedControl *control = sender;
            self.blockAction(@(control.selectedSegmentIndex));
        } else {
            self.blockAction(sender);
        }
    }
}
@end



@implementation UIControl (Blocks)

static const char *UIControlBlockActions;

-(void)addEventHandler:(void(^)(id))handler forControlEvents:(UIControlEvents)controlEvents {
    NSMutableArray *blockActions = objc_getAssociatedObject(self, &UIControlBlockActions);
    if (!blockActions) {
        blockActions = [NSMutableArray new];
        objc_setAssociatedObject(self, &UIControlBlockActions, blockActions, OBJC_ASSOCIATION_RETAIN);
    }
    BlockActionWrapper *target = [BlockActionWrapper new];
    [target setBlockAction:handler];
    [blockActions addObject:target];
    [self addTarget:target action:@selector(invokeBlock:) forControlEvents:controlEvents];
}

-(void)removeAllHandlers {
    NSMutableArray *blockActions = objc_getAssociatedObject(self, &UIControlBlockActions);
    if (!blockActions) {
        return;
    }
    [self removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [blockActions removeAllObjects];
}

-(void)removeHandler:(void(^)(id))handler {
    NSMutableArray *blockActions = objc_getAssociatedObject(self, &UIControlBlockActions);
    if (!blockActions) {
        return;
    }
    BlockActionWrapper *actionToRemove;
    for (BlockActionWrapper *action in blockActions) {
        if (action.blockAction == handler) {
            actionToRemove = action;
            break;
        }
    }
    if (actionToRemove) {
        [self removeBlockActionWrapper:actionToRemove];
    }
}

-(void)removeHandlerForControlEvent:(UIControlEvents)controlEvent {
    NSMutableArray *blockActions = objc_getAssociatedObject(self, &UIControlBlockActions);
    if (!blockActions) {
        return;
    }
    BlockActionWrapper *actionToRemove;
    
    for (BlockActionWrapper *action in blockActions) {
        if ([self actionsForTarget:action forControlEvent:controlEvent]) {
            actionToRemove = action;
        }
    }
    if (actionToRemove) {
        [self removeBlockActionWrapper:actionToRemove];
    }
}


-(void)removeBlockActionWrapper:(BlockActionWrapper *)action {
    NSMutableArray *blockActions = objc_getAssociatedObject(self, &UIControlBlockActions);
    if ([blockActions containsObject:action]) {
        [blockActions removeObject:action];
        objc_setAssociatedObject(self, &UIControlBlockActions, blockActions, OBJC_ASSOCIATION_RETAIN);
    }
    if ([[self allTargets]containsObject:action]) {
        [self removeTarget:action action:NULL forControlEvents:UIControlEventAllEvents];
    }
}




@end
