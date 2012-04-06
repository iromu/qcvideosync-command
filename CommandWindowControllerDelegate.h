//
//  CommandWindowControllerDelegate.h
//  command
//
//  Created by wantez on 30/08/10.
//  Copyright 2010 Ivan Rodriguez Murillo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SocketController.h"

@protocol CommandWindowControllerDelegate
-(SocketController*)	listenSocket;
- (void) updateMIDISources;
@end