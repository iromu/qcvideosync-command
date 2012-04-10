//
//  SocketController.h
//  command
//
//  Created by wantez on 03/08/10.
//  Copyright 2010 Ivan Rodriguez Murillo. All rights reserved.
//

#include <common.h>
#import "GCDAsyncSocket.h"

@class SimplePingController;

@protocol SocketControllerDelegate <NSObject>
@optional
-(void) receiveData: (NSString *) data;
-(void) didConnectToHost;
-(void) didDisconnectFromHost;
- (void)updateConnectedSockets:(NSUInteger)connectedSockets;
- (NSString *)didAcceptNewPeer:(NSString *)peer;
- (void)onSocketwillDisconnectWithError:(NSString *)host port:(UInt16)port;
-(void)updatePeer:(NSString *) peer withLag: (double) lag;
@end


@interface SocketController :  NSObject <NSNetServiceDelegate,GCDAsyncSocketDelegate>{
    NSNetService *netService;
	GCDAsyncSocket*	serverSocket;
	id<SocketControllerDelegate> theDelegate;
	
	BOOL			running;
	NSMutableArray*	connectedSockets;
    
    SimplePingController* pingController;
}

@property (readwrite, strong) id<SocketControllerDelegate> theDelegate;	
@property (readwrite, assign) BOOL running;	

-(id) initWithDelegate: (id<SocketControllerDelegate>) theDelegate;
-(BOOL) startServer: (NSString *) port;
-(void) stopServer;
- (void)broadcastCommand:(NSString *) cmd;
@end

