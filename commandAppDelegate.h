//
//  commandAppDelegate.h
//  command
//
//  Created by wantez on 19/07/10.
//  Copyright 2010 Ivan Rodriguez Murillo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "AsyncSocket.h"

#include <assert.h>
#include <CoreServices/CoreServices.h>
#include <mach/mach.h>
#include <mach/mach_time.h>
#include <unistd.h>

@class AsyncSocket;

#if (MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_5)
@interface commandAppDelegate : NSObject  
#else
@interface commandAppDelegate : NSObject <NSApplicationDelegate> 
#endif


{
    NSWindow *window;
	IBOutlet id logView;
	
	IBOutlet id connCounter;
	IBOutlet id portField;
	AsyncSocket *listenSocket;
	NSMutableArray *connectedSockets;
	
	BOOL isRunning;
	IBOutlet id startStopButton;
	
	 NSTimer *repeatingTimer;
	NSUInteger timerCount;
	uint64_t    start;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) NSTimer *repeatingTimer;
@property NSUInteger timerCount;
@property uint64_t    start;

- (IBAction) startStop:(id)sender;
- (IBAction) sendStartCommand:(id)sender;
- (IBAction) sendStopCommand:(id)sender;

- (void)startRepeatingTimer;
//- (void)timerFireMethod:(NSTimer*)theTimer;

- (NSDictionary *)userInfo;
@end
