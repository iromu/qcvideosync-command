//
//  SocketController.m
//  command
//
//  Created by wantez on 03/08/10.
//  Copyright 2010 Ivan Rodriguez Murillo. All rights reserved.
//

#import "SocketController.h"
#import "SimplePingController.h"
#import "GCDAsyncSocket.h"

@interface SocketController (PrivateAPI)
- (BOOL) acceptOnPortString:(NSString *)str;
-(NSString*) getPeerName:(GCDAsyncSocket *)sock;
@end

@implementation SocketController

@synthesize theDelegate;
@synthesize running;

-(id) initWithDelegate: (id<SocketControllerDelegate>) delegate {
	self = [super init];
	[self setTheDelegate: delegate];
    
    pingController = [[SimplePingController alloc]init];
	NSLog (@"SocketController.initWithDelegate :: Creating Server socket.");
	serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
	
	//[serverSocket setRunLoopModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
	
	
	connectedSockets = [[NSMutableArray alloc] initWithCapacity:1];
	running = NO;
	
	return self;
}

- (void) stopServer{
    [netService stop];
    
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
		for (GCDAsyncSocket *sock in connectedSockets) {
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
        
        netService = [[NSNetService alloc] initWithDomain:@"local."
		                                             type:@"_QCVideoSync._tcp."
		                                             name:@""
		                                             port:port];
		
		[netService setDelegate:self];
		[netService publish];
        
		return YES;
	}
	else
	{
		// If you get a generic CFSocket error, you probably tried to use a port
		// number reserved by the operating system.
		
		NSLog (@"Cannot accept connections on port %u. Error domain %@ code %ld (%@). Exiting.", port, [err domain], [err code], [err localizedDescription]);
		return NO;
		//exit(1);
	}
}


- (void)netServiceDidPublish:(NSNetService *)ns
{
	NSLog(@"Bonjour Service Published: domain(%@) type(%@) name(%@) port(%i)",
          [ns domain], [ns type], [ns name], (int)[ns port]);
}

- (void)netService:(NSNetService *)ns didNotPublish:(NSDictionary *)errorDict
{
	// Override me to do something here...
	// 
	// Note: This method in invoked on our bonjour thread.
	
	NSLog(@"Failed to Publish Service: domain(%@) type(%@) name(%@) - %@",
          [ns domain], [ns type], [ns name], errorDict);
}
#pragma mark GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket;
{
	NSLog(@"Entering 'onSocket.didAcceptNewSocket'.");
	//[newSocket retain];
	[connectedSockets addObject:newSocket];
	
	
	if ([theDelegate respondsToSelector:@selector(updateConnectedSockets:)])
		[theDelegate updateConnectedSockets: [connectedSockets count]];	
	//[connCounter setStringValue: FORMAT(@"%hu", [connectedSockets count])];
	
}


- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
	NSLog(@"Entering 'onSocket.didConnectToHost'.");
	NSString * welcomeMsg=nil;//= @"Welcome to the Video Server\r\n";
	if ([theDelegate respondsToSelector:@selector(didConnectToHost:port:)])
		welcomeMsg = [theDelegate didConnectToHost: host port: port];	
	
	NSLog(@"Accepted client %@:%hu", host, port);
	
	
	//NSString *welcomeMsg = @"Welcome to the Video Server\r\n";
	//NSData *welcomeData = [welcomeMsg dataUsingEncoding:NSUTF8StringEncoding];
	
	if (welcomeMsg) {
		NSString *msg = [NSString stringWithFormat:@"CMD %@\r\n", welcomeMsg];
		NSData *welcomeData = [msg dataUsingEncoding:NSUTF8StringEncoding];
		[sock writeData:welcomeData withTimeout:NO_TIMEOUT tag:WELCOME_MSG];
	}
    
    double CurrentTime = [[NSDate date] timeIntervalSince1970];
    NSString *tick = FORMAT(@"Tick %f\r\n", CurrentTime);
    NSData *tickData = [tick dataUsingEncoding:NSUTF8StringEncoding];
	[sock writeData:tickData withTimeout:NO_TIMEOUT tag:TICK_MSG];
	
	[sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:NO_TIMEOUT tag:0];
    // NSData * hostAddress = [[NSData alloc]init] ;        
    //[pingController runWithHostAddress:hostAddress];
    //pingController.pinger = nil;
    //pingController.sendTimer = nil;
    //[pingController runWithHostName:host];
    
}



- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag;
{
	//if(tag == ECHO_MSG)
	//{
	//[sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:NO_TIMEOUT tag:0];
	//}
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag;
{
	NSLog(@"Entering 'onSocket.didReadData'.");
    
	//NSData *strData = [data subdataWithRange:NSMakeRange(0, [data length] - 2)];
    //	NSString *msg = [[[NSString alloc] initWithData:strData encoding:NSUTF8StringEncoding] autorelease];
	NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
	
    if(str)
    {
        //[self logMessage:msg];
        //NSLog(@"%@ from %@", str,sock);
        if([str hasPrefix: @"Tick "]){
            double CurrentTime = [[NSDate date] timeIntervalSince1970];
            double lag = (CurrentTime - [[str substringFromIndex:5] doubleValue] ) * 1000.00;
            NSString* peer = [self getPeerName:sock];
            NSLog(@"lag: %f ms from %@", lag, peer);
            if ([theDelegate respondsToSelector:@selector(updatePeer:withLag:)])
               [theDelegate updatePeer: peer withLag: lag];
        }
    }
    else
    {
        NSLog(@"Error converting received data into UTF-8 String");
        
    }
	
	// Even if we were unable to write the incoming data to the log,
	// we're still going to echo it back to the client.
	//[sock writeData:data withTimeout:NO_TIMEOUT tag:ECHO_MSG];
}
#pragma mark -
-(NSString*) getPeerName:(GCDAsyncSocket *)sock
{	
    return [NSString stringWithFormat: @"%@:%u",
               [sock connectedHost],
               [sock connectedPort]];
}

- (NSTimeInterval)onSocket:(GCDAsyncSocket *)sock
  shouldTimeoutReadWithTag:(long)tag
				   elapsed:(NSTimeInterval)elapsed
				 bytesDone:(CFIndex)length
{
	NSLog(@"Entering 'onSocket.shouldTimeoutReadWithTag'.");
	if(elapsed <= READ_TIMEOUT)
	{
		NSString *warningMsg = @"WARNING Are you still there?\r\n";
		NSData *warningData = [warningMsg dataUsingEncoding:NSUTF8StringEncoding];
		
		[sock writeData:warningData withTimeout:NO_TIMEOUT tag:WARNING_MSG];
		
		return READ_TIMEOUT_EXTENSION;
	}
	
	return READ_TIMEOUT_EXTENSION;
}

- (void)onSocket:(GCDAsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
	NSLog(@"Entering 'onSocket.willDisconnectWithError'.");
	if ([theDelegate respondsToSelector:@selector(onSocketwillDisconnectWithError:port:)])
		[theDelegate onSocketwillDisconnectWithError: [sock connectedHost] port: [sock connectedPort]];
	//[self logInfo:FORMAT(@"Client Disconnected: %@:%hu", [sock connectedHost], [sock connectedPort])];
	
}

- (void)onSocketDidDisconnect:(GCDAsyncSocket *)sock
{
	NSLog(@"Entering 'onSocket.onSocketDidDisconnect'.");
	[connectedSockets removeObject:sock];
	
	if ([theDelegate respondsToSelector:@selector(updateConnectedSockets:)])
		[theDelegate updateConnectedSockets: [connectedSockets count]];
	
    
	//[connCounter setStringValue: FORMAT(@"%hu", [connectedSockets count])];
}

@end
