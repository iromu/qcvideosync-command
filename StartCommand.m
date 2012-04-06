//
//  StartCommand.m
//  command
//
//  Created by Iván Rodríguez Murillo on 06/04/12.
//  Copyright (c) 2012 Ivan Rodriguez Murillo. All rights reserved.
//

#import "StartCommand.h"


@implementation StartCommand
- (id)performDefaultImplementation {
    NSLog(@"StartCommand performDefaultImplementation");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"startScriptCommandSent" object:nil userInfo:nil];
	return [NSNumber numberWithInt:1];
}
@end
