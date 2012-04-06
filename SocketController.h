//
//  SocketController.h
//  command
//
//  Created by wantez on 03/08/10.
//  Copyright 2010 Ivan Rodriguez Murillo. All rights reserved.
//

#include <common.h>
#include "AsyncSocket.h"

@protocol SocketControllerDelegate <NSObject>
@optional
-(void) receiveData: (NSString *) data;
-(void) didConnectToHost;
-(void) didDisconnectFromHost;
- (void)updateConnectedSockets:(NSUInteger)connectedSockets;
- (NSString *)didConnectToHost:(NSString *)host port:(UInt16)port;
- (void)onSocketwillDisconnectWithError:(NSString *)host port:(UInt16)port;
@end


//@class AsyncSocket;
@interface SocketController :  NSObject {
	AsyncSocket*	serverSocket;
	id<SocketControllerDelegate> theDelegate;
	
	BOOL			running;
	NSMutableArray*	connectedSockets;
}

@property (readwrite, retain) id<SocketControllerDelegate> theDelegate;	
@property (readwrite, assign) BOOL running;	

-(id) initWithDelegate: (id<SocketControllerDelegate>) theDelegate;
-(BOOL) startServer: (NSString *) port;
-(void) stopServer;
- (void)broadcastCommand:(NSString *) cmd;
@end

