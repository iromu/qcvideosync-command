//
//  commandAppDelegate.m
//  command
//
//  Created by wantez on 19/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "commandAppDelegate.h"


#define WELCOME_MSG  0
#define ECHO_MSG     1
#define WARNING_MSG  2

#define NO_TIMEOUT -1
#define READ_TIMEOUT 15.0
#define READ_TIMEOUT_EXTENSION 10.0

#define FORMAT(format, ...) [NSString stringWithFormat:(format), ##__VA_ARGS__]

@interface commandAppDelegate (PrivateAPI)
- (void)logError:(NSString *)msg;
- (void)logInfo:(NSString *)msg;
- (void)logMessage:(NSString *)msg;
- (void)stopRepeatingTimer;
- (void)broadcastTick:(NSUInteger)tick;
@end


@implementation commandAppDelegate

@synthesize window;
@synthesize repeatingTimer;
@synthesize timerCount;
@synthesize start;


- (id)init
{
	NSLog(@"Entering 'init'.");
	
	if((self = [super init]))
	{
		NSLog(@"Entering 'init.setup'.");
		listenSocket = [[AsyncSocket alloc] initWithDelegate:self];
		connectedSockets = [[NSMutableArray alloc] initWithCapacity:1];
		
		isRunning = NO;
	}
	return self;
}

- (void)broadcastCommand:(NSString *) cmd {
	if ([connectedSockets count]>0) {
		double CurrentTime = [[NSDate date] timeIntervalSince1970];
		NSString *msg = [NSString stringWithFormat:@"CMD %@ %f\r\n", cmd,CurrentTime];
		NSData *msgData = [msg dataUsingEncoding:NSUTF8StringEncoding];
		for (AsyncSocket *sock in connectedSockets) {
			[sock writeData:msgData withTimeout:NO_TIMEOUT tag:ECHO_MSG];
		}
	}
}

