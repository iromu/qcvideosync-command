//
//  AppDelegate.m
//  command
//
//  Created by wantez on 03/08/10.
//  Copyright 2010 Ivan Rodriguez Murillo. All rights reserved.
//

#import "AppDelegate.h"
#import "CommandWindowController.h"

@implementation AppDelegate

@synthesize listenSocket;
#pragma mark -
#pragma mark Application lifecycle


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)sender
{
	NSLog(@"Entering 'AppDelegate.applicationShouldTerminateAfterLastWindowClosed'.");
	

	return YES;
}


- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	NSLog(@"Entering 'AppDelegate.applicationShouldTerminate'.");
	
	[cmdWindowController applicationShouldTerminate: sender];
	//if (![managedObjectContext hasChanges]) return NSTerminateNow;
    return NSTerminateNow;
}
- (void)applicationDidFinishLaunching:(NSNotification*)notification
{
	NSLog(@"Entering 'AppDelegate.applicationDidFinishLaunching'.");
	
	cmdWindowController = [[CommandWindowController alloc] initWithWindowNibName:@"CommandWindow"];
	
	cmdWindowController.theDelegate = self;
	
	midiController = [[MIDIController alloc] initWithDelegate: cmdWindowController];
	[midiController updateMIDISources];
	
	//[inputPopUp addItemWithTitle:[input displayName]];
	
	listenSocket = [[SocketController alloc] initWithDelegate: cmdWindowController];
    
    
	
	[cmdWindowController showWindow:self];
	
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(handleStartScriptCommandSent:) 
                                                 name:@"startScriptCommandSent" object:nil];
    
    
	//[self managedObjectContext ];
}
- (void)handleStartScriptCommandSent:(NSNotification *)note
{
    debug(@"handleStartScriptCommandSent selector");
    [self performSelectorOnMainThread:@selector(mainThread_handleStartScriptCommandSent:) withObject:note waitUntilDone:NO];
}

- (void)mainThread_handleStartScriptCommandSent:(NSNotification *)note
{
    debug(@"mainThread_handleStartScriptCommandSent selector");
   // [self preVisualization: kPreTime];
    
}
- (void)dealloc {
    debug(@"Entering 'AppDelegate.dealloc'.");
	/*
    [managedObjectContext_ release];
    [managedObjectModel_ release];
    [persistentStoreCoordinator_ release];
    */
}
- (IBAction)openSettings:(id)sender
{
	NSLog(@"Entering 'AppDelegate.openSettings'.");
    [cmdWindowController openSettings: self];
}
- (void)updateMIDISources
{
	NSLog(@"Entering 'AppDelegate.updateMIDISources'.");
    [midiController updateMIDISources];
}


#pragma mark -


@end