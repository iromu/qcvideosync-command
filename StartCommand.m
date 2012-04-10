//
//  StartCommand.m
//  command
//
//  Created by Iván Rodríguez Murillo on 06/04/12.
//  Copyright (c) 2012 Ivan Rodriguez Murillo. All rights reserved.
//

#import "StartCommand.h"

// Log levels: off, error, warn, info, verbose
#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

@implementation StartCommand
- (id)performDefaultImplementation {
    DDLogVerbose(@"StartCommand performDefaultImplementation");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"startScriptCommandSent" object:nil userInfo:nil];
	return [NSNumber numberWithInt:1];
}
@end