- (void)windowWillClose:(NSNotification *)notification 
{
	NSLog(@"Entering 'windowWillClose'.");
	[NSApp terminate:self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSLog(@"Entering 'applicationDidFinishLaunching'.");

	
	// Advanced options - enable the socket to contine operations even during modal dialogs, and menu browsing
	[listenSocket setRunLoopModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
		NSLog(@"Ready");
	//[mTextView setString: @"Server Waiting"];	
	
	//[[[mTextView textStorage] mutableString] appendString: @"Server Waiting"];
	
	//connectedSockets = [[NSMutableArray alloc] initWithCapacity:1];
	
	
	
	
/*	struct sockaddr_in sin;
    int sock, yes = 1;
    
    CFRunLoopSourceRef source;
    
    sock = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
    memset(&sin, 0, sizeof(sin));
	
    sin.sin_family = AF_INET;
    sin.sin_port = htons(8888);
    setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, 
			   &yes, sizeof(yes));
    setsockopt(sock, SOL_SOCKET, SO_REUSEPORT, 
			   &yes, sizeof(yes));
    bind(sock, (struct sockaddr *)&sin, sizeof(sin));
    listen(sock, 5);
    
    s = CFSocketCreateWithNative(NULL, sock, 
								 kCFSocketAcceptCallBack, 
								 acceptConnection, 
								 NULL);
    
    source = CFSocketCreateRunLoopSource(NULL, s, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source,
					   kCFRunLoopDefaultMode);
    CFRelease(source);
    CFRelease(s);
	

	//[s scheduleInRunLoop:[NSRunLoop currentRunLoop]
//					  forMode:NSDefaultRunLoopMode];
    //CFRunLoopRun();
	*/
	
}

- (void)scrollToBottom
{
	NSScrollView *scrollView = [logView enclosingScrollView];
	NSPoint newScrollOrigin;
	
	if ([[scrollView documentView] isFlipped])
		newScrollOrigin = NSMakePoint(0.0F, NSMaxY([[scrollView documentView] frame]));
	else
		newScrollOrigin = NSMakePoint(0.0F, 0.0F);
	
	[[scrollView documentView] scrollPoint:newScrollOrigin];
}


- (void)logError:(NSString *)msg
{
	NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
	[attributes setObject:[NSColor redColor] forKey:NSForegroundColorAttributeName];
	
	NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
	[as autorelease];
	
	[[logView textStorage] appendAttributedString:as];
	[self scrollToBottom];
}

- (void)logInfo:(NSString *)msg
{
	NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
	[attributes setObject:[NSColor purpleColor] forKey:NSForegroundColorAttributeName];
	
	NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
	[as autorelease];
	
	[[logView textStorage] appendAttributedString:as];
	[self scrollToBottom];
}

- (void)logMessage:(NSString *)msg
{
	NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
	[attributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
	
	NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
	[as autorelease];
	
	[[logView textStorage] appendAttributedString:as];
	[self scrollToBottom];
}

- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket
{
	NSLog(@"Entering 'onSocket.didAcceptNewSocket'.");
	[connectedSockets addObject:newSocket];
	[connCounter setStringValue: FORMAT(@"%hu", [connectedSockets count])];
	
}


- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
	NSLog(@"Entering 'onSocket.didConnectToHost'.");
	[self logInfo:FORMAT(@"Accepted client %@:%hu", host, port)];
	
	
	NSString *welcomeMsg = @"Welcome to the Video Server\r\n";
	NSData *welcomeData = [welcomeMsg dataUsingEncoding:NSUTF8StringEncoding];
	
	[sock writeData:welcomeData withTimeout:NO_TIMEOUT tag:WELCOME_MSG];
	
	[sock readDataToData:[AsyncSocket CRLFData] withTimeout:NO_TIMEOUT tag:0];
}

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
	//if(tag == ECHO_MSG)
	//{
		[sock readDataToData:[AsyncSocket CRLFData] withTimeout:NO_TIMEOUT tag:0];
	//}
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	NSLog(@"Entering 'onSocket.didReadData'.");
	NSData *strData = [data subdataWithRange:NSMakeRange(0, [data length] - 2)];
	NSString *msg = [[[NSString alloc] initWithData:strData encoding:NSUTF8StringEncoding] autorelease];
	if(msg)
	{
		[self logMessage:msg];
	}
	else
	{
		[self logError:@"Error converting received data into UTF-8 String"];
	}
	
	// Even if we were unable to write the incoming data to the log,
	// we're still going to echo it back to the client.
	[sock writeData:data withTimeout:NO_TIMEOUT tag:ECHO_MSG];
}

/**
 * This method is called if a read has timed out.
 * It allows us to optionally extend the timeout.
 * We use this method to issue a warning to the user prior to disconnecting them.
 **/
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
	[self logInfo:FORMAT(@"Client Disconnected: %@:%hu", [sock connectedHost], [sock connectedPort])];
	
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
	NSLog(@"Entering 'onSocket.onSocketDidDisconnect'.");
	[connectedSockets removeObject:sock];
	[connCounter setStringValue: FORMAT(@"%hu", [connectedSockets count])];
}

- (IBAction)startStop:(id)sender
{
	if(!isRunning)
	{
		int port = [portField intValue];
		
		if(port < 0 || port > 65535)
		{
			port = 0;
		}
		
		NSError *error = nil;
		if(![listenSocket acceptOnPort:port error:&error])
		{
			[self logError:FORMAT(@"Error starting server: %@", error)];
			return;
		}
		
		[self logInfo:FORMAT(@"Server started on port %hu", [listenSocket localPort])];
		isRunning = YES;
		//[self startRepeatingTimer];
		
		[portField setEnabled:NO];
		[startStopButton setTitle:@"Stop"];
	}
	else
	{
		// Stop accepting connections
		[listenSocket disconnect];
		
		// Stop any client connections
		int i;
		for(i = 0; i < [connectedSockets count]; i++)
		{
			// Call disconnect on the socket,
			// which will invoke the onSocketDidDisconnect: method,
			// which will remove the socket from the list.
			[[connectedSockets objectAtIndex:i] disconnect];
		}
		
		[self logInfo:@"Stopped server"];
		isRunning = false;
		//[self stopRepeatingTimer];
		
		[portField setEnabled:YES];
		[startStopButton setTitle:@"Start"];
	}
}

