//
//  SocketController.m
//  command
//
//  Created by wantez on 03/08/10.
//  Copyright 2010 Ivan Rodriguez Murillo. All rights reserved.
//

#import "SocketController.h"


@interface SocketController (PrivateAPI)
- (BOOL) acceptOnPortString:(NSString *)str;
@end

@implementation SocketController

@synthesize theDelegate;
@synthesize running;

-(id) initWithDelegate: (id<SocketControllerDelegate>) delegate {
	self = [super init];
	[self setTheDelegate: delegate];
	NSLog (@"SocketController.initWithDelegate :: Creating Server socket.");
	serverSocket = [[AsyncSocket alloc] initWithDelegate:self];
	
	[serverSocket setRunLoopModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
	
	
	connectedSockets = [[NSMutableArray alloc] initWithCapacity:1];
	running = NO;
	
	return self;
}

- (void) stopServer{
	// Stop accepting connections
	[serverSocket disconnect];
	
	// Stop any client connections
	int i;
	for(i = 0; i < [connectedSockets count]; i++)
	{
		// Call disconnect on the socket,
		// which will invoke the onSocketDidDisconnect: method,
		// which will remove the socket from the list.
		[[connectedSockets objectAtIndex:i] disconnect];
	}
	running = NO;
	
}

-(BOOL) startServer: (NSString *) port{
	return [self acceptOnPortString:port];
}


- (void)broadcastCommand:(NSString *) cmd {
	
	if ([connectedSockets count]>0) {
		//double CurrentTime = [[NSDate date] timeIntervalSince1970];
		//NSString *msg = [NSString stringWithFormat:@"CMD %@ %f\r\n", cmd,CurrentTime];
		NSString *msg = [NSString stringWithFormat:@"CMD %@\r\n", cmd];
		NSData *msgData = [msg dataUsingEncoding:NSUTF8StringEncoding];
		for (AsyncSocket *sock in connectedSockets) {
			[sock writeData:msgData withTimeout:NO_TIMEOUT tag:ECHO_MSG];
		}
	}
}

- (BOOL) acceptOnPortString:(NSString *)str
{
	// AsyncSocket requires a run-loop.
	//NSAssert ([[NSRunLoop currentRunLoop] currentMode] != nil, @"Run loop is not running");
	
	UInt16 port = [str intValue];
	
	NSError *err = nil;
	if ([serverSocket acceptOnPort:port error:&err]){
		NSLog (@"Waiting for connections on port %u.", port);
		running=YES;
		return YES;
	}
	else
	{
		// If you get a generic CFSocket error, you probably tried to use a port
		// number reserved by the operating system.
		
		NSLog (@"Cannot accept connections on port %u. Error domain %@ code %d (%@). Exiting.", port, [err domain], [err code], [err localizedDescription]);
		return NO;
		//exit(1);
	}
}



- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket
{
	NSLog(@"Entering 'onSocket.didAcceptNewSocket'.");
	//[newSocket retain];
	[connectedSockets addObject:newSocket];
	
	
	if ([theDelegate respondsToSelector:@selector(updateConnectedSockets:)])
		[theDelegate updateConnectedSockets: [connectedSockets count]];	
	//[connCounter setStringValue: FORMAT(@"%hu", [connectedSockets count])];
	
}


- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
	NSLog(@"Entering 'onSocket.didConnectToHost'.");
	NSString * welcomeMsg=nil;//= @"Welcome to the Video Server\r\n";
	if ([theDelegate respondsToSelector:@selector(didConnectToHost:port:)])
		welcomeMsg = [theDelegate didConnectToHost: host port: port];	
	
	//[self logInfo:FORMAT(@"Accepted client %@:%hu", host, port)];
	
	
	//NSString *welcomeMsg = @"Welcome to the Video Server\r\n";
	//NSData *welcomeData = [welcomeMsg dataUsingEncoding:NSUTF8StringEncoding];
	
	if (welcomeMsg) {
		NSString *msg = [NSString stringWithFormat:@"CMD %@\r\n", welcomeMsg];
		NSData *welcomeData = [msg dataUsingEncoding:NSUTF8StringEncoding];
		[sock writeData:welcomeData withTimeout:NO_TIMEOUT tag:WELCOME_MSG];
	}
	//[sock writeData:welcomeData withTimeout:NO_TIMEOUT tag:WELCOME_MSG];
	
	[sock readDataToData:[AsyncSocket CRLFData] withTimeout:NO_TIMEOUT tag:0];
}

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
	//if(tag == ECHO_MSG)
	//{
	//[sock readDataToData:[AsyncSocket CRLFData] withTimeout:NO_TIMEOUT tag:0];
	//}
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	NSLog(@"Entering 'onSocket.didReadData'.");
	//NSData *strData = [data subdataWithRange:NSMakeRange(0, [data length] - 2)];
	//NSString *msg = [[[NSString alloc] initWithData:strData encoding:NSUTF8StringEncoding] autorelease];
	
	/*
	 if(msg)
	 {
	 [self logMessage:msg];
	 }
	 else
	 {
	 [self logError:@"Error converting received data into UTF-8 String"];
	 }
	 */
	
	// Even if we were unable to write the incoming data to the log,
	// we're still going to echo it back to the client.
	[sock writeData:data withTimeout:NO_TIMEOUT tag:ECHO_MSG];
}


- (NSTimeInterval)onSocket:(AsyncSocket *)sock
  shouldTimeoutReadWithTag:(long)tag
				   elapsed:(NSTimeInterval)elapsed
				 bytesDone:(CFIndex)length
{
	NSLog(@"Entering 'onSocket.shouldTimeoutReadWithTag'.");
	if(elapsed <= READ_TIMEOUT)
	{
		NSString *warningMsg = @"Are you still there?\r\n";
		NSData *warningData = [warningMsg dataUsingEncoding:NSUTF8StringEncoding];
		
		[sock writeData:warningData withTimeout:NO_TIMEOUT tag:WARNING_MSG];
		
		return READ_TIMEOUT_EXTENSION;
	}
	
	return READ_TIMEOUT_EXTENSION;
}

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
	NSLog(@"Entering 'onSocket.willDisconnectWithError'.");
	if ([theDelegate respondsToSelector:@selector(onSocketwillDisconnectWithError:port:)])
		[theDelegate onSocketwillDisconnectWithError: [sock connectedHost] port: [sock connectedPort]];
	//[self logInfo:FORMAT(@"Client Disconnected: %@:%hu", [sock connectedHost], [sock connectedPort])];
	
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
	NSLog(@"Entering 'onSocket.onSocketDidDisconnect'.");
	[connectedSockets removeObject:sock];
	
	if ([theDelegate respondsToSelector:@selector(updateConnectedSockets:)])
		[theDelegate updateConnectedSockets: [connectedSockets count]];
	
		
	//[connCounter setStringValue: FORMAT(@"%hu", [connectedSockets count])];
}

@end
