//
//  SimplePingDelegate.h
//  command
//
//  Created by Iván Rodríguez Murillo on 08/04/12.
//  Copyright (c) 2012 Ivan Rodriguez Murillo. All rights reserved.
//

#include "SimplePing.h"

#include <sys/socket.h>
#include <netdb.h>

@interface SimplePingController  : NSObject<SimplePingDelegate>
{
    SimplePing *    _pinger;
    NSTimer *       _sendTimer;
    BOOL            _done;
}

@property (nonatomic, strong, readwrite) SimplePing *   pinger;
@property (nonatomic, strong, readwrite) NSTimer *      sendTimer;

- (void)runWithHostName:(NSString *)hostName;
- (void)runWithHostAddress:(NSData *)hostAddress;

@end
