//
//  SocketController.m
//  command
//
//  Created by wantez on 03/08/10.
//  Copyright 2010 Ivan Rodriguez Murillo. All rights reserved.
//

#import "SocketController.h"
#import "SimplePingController.h"
 
#import "common.h"
#include <mach/mach.h>
#include <mach/mach_time.h>

#define WELCOME_MSG 0
#define ECHO_MSG    1
#define WARNING_MSG 2
#define TICK_MSG    3
#define CMD_MSG     4


#define NO_TIMEOUT -1
#define READ_TIMEOUT 15.0
#define READ_TIMEOUT_EXTENSION 10.0

// Log levels: off, error, warn, info, verbose
#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_INFO;
#else
static const int ddLogLevel = LOG_LEVEL_WARN;
#endif

@interface SocketController (PrivateAPI)
- (void) ping:(GCDAsyncSocket *)sock;
- (BOOL) acceptOnPortString:(NSString *)str;
- (NSString *) getPeerName:(GCDAsyncSocket *)sock;
- (NSString *) getHostName:(GCDAsyncSocket *)sock;
@end

@implementation SocketController

@synthesize theDelegate;
@synthesize running;

- (id) initWithDelegate:(id<SocketControllerDelegate>)delegate
{
    self = [super init];
    [self setTheDelegate:delegate];

    //pingController = [[SimplePingController alloc]init];
    DDLogVerbose (@"SocketController.initWithDelegate :: Creating Server socket.");
    serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];

    connectedSockets = [[NSMutableArray alloc] initWithCapacity:1];
    running = NO;

    return self;
}


- (void) stopServer
{
    [netService stop];

    // Stop accepting connections
    [serverSocket disconnect];

    // Stop any client connections
    int i;
    for (i = 0; i < [connectedSockets count]; i++) {
        [[connectedSockets objectAtIndex:i] disconnect];
    }
    running = NO;
}


- (BOOL) startServer:(NSString *)port
{
    return [self acceptOnPortString:port];
}


- (void)broadcastCommand:(NSString *)cmd
{

    if ([connectedSockets count] > 0) {
        NSString *msg = [NSString stringWithFormat:@"CMD %@\r\n", cmd];
        NSData *msgData = [msg dataUsingEncoding:NSUTF8StringEncoding];
        for (GCDAsyncSocket *sock in connectedSockets) {
            [sock writeData:msgData withTimeout:NO_TIMEOUT tag:CMD_MSG];
        }
    }
}


- (void)ping
{
    if ([connectedSockets count] > 0) {
        for (GCDAsyncSocket *sock in connectedSockets) {
            [self ping:sock];
        }
    }
}


- (BOOL) acceptOnPortString:(NSString *)str
{
    UInt16 port = [str intValue];

    NSError *err = nil;
    if ([serverSocket acceptOnPort:port error:&err]) {
        DDLogVerbose (@"Waiting for connections on port %u.", port);
        running = YES;

        netService = [[NSNetService alloc] initWithDomain:@"local."
                                                     type:@"_QCVideoSync._tcp."
                                                     name:@""
                                                     port:port];

        [netService setDelegate:self];
        [netService publish];

        return YES;
    }else {
        DDLogError (@"Cannot accept connections on port %u. Error domain %@ code %ld (%@). Exiting.", port, [err domain], [err code],
                    [err localizedDescription]);
        return NO;
    }
}


- (void)netServiceDidPublish:(NSNetService *)ns
{
    DDLogVerbose(@"Bonjour Service Published: domain(%@) type(%@) name(%@) port(%i)",
                 [ns domain], [ns type], [ns name], (int)[ns port]);
}


- (void)netService:(NSNetService *)ns didNotPublish:(NSDictionary *)errorDict
{
    DDLogVerbose(@"Failed to Publish Service: domain(%@) type(%@) name(%@) - %@",
                 [ns domain], [ns type], [ns name], errorDict);
}