- (IBAction) sendStartCommand:(id)sender
{
	NSLog(@"Entering 'sendStartCommand'.");
	[self logInfo: @"Server sent START"];	
	//[[[logView textStorage] mutableString] appendString: @"Server send StartCommand\n"];
	[self broadcastCommand:@"START"];
}

- (IBAction) sendStopCommand:(id)sender
{
	NSLog(@"Entering 'sendStopCommand'.");
	[self logInfo: @"Server sent STOP"];	
	[self broadcastCommand:@"STOP"];
}

- (void)startRepeatingTimer {
	NSLog(@"Entering 'startRepeatingTimer'.");
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:5
						target:self selector:@selector(countedtargetMethod:)
						userInfo:[self userInfo] repeats:YES];
    self.repeatingTimer = timer;
	self.start = mach_absolute_time();
}

- (NSDictionary *)userInfo {
    return [NSDictionary dictionaryWithObject:[NSDate date] forKey:@"StartDate"];
}

- (void)targetMethod:(NSTimer*)theTimer {
	
    NSDate *startDate = [[theTimer userInfo] objectForKey:@"StartDate"];
    NSLog(@"Timer started on %@", startDate);
}

- (void)invocationMethod:(NSDate *)date {
	
    NSLog(@"Invocation for timer started on %@", date);
}

- (void)countedtargetMethod:(NSTimer*)theTimer {
	
	[self broadcastTick: timerCount];
	/*
    NSDate *startDate = [[theTimer userInfo] objectForKey:@"StartDate"];
	//NSDate *reftime = [NSDate date];
	
	//double howmanysecondselapsed = [[NSDate startDate] timeIntervalSinceDate:reftime];
	
	//NSDate *reftime = [NSDate date];
	//double howmanysecondselapsed = [[NSDate date] timeIntervalSince: startDate];
	NSDate *now = [[NSDate alloc] init];
	
	//NSDate *reftime = [NSDate date];
	double howmanysecondselapsed = [startDate timeIntervalSinceNow];
	//double howmanysecondselapsed = [startDate timeIntervalSinceDate: reftime];
	
	uint64_t end = mach_absolute_time();
	uint64_t elapsed = end - start;
	Nanoseconds elapsedNano = AbsoluteToNanoseconds( *(AbsoluteTime *) &elapsed );
	uint64_t nanos = * (uint64_t *) &elapsedNano;
	
    NSLog(@"%@ :: Timer started on %@; fire count %d, elapsed seconds %f nanos %f",now, startDate, timerCount,howmanysecondselapsed, nanos);
	*/
	 timerCount++;
	
	//[startDate release];
	//[now release];
	//[howmanysecondselapsed release];
	//[end release];
	//[elapsed release];
	//[elapsedNano release];
	//[nanos release];
    //if (timerCount > 3) {
    //    [theTimer invalidate];
    //}
}
- (void)stopRepeatingTimer {
	NSLog(@"Entering 'stopRepeatingTimer'.");
    [repeatingTimer invalidate];
    self.repeatingTimer = nil;
	timerCount=0;
}


- (void)broadcastTick:(NSUInteger) tick {
	if ([connectedSockets count]>0) {
		
		//NSLog(@"fire count %d",tick);
		
		double CurrentTime = [[NSDate date] timeIntervalSince1970];
		for (AsyncSocket *sock in connectedSockets) {
			
			//NSString *warningMsg = @"Tick ";
			//NSString *msg = [NSString stringWithFormat:@"%@%d %f\r\n", warningMsg, tick, CurrentTime];
			NSString *msg = [NSString stringWithFormat:@"Tick %f\r\n", CurrentTime];
			
			
			NSData *msgData = [msg dataUsingEncoding:NSUTF8StringEncoding];
			
			[sock writeData:msgData withTimeout:NO_TIMEOUT tag:ECHO_MSG];
			
		}
	}
}


@end
