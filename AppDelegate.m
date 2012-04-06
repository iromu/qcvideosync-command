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
    [self preVisualization: kPreTime];
    
}
- (void)dealloc {
    NSLog(@"Entering 'AppDelegate.dealloc'.");
	/*
    [managedObjectContext_ release];
    [managedObjectModel_ release];
    [persistentStoreCoordinator_ release];
    */
	[midiController release];
	[listenSocket release];
	[cmdWindowController release];
    [super dealloc];
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
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
/*
- (NSManagedObjectContext *)managedObjectContext {
    NSLog(@"Entering 'AppDelegate.managedObjectContext'.");
    if (managedObjectContext_ != nil) {
        return managedObjectContext_;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext_ = [[NSManagedObjectContext alloc] init];
        [managedObjectContext_ setPersistentStoreCoordinator:coordinator];
    }
    return managedObjectContext_;
}


*/
/**
 Creates, retains, and returns the managed object model for the application 
 by merging all of the models found in the application bundle.
 */
/*
- (NSManagedObjectModel *)managedObjectModel {
	
    if (managedObjectModel_) return managedObjectModel_;
	
    managedObjectModel_ = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel_;
}
*/
/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
/*
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	NSLog(@"Entering 'AppDelegate.persistentStoreCoordinator'.");
    if (persistentStoreCoordinator_ != nil) {
        return persistentStoreCoordinator_;
    }
    
    NSURL *storeURL = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"command.sqlite"]];
    
    NSError *error = nil;
    persistentStoreCoordinator_ = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
       /* NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return persistentStoreCoordinator_;
}
*/
#pragma mark -
#pragma mark Application's Documents directory

/**
 Returns the path to the application's Documents directory.
 */
/*
- (NSString *)applicationDocumentsDirectory {
	NSLog(@"Entering 'AppDelegate.applicationDocumentsDirectory'.");
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}
*/



@end