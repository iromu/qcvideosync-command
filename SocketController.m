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

// Log levels: off, error, warn, info, verbose
#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#endif

@interface SocketController (PrivateAPI)
-(void) ping: (GCDAsyncSocket* )sock;
- (BOOL) acceptOnPortString:(NSString *)str;
-(NSString*) getPeerName:(GCDAsyncSocket *)sock;
-(NSString*) getHostName:(GCDAsyncSocket *)sock;
@end

@implementation SocketController

@synthesize theDelegate;
@synthesize running;

-(id) initWithDelegate: (id<SocketControllerDelegate>) delegate {
	self = [super init];
	[self setTheDelegate: delegate];
    

    
    
    pingController = [[SimplePingController alloc]init];
	DDLogVerbose (@"SocketController.initWithDelegate :: Creating Server socket.");
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
		DDLogVerbose (@"Waiting for connections on port %u.", port);
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
		
		DDLogError (@"Cannot accept connections on port %u. Error domain %@ code %ld (%@). Exiting.", port, [err domain], [err code], [err localizedDescription]);
		return NO;
		//exit(1);
	}
}


- (void)netServiceDidPublish:(NSNetService *)ns
{
	DDLogVerbose(@"Bonjour Service Published: domain(%@) type(%@) name(%@) port(%i)",
                 [ns domain], [ns type], [ns name], (int)[ns port]);
}

- (void)netService:(NSNetService *)ns didNotPublish:(NSDictionary *)errorDict
{
	// Override me to do something here...
	// 
	// Note: This method in invoked on our bonjour thread.
	
	DDLogVerbose(@"Failed to Publish Service: domain(%@) type(%@) name(%@) - %@",
                 [ns domain], [ns type], [ns name], errorDict);
}
#pragma mark GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket;
{
    NSString* peer = [self getPeerName: newSocket];
	DDLogError(@"socket: %@ didAcceptNewSocket: %@", [self getHostName: sock], peer);
	[connectedSockets addObject:newSocket];	
	
	if ([theDelegate respondsToSelector:@selector(updateConnectedSockets:)])
		[theDelegate updateConnectedSockets: [connectedSockets count]];	
    
    DDLogInfo(@"Accepted client %@", peer);
	NSString * welcomeMsg=nil;//= @"Welcome to the Video Server\r\n";
	if ([theDelegate respondsToSelector:@selector(didAcceptNewPeer:)])
		welcomeMsg = [theDelegate didAcceptNewPeer: peer];	
	
	if (welcomeMsg) {
		NSString *msg = [NSString stringWithFormat:@"CMD %@\r\n", welcomeMsg];
		NSData *welcomeData = [msg dataUsingEncoding:NSUTF8StringEncoding];
		[newSocket writeData:welcomeData withTimeout:NO_TIMEOUT tag:WELCOME_MSG];
	}
    
    
	
	[newSocket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:NO_TIMEOUT tag:0];	
    
    [self ping: newSocket];
}



- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag;
{
	if(tag == TICK_MSG)
	{
	[sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:NO_TIMEOUT tag:0];
	}
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag;
{
	DDLogVerbose(@"Entering 'onSocket.didReadData'.");
    
	//NSData *strData = [data subdataWithRange:NSMakeRange(0, [data length] - 2)];
    //	NSString *msg = [[[NSString alloc] initWithData:strData encoding:NSUTF8StringEncoding] autorelease];
	NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
	
    if(str)
    {
        //[self logMessage:msg];
        //DDLogVerbose(@"%@ from %@", str,sock);
        if([str hasPrefix: @"Tick "]){
            double CurrentTime = [[NSDate date] timeIntervalSince1970];
            double lag = (CurrentTime - [[str substringFromIndex:5] doubleValue] ) * 1000.00;
            NSString* peer = [self getPeerName:sock];
            DDLogVerbose(@"lag: %f ms from %@", lag, peer);
            if ([theDelegate respondsToSelector:@selector(updatePeer:withLag:)])
                [theDelegate updatePeer: peer withLag: lag];
            
           // double CurrentTime = [[NSDate date] timeIntervalSince1970];
           // NSString *tick = FORMAT(@"Tick %f\r\n", CurrentTime);
            //NSData *tickData = [tick dataUsingEncoding:NSUTF8StringEncoding];
            //[sock writeData:tickData withTimeout:NO_TIMEOUT tag:TICK_MSG];
            //[sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:NO_TIMEOUT tag:0];
            [self ping:sock];
        }
        else {
            DDLogError(@"Unknow response from peer");
        }
    }
    else
    {
        DDLogError(@"Error converting received data into UTF-8 String");
        
    }
	
	// Even if we were unable to write the incoming data to the log,
	// we're still going to echo it back to the client.
	//[sock writeData:data withTimeout:NO_TIMEOUT tag:ECHO_MSG];
}

- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length
{
	DDLogVerbose(@"Entering 'onSocket.shouldTimeoutReadWithTag'.");
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
	DDLogVerbose(@"Entering 'onSocket.willDisconnectWithError'.");
	if ([theDelegate respondsToSelector:@selector(onSocketwillDisconnectWithError:port:)])
		[theDelegate onSocketwillDisconnectWithError: [sock connectedHost] port: [sock connectedPort]];
	//[self logInfo:FORMAT(@"Client Disconnected: %@:%hu", [sock connectedHost], [sock connectedPort])];
	
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
	DDLogVerbose(@"Entering 'onSocket.onSocketDidDisconnect'.");
    
    if ([theDelegate respondsToSelector:@selector(onSocketwillDisconnectWithError:port:)])
		[theDelegate onSocketwillDisconnectWithError: [sock connectedHost] port: [sock connectedPort]];
	
    
	[connectedSockets removeObject:sock];
	
	if ([theDelegate respondsToSelector:@selector(updateConnectedSockets:)])
		[theDelegate updateConnectedSockets: [connectedSockets count]];
	
    
	//[connCounter setStringValue: FORMAT(@"%hu", [connectedSockets count])];
}

#pragma mark -

#pragma mark PrivateAPI
-(void) ping: (GCDAsyncSocket* )sock
{
    double CurrentTime = [[NSDate date] timeIntervalSince1970];
    NSString *tick = FORMAT(@"Tick %f\r\n", CurrentTime);
    NSData *tickData = [tick dataUsingEncoding:NSUTF8StringEncoding];
	[sock writeData:tickData withTimeout:NO_TIMEOUT tag:TICK_MSG];
}

-(NSString*) getPeerName:(GCDAsyncSocket *)sock
{	
    return [NSString stringWithFormat: @"%@:%u",
            [sock connectedHost],
            [sock connectedPort]];
}
-(NSString*) getHostName:(GCDAsyncSocket *)sock
{	
    return [NSString stringWithFormat: @"%@:%u",
            [sock localHost],
            [sock localPort]];
}
#pragma mark -
@end