#pragma mark GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket;
{
    NSString * peer = [self getPeerName:newSocket];
    DDLogVerbose(@"socket: %@ didAcceptNewSocket: %@", [self getHostName:sock], peer);
    [connectedSockets addObject:newSocket];

    if ([theDelegate respondsToSelector:@selector(updateConnectedSockets:)]) {
        [theDelegate updateConnectedSockets:[connectedSockets count]];
    }

    DDLogInfo(@"Accepted client %@", peer);
    NSString * welcomeMsg = nil;
    if ([theDelegate respondsToSelector:@selector(didAcceptNewPeer:)]) {
        welcomeMsg = [theDelegate didAcceptNewPeer:peer];
    }

    if (welcomeMsg) {
        NSString *msg = [NSString stringWithFormat:@"CMD %@\r\n", welcomeMsg];
        NSData *welcomeData = [msg dataUsingEncoding:NSUTF8StringEncoding];
        [newSocket writeData:welcomeData withTimeout:NO_TIMEOUT tag:WELCOME_MSG];
    }

    [newSocket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:NO_TIMEOUT tag:0];

    //[self ping: newSocket];
}
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag;
{
    if (tag == TICK_MSG) {
        [sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:NO_TIMEOUT tag:0];
    }
}
//Raw mach_absolute_times going in, difference in seconds out
double subtractTimes( uint64_t endTime, uint64_t startTime )
{
    uint64_t difference = endTime - startTime;
    static double conversion = 0.0;

    if (conversion == 0.0) {
        mach_timebase_info_data_t info;
        kern_return_t err = mach_timebase_info( &info );

        //Convert the timebase into seconds
        if (err == 0) {
            conversion = 1e-9 * (double) info.numer / (double) info.denom;
        }
    }

    return conversion * (double) difference;
}


- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag;
{
    uint64_t stop = mach_absolute_time();
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    if (str) {
        if ([str hasPrefix:@"Tick "]) {
            NSString * startS = [str substringFromIndex:5];
            uint64_t start = strtoull([startS UTF8String], NULL, 0);
            double lag = subtractTimes(stop, start) * 1000.0 / 2;

            NSString * peer = [self getPeerName:sock];
            if ([theDelegate respondsToSelector:@selector(updatePeer:withLag:)]) {
                [theDelegate updatePeer:peer withLag:lag];
            }
        }else {
            DDLogError(@"Unknow response from peer");
        }
    }else {
        DDLogError(@"Error converting received data into UTF-8 String");
    }
}

- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag
   elapsed:(NSTimeInterval)elapsed
   bytesDone:(NSUInteger)length
{
    DDLogVerbose(@"Entering 'onSocket.shouldTimeoutReadWithTag'.");
    if (elapsed <= READ_TIMEOUT) {
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
    if ([theDelegate respondsToSelector:@selector(onSocketwillDisconnectWithError:port:)]) {
        [theDelegate onSocketwillDisconnectWithError:[sock connectedHost] port:[sock connectedPort]];
    }
}


- (void)socketDidCloseReadStream:(GCDAsyncSocket *)sock
{
    DDLogVerbose(@"Entering 'onSocket.socketDidCloseReadStream'.");
}


- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    DDLogVerbose(@"Entering 'onSocket.onSocketDidDisconnect'.");

    if ([theDelegate respondsToSelector:@selector(onSocketwillDisconnectWithError:port:)]) {
        [theDelegate onSocketwillDisconnectWithError:[sock connectedHost] port:[sock connectedPort]];
    }


    [connectedSockets removeObject:sock];

    if ([theDelegate respondsToSelector:@selector(updateConnectedSockets:)]) {
        [theDelegate updateConnectedSockets:[connectedSockets count]];
    }
}


#pragma mark -

#pragma mark PrivateAPI
- (void) ping:(GCDAsyncSocket *)sock
{
    uint64_t start = mach_absolute_time();
    NSString *tick = FORMAT(@"Tick %llu\r\n", start);


    NSData *tickData = [tick dataUsingEncoding:NSUTF8StringEncoding];
    [sock writeData:tickData withTimeout:NO_TIMEOUT tag:TICK_MSG];
    
    DDLogVerbose(@"Ping %@",tick);
}


- (NSString *) getPeerName:(GCDAsyncSocket *)sock
{
    return [NSString stringWithFormat:@"%@:%u",
            [sock connectedHost],
            [sock connectedPort]];
}


- (NSString *) getHostName:(GCDAsyncSocket *)sock
{
    return [NSString stringWithFormat:@"%@:%u",
            [sock localHost],
            [sock localPort]];
}


#pragma mark -
@end
