//
//  CommandWindowController.m
//  command
//
//  Created by wantez on 03/08/10.
//  Copyright 2010 Ivan Rodriguez Murillo. All rights reserved.
//

#import "CommandWindowController.h"
#include <mach/mach.h>
#include <mach/mach_time.h>

// Log levels: off, error, warn, info, verbose
#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

#define kUse_Bindings_By_Code	1

@interface CommandWindowController (PrivateAPI)
- (void)logError:(NSString *)msg;
- (void)logInfo:(NSString *)msg;
- (void)logMessage:(NSString *)msg;
- (void)startRepeatingTimer;
- (void)stopRepeatingTimer;
- (void)loadSettings;
- (void)applySettings;
- (void)saveSettings;
- (void) sendPLCommand: (NSUInteger) number;
- (void)setNote:(Byte)note forPlayList: (int) number;
- (void)setNoteControls;
@end

@implementation CommandWindowController

@synthesize nextTimer;
@synthesize updateIndicatorTimer;
@synthesize start;
@synthesize theDelegate;

NSDateFormatter* dateFormat ;
BOOL fullscreen;

- initWithPath:(NSString *)newPath
{
	DDLogVerbose(@"Entering 'CommandWindowController.initWithPath'.");
    return [super initWithWindowNibName:@"CommandWindow"];
}


/**
 Implementation of dealloc, to release the retained variables.
 */

- (void)dealloc {
	DDLogVerbose(@"Entering 'CommandWindowController.dealloc'.");
	
	
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	DDLogVerbose(@"Entering 'CommandWindowController.applicationShouldTerminate'.");
	
	[self saveSettings];
	
    if (!managedObjectContext) return NSTerminateNow;
	
    if (![managedObjectContext commitEditing]) {
        DDLogVerbose(@"%@:%s unable to commit editing to terminate", [self class], _cmd);
        return NSTerminateCancel;
    }
	
    if (![managedObjectContext hasChanges]) return NSTerminateNow;
	
    NSError *error = nil;
    if (![managedObjectContext save:&error]) {
		DDLogVerbose(@"Entering 'CommandWindowController.applicationShouldTerminate'. ERROR");
		
        // This error handling simply presents error information in a panel with an 
        // "Ok" button, which does not include any attempt at error recovery (meaning, 
        // attempting to fix the error.)  As a result, this implementation will 
        // present the information to the user and then follow up with a panel asking 
        // if the user wishes to "Quit Anyway", without saving the changes.
		
        // Typically, this process should be altered to include application-specific 
        // recovery steps.  
		
        BOOL result = [sender presentError:error];
        if (result) return NSTerminateCancel;
		
        NSString *question = NSLocalizedString(@"Could not save changes while quitting.  Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];
		
        NSInteger answer = [alert runModal];
        alert = nil;
        
        if (answer == NSAlertAlternateReturn) return NSTerminateCancel;
		
    }
	DDLogVerbose(@"Entering 'CommandWindowController.applicationShouldTerminate'. SAVED");
	
    return NSTerminateNow;
	
}

- (void)awakeFromNib
{

    
	DDLogVerbose(@"Entering 'CommandWindowController.awakeFromNib'.");
	
	[self loadSettings];
    
	currentPL = 1;
	nextIndex=1;
	//Format Date
	dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateFormat: @"yyyy-MM-dd HH:mm:ss"]; // 2009-02-01 19:50:41 PST
    
	int intervalInt = [timeInterval intValue];
	[indicator setMaxValue: intervalInt];
	[indicator setNumberOfMajorTickMarks: 4];
	[indicator setNumberOfTickMarks: intervalInt];
	
	[self startStop:nil];
	
#if kUse_Bindings_By_Code
	NSTableColumn *macColumn = [myTableView tableColumnWithIdentifier:@"mac"];
	[macColumn bind:@"value" toObject:myContentArray withKeyPath:@"arrangedObjects.mac" options:nil];
	
	NSTableColumn *delayColumn = [myTableView tableColumnWithIdentifier:@"delay"];
	[delayColumn bind:@"value" toObject:myContentArray withKeyPath:@"arrangedObjects.delay" options:nil];
    
	NSDictionary *valueOptionsDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithBool:YES], @"NSAllowsEditingMultipleValuesSelection",
                                      [NSNumber numberWithBool:YES], @"NSConditionallySetsEditable",
                                      [NSNumber numberWithBool:YES], @"NSRaisesForNotApplicableKeys",
                                      nil];
	[[myFormFields cellAtIndex: 0] bind:@"value" toObject:myContentArray withKeyPath:@"selection.mac" options:valueOptionsDict];
	[[myFormFields cellAtIndex: 1] bind:@"value" toObject:myContentArray withKeyPath:@"selection.delay" options:valueOptionsDict];
#endif
    
    // start listening for selection changes in our NSTableView's array controller
	[myContentArray addObserver: self
                     forKeyPath: @"selectionIndexes"
                        options: NSKeyValueObservingOptionNew
                        context: NULL];
	
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	DDLogVerbose(@"Table section changed: keyPath = %@, %@", keyPath, [object selectionIndexes]);
}
-(void)loadSettings{
	DDLogVerbose(@"Entering 'loadSettings'.");
	
	settingsModel = [[SettingsModel alloc]init];
	
	NSManagedObjectContext *context=[self managedObjectContext];
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription 
						entityForName:@"settings" 
						inManagedObjectContext:context]];
	
	NSArray *results = [context executeFetchRequest:request error:nil];
    
	NSManagedObject *object=[results lastObject];
	if ([results count] == 0) {
		DDLogVerbose(@"Insert");
		
		object=[NSEntityDescription	insertNewObjectForEntityForName:@"settings"
											 inManagedObjectContext:context];	
	}
    
	settingsModel.port =		[object valueForKey:@"port"] ;
	settingsModel.interval =	[object valueForKey:@"interval"] ;
	settingsModel.fullscreen =	[object valueForKey:@"fullscreen" ];
	
	settingsModel.pl1Note = [object valueForKey:@"pl1Note"] ;
	settingsModel.pl2Note = [object valueForKey:@"pl2Note"];
	settingsModel.pl3Note = [object valueForKey:@"pl3Note" ];	
	
	[self applySettings];
    
}



-(void)saveSettings{
	DDLogVerbose(@"Entering 'saveSettings'.");
	
	NSManagedObjectContext *context=[self managedObjectContext];
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription 
						entityForName:@"settings" 
						inManagedObjectContext:context]];
	
	NSArray *results = [context executeFetchRequest:request error:nil];
	
	NSManagedObject *object=[results lastObject];
	
	[object setValue:settingsModel.port forKey:@"port"];
	[object setValue:settingsModel.interval forKey:@"interval"];
	[object setValue:settingsModel.fullscreen forKey:@"fullscreen"];
	
	[object setValue:settingsModel.pl1Note forKey:@"pl1Note"];
	[object setValue:settingsModel.pl2Note forKey:@"pl2Note"];
	[object setValue:settingsModel.pl3Note forKey:@"pl3Note"];
	
	[context save:nil];
	
}

-(void)applySettings{
	DDLogVerbose(@"Entering 'CommandWindowController.applySettings'.");
	
	DDLogVerbose(@"port: %@",settingsModel.port);
	DDLogVerbose(@"interval: %@",settingsModel.interval);
	DDLogVerbose(@"fullscreen: %@",settingsModel.fullscreen);
	
	
	DDLogVerbose(@"pl1Note: %@",settingsModel.pl1Note);
	DDLogVerbose(@"pl2Note: %@",settingsModel.pl2Note);
	DDLogVerbose(@"pl3Note: %@",settingsModel.pl3Note);
	
	[portField setStringValue:FORMAT(@"%@", settingsModel.port)];
	[timeInterval setStringValue:FORMAT(@"%@", settingsModel.interval)];
	[self setNoteControls];
	[fullScreenCheck setIntValue:[settingsModel.fullscreen intValue]];
	
}

- (IBAction)startStop:(id)sender
{
	DDLogVerbose(@"Entering 'CommandWindowController.startStop'.");
	if(![theDelegate.listenSocket running])
	{
		int port = [portField intValue];
		
		if(port < 0 || port > 65535)
		{
			port = 0;
		}
		
		if([theDelegate.listenSocket startServer:FORMAT(@"%hu", port)]){
			[self logInfo:FORMAT(@"Server started on port %hu", port)];
		}
		
		else {
			[self logError:FORMAT(@"Error starting server")];
		}
		
		[portField setEnabled:NO];
		[startStopButton setTitle:@"Stop"];
	}
	else
	{
        [self stopRepeatingTimer];
		[theDelegate.listenSocket stopServer];
		
		[portField setEnabled:YES];
		[startStopButton setTitle:@"Start"];
		
		[self logInfo:FORMAT(@"Server stopped")];
	}
	
}


- (IBAction) sendStartCommand:(id)sender
{
	DDLogVerbose(@"Entering 'sendStartCommand'.");
	
	[startCmdButton setEnabled:NO];
	
	[self startRepeatingTimer];
}

- (IBAction) sendStopCommand:(id)sender
{
	DDLogVerbose(@"Entering 'sendStopCommand'.");
	
	[startCmdButton setEnabled:YES];
	
	[self stopRepeatingTimer];
	
	[theDelegate.listenSocket broadcastCommand:@"STOP"];
	[self logMessage: @"Server sent STOP"];
}

- (IBAction) sendPL1Command:(id)sender
{
	DDLogVerbose(@"Entering 'sendPL1Command'.");
	[self sendPLCommand: 1];
}
- (IBAction) sendPL2Command:(id)sender
{
	DDLogVerbose(@"Entering 'sendPL2Command'.");
	[self sendPLCommand: 2];
}
- (IBAction) sendPL3Command:(id)sender
{
	DDLogVerbose(@"Entering 'sendPL3Command'.");
	[self sendPLCommand: 3];
}

- (void) sendPLCommand: (NSUInteger) number{
	DDLogVerbose(@"Entering 'sendPLCommand'.");
	NSString *command = [NSString stringWithFormat:@"PL %hu",number];
	[startCmdButton setEnabled:NO];
	[self stopRepeatingTimer];
	[theDelegate.listenSocket broadcastCommand:command];
	[self logMessage: FORMAT(@"Server sent %@", command)];
	[self startRepeatingTimer];
	
	currentPL = number;
	currentNote = number;
}

- (IBAction)openSettings:(id)sender
{
	DDLogVerbose(@"Entering 'CommandWindowController.openSettings'.");
	
	[theDelegate updateMIDISources];
	
    [[NSApplication sharedApplication]
	 beginSheet:settingsPanel
	 modalForWindow:documentWindow
	 modalDelegate:self
	 didEndSelector:@selector(settingsPanelDidEnd:returnCode:contextInfo:)
	 contextInfo:nil
	 ];
	
}

- (IBAction) toggleFullScreenCheck:(id)sender
{
	int toggle = ![settingsModel.fullscreen intValue];
	settingsModel.fullscreen =  [NSNumber numberWithInt: toggle];
	[fullScreenCheck setIntValue:toggle];
	
}

- (IBAction) ping:(id)sender
{
    //[myContentArray.arrangedObjects removeAllObjects];
	[theDelegate.listenSocket ping];
}

- (IBAction)settingsPanelButtonPressed:(id)sender
{
	DDLogVerbose(@"Entering 'CommandWindowController.settingsPanelButtonPressed'.");
	
	[self saveAction:sender];
	
    if ([settingsPanel makeFirstResponder:nil]) {        
        [settingsPanel orderOut:self];
        [[NSApplication sharedApplication] endSheet:settingsPanel returnCode:0];
    }
	
}


- (void)settingsPanelDidEnd:(NSWindow*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo
{
	DDLogVerbose(@"Entering 'CommandWindowController.settingsPanelDidEnd'.");
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


- (void)startRepeatingTimer {
	DDLogVerbose(@"Entering 'startRepeatingTimer'.");
	
	if(nextTimer == nil){
		//double interval = [timeInterval doubleValue];
		int intervalInt = [timeInterval intValue];
		//(NSNumber *)
		settingsModel.interval = [NSNumber numberWithInt: intervalInt];
		DDLogVerbose(@"Server will repeat NEXT command every %d seconds",intervalInt);
		[self logInfo:FORMAT(@"Server will repeat NEXT command every %d seconds",intervalInt)];
		DDLogVerbose(@"log 'startRepeatingTimer'.");
		nextTimer = [NSTimer scheduledTimerWithTimeInterval:[timeInterval doubleValue]
													 target:self selector:@selector(timerTargetMethod)
												   userInfo:nil repeats:YES];
		DDLogVerbose(@"nextTimer 'startRepeatingTimer'.");
		updateIndicatorTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
																target:self selector:@selector(updateIndicator)
															  userInfo:nil repeats:YES];
		
		DDLogVerbose(@"updateIndicatorTimer 'startRepeatingTimer'.");	
		//[nextTimer retain];
		//[updateIndicatorTimer retain];
		[nextTimer fire];
		start = mach_absolute_time();
		[timeInterval setEnabled:NO];
		
		[indicator setMaxValue: intervalInt];
		[indicator setIntValue: 1];
		[indicator setNumberOfMajorTickMarks: 5];
		[indicator setNumberOfTickMarks: intervalInt+1];
	}
	DDLogVerbose(@"Exiting 'startRepeatingTimer'.");
	
}
- (void)stopRepeatingTimer {
	DDLogVerbose(@"Entering 'stopRepeatingTimer'.");
    [nextTimer invalidate];
	[updateIndicatorTimer invalidate];
    nextTimer = nil;
	updateIndicatorTimer = nil;
	
	//[nextTimer release];
	//[updateIndicatorTimer release];
	
	//timerCount=0;
	[timeInterval setEnabled:YES];
	nextIndex=1;
}
- (NSDictionary *)userInfo {
    return [NSDictionary dictionaryWithObject:[NSDate date] forKey:@"StartDate"];
}

- (void)timerTargetMethod {
    //NSDate *startDate = [[theTimer userInfo] objectForKey:@"StartDate"];
    //DDLogVerbose(@"Timer started on %@", startDate);
	
	//[indicator setIntValue: 0];
	
	//[self logInfo: @"Server sent NEXT"];
	
	
	if(nextIndex==NSUIntegerMax)nextIndex=0;
	
	NSString *command = [NSString stringWithFormat:@"NEXT %hu",nextIndex++];
	
	[theDelegate.listenSocket broadcastCommand:command];
	//[self logMessage: FORMAT(@"Server sent %@", command)];
	[indicator setIntValue: 0];
	self.start = mach_absolute_time();
	
}

- (void)updateIndicator {
	[indicator setIntValue:[indicator intValue]+1];
	
	if (currentPL != currentNote) {
		[self sendPLCommand:currentNote];
	}
}
#pragma mark PrivateAPI

- (NSString*) getCurrentStringDate
{
	return [dateFormat stringFromDate: [NSDate date]];
	
}

- (void)logError:(NSString *)msg
{
	NSString *paragraph = [NSString stringWithFormat:@"%@ %@\n", [self getCurrentStringDate ],msg];
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
	[attributes setObject:[NSColor redColor] forKey:NSForegroundColorAttributeName];
	
	NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
	//[as autorelease];
	
	[[logView textStorage] appendAttributedString:as];
	[self scrollToBottom];
}

- (void)logInfo:(NSString *)msg
{
	NSString *paragraph = [NSString stringWithFormat:@"%@ %@\n", [self getCurrentStringDate ],msg];
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
	[attributes setObject:[NSColor purpleColor] forKey:NSForegroundColorAttributeName];
	
	NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
	//[as autorelease];
	
	[[logView textStorage] appendAttributedString:as];
	[self scrollToBottom];
}

- (void)logMessage:(NSString *)msg
{
	NSString *paragraph = [NSString stringWithFormat:@"%@ %@\n", [self getCurrentStringDate ],msg];
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
	[attributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
	
	NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
	//[as autorelease];
	
	[[logView textStorage] appendAttributedString:as];
	[self scrollToBottom];
}

#pragma mark -

#pragma mark SocketControllerDelegate protocol

- (void)updateConnectedSockets:(NSUInteger)connectedSockets{
	
	if (connectedSockets<1) {
		//red
		[connCounter setTextColor: NSColor.redColor];
	}else {
		//green
		[connCounter setTextColor: NSColor.greenColor];
		
		if (nextTimer == nil) {
			[self sendStartCommand: nil];
		}
	}
	
	
	[connCounter setStringValue: FORMAT(@"%hu", connectedSockets)];
	
}

- (NSString *)didAcceptNewPeer:(NSString *)peer;
{
	[self logInfo:FORMAT(@"Accepted client %@", peer)];
    

    [self updatePeer:peer withLag:0];
    
	if(self.nextTimer){
		uint64_t elapsed =  mach_absolute_time()-self.start;
		Nanoseconds elapsedNano = AbsoluteToNanoseconds( *(AbsoluteTime *) &elapsed );
		NSString *command = [NSString stringWithFormat:@"PL %hu NEXT %hu CT %llu",currentPL,nextIndex-1, * (uint64_t *)&elapsedNano];
		[self logMessage: FORMAT(@"Server sent %@ to client %@", command, peer)];
       // DDLogVerbose(@"Server sent %@ to client %@", peer);
		return command;
	}
	else 
		return @"Wellcome";
}
-(void)updatePeer:(NSString *) peer withLag: (double) lag
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 peer, @"mac",
                                 FORMAT(@"%f ms", lag), @"delay",
                                 nil];
    NSArray * arrangedObjects = myContentArray.arrangedObjects;
    
    __block NSInteger idx=-1;
    [arrangedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop){
        NSString* key = [obj objectForKey:@"mac"];
       // DDLogVerbose(@"Object: %@",id);
        if([key localizedCaseInsensitiveCompare:peer] == NSOrderedSame){
           // DDLogVerbose(@"Object Found: %@ at index: %lu",obj, index);
            idx=index;
            *stop=YES;
        }
    } ];
    if(idx!=-1)
        [myContentArray removeObjectAtArrangedObjectIndex:idx];
	[myContentArray addObject: dict];
}
- (void)onSocketwillDisconnectWithError:(NSString *)host port:(UInt16)port{
	[self logInfo:FORMAT(@"Client Disconnected: %@:%hu", host, port)];
    //[myContentArray setFetchPredicate:[NSPredicate predicateWithFormat:@"mac == %@", FORMAT(@"%@:%hu", host, port)]];
    
    //[myContentArray setEntityName:@"Entry"];
    //[myContentArray setManagedObjectContext:[self managedObjectContext]];
    //    [myContentArray setFilterPredicate:[NSPredicate predicateWithFormat:@"mac == %@", [NSNumber numberWithInt:1]]];
    /*  
     
     NSError* error = [[NSError alloc]init ];
     
     if ([myContentArray fetchWithRequest:nil merge:YES error:&error] == NO) {
     DDLogVerbose(@"Error fetching entries: %@", error.description);
     } else {
     DDLogVerbose(@"Found %lu entries.", [[myContentArray arrangedObjects] count]);
     }*/
}



#pragma mark -


- (void)inputPopUpRemoveAllItems {
	DDLogVerbose(@"Entering 'CommandWindowController.inputPopUpRemoveAllItems'.");
	[inputPopUp removeAllItems];
}


- (void)inputPopUpAddItem:(PYMIDIEndpoint*)input  {
	DDLogVerbose(@"Entering 'CommandWindowController.inputPopUpAddItem'. %@",[input displayName]);
	[inputPopUp addItemWithTitle:[input displayName]];
	//[[inputPopUp lastItem] setRepresentedObject:input];
}


- (void)inputPopUpAddItems:(NSArray*)items  {
	DDLogVerbose(@"Entering 'CommandWindowController.inputPopUpAddItems'.");
	[inputPopUp removeAllItems];
	
	for (NSString *item in items) {
		DDLogVerbose(@"%@", item);
		[inputPopUp addItemWithTitle:item];
	}
}


/**
 Performs the save action for the application, which is to send the save:
 message to the application's managed object context.  Any encountered errors
 are presented to the user.
 */

- (IBAction) saveAction:(id)sender {
	DDLogVerbose(@"Entering 'CommandWindowController.saveAction'.");
	
    NSError *error = nil;
    
	[self saveSettings];
	
    if (![[self managedObjectContext] commitEditing]) {
        DDLogVerbose(@"%@:%s unable to commit editing before saving", [self class], _cmd);
    }
	
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

/**
 Returns the support directory for the application, used to store the Core Data
 store file.  This code uses a directory named "CoreData" for
 the content, either in the NSApplicationSupportDirectory location or (if the
 former cannot be found), the system's temporary directory.
 */

- (NSString *)applicationSupportDirectory {
	DDLogVerbose(@"Entering 'CommandWindowController.applicationSupportDirectory'.");
	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
	
	DDLogVerbose(@"Path: %@",[basePath stringByAppendingPathComponent:@"command"]);
    return [basePath stringByAppendingPathComponent:@"command"];
}

/**
 Creates, retains, and returns the managed object model for the application 
 by merging all of the models found in the application bundle.
 */

- (NSManagedObjectModel *)managedObjectModel {
	DDLogVerbose(@"Entering 'CommandWindowController.managedObjectModel'.");
	
    if (managedObjectModel) return managedObjectModel;
	
    managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];    
    return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.  This 
 implementation will create and return a coordinator, having added the 
 store for the application to it.  (The directory for the store is created, 
 if necessary.)
 */

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
	DDLogVerbose(@"Entering 'CommandWindowController.persistentStoreCoordinator'.");
	
    if (persistentStoreCoordinator) return persistentStoreCoordinator;
	
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSAssert(NO, @"Managed object model is nil");
        DDLogVerbose(@"%@:%s No model to generate a store from", [self class], _cmd);
        return nil;
    }
	
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *applicationSupportDirectory = [self applicationSupportDirectory];
    NSError *error = nil;
    
    if ( ![fileManager fileExistsAtPath:applicationSupportDirectory isDirectory:NULL] ) {
		if (![fileManager createDirectoryAtPath:applicationSupportDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            NSAssert(NO, ([NSString stringWithFormat:@"Failed to create App Support directory %@ : %@", applicationSupportDirectory,error]));
            DDLogVerbose(@"Error creating application support directory at %@ : %@",applicationSupportDirectory,error);
            return nil;
		}
    }
    
    NSURL *url = [NSURL fileURLWithPath: [applicationSupportDirectory stringByAppendingPathComponent: @"storedata"]];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: mom];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSXMLStoreType 
												  configuration:nil 
															URL:url 
														options:nil 
														  error:&error]){
        [[NSApplication sharedApplication] presentError:error];
        persistentStoreCoordinator = nil;
        return nil;
    }    
	
    return persistentStoreCoordinator;
}

/**
 Returns the managed object context for the application (which is already
 bound to the persistent store coordinator for the application.) 
 */

- (NSManagedObjectContext *) managedObjectContext {
	DDLogVerbose(@"Entering 'CommandWindowController.managedObjectContext'.");
	
    if (managedObjectContext) return managedObjectContext;
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator: coordinator];
	
    return managedObjectContext;
}




- (IBAction)pl1NoteSliderChanged:(id)sender
{
    [self setNote:[pl1NoteSlider intValue] forPlayList:1];
}
- (IBAction)pl1NoteStepperChanged:(id)sender
{
    [self setNote:[pl1NoteStepper intValue] forPlayList:1];
}

- (IBAction)pl2NoteSliderChanged:(id)sender
{
    [self setNote:[pl2NoteSlider intValue] forPlayList:2];
}
- (IBAction)pl2NoteStepperChanged:(id)sender
{
    [self setNote:[pl2NoteStepper intValue] forPlayList:2];
}

- (IBAction)pl3NoteSliderChanged:(id)sender
{
    [self setNote:[pl3NoteSlider intValue] forPlayList:3];
}
- (IBAction)pl3NoteStepperChanged:(id)sender
{
    [self setNote:[pl3NoteStepper intValue] forPlayList:3];
}


- (void)setNote:(Byte)note forPlayList: (int) number
{
	//DDLogVerbose(@"Entering 'CommandWindowController.setNote'.");
	
	switch (number) {
		case 1:
			settingsModel.pl1Note = [NSNumber numberWithInt: note];
			break;
		case 2:
			settingsModel.pl2Note = [NSNumber numberWithInt: note];
			break;
		case 3:
			settingsModel.pl3Note = [NSNumber numberWithInt: note];
			break;
		default:
			break;
	}
	[self setNoteControls];
}



- (void)setNoteControls
{
	PYMIDIManager* manager = [PYMIDIManager sharedInstance];
    
	[pl1NoteField setStringValue:[manager nameOfNote:[settingsModel.pl1Note intValue]]];
	[pl2NoteField setStringValue:[manager nameOfNote:[settingsModel.pl2Note intValue]]];
	[pl3NoteField setStringValue:[manager nameOfNote:[settingsModel.pl3Note intValue]]];
	
	[pl1NoteStepper setIntValue:[settingsModel.pl1Note intValue]]; 
	[pl2NoteStepper setIntValue:[settingsModel.pl2Note intValue]]; 
	[pl3NoteStepper setIntValue:[settingsModel.pl3Note intValue]]; 
	
	[pl1NoteSlider setIntValue:[settingsModel.pl1Note intValue]]; 
	[pl2NoteSlider setIntValue:[settingsModel.pl2Note intValue]]; 
	[pl3NoteSlider setIntValue:[settingsModel.pl3Note intValue]]; 
}

- (void) processMIDINote: (int) note{
	DDLogVerbose(@"Entering 'CommandWindowController.processMIDINote'.");
	
	
	if (note == [settingsModel.pl1Note intValue] && currentPL != 1) {
		currentNote = 1;
		//currentPL=1;
		//[self sendPL1Command:nil];
	} else if (note == [settingsModel.pl2Note intValue] && currentPL != 2) {
		currentNote = 2;
		//currentPL=2;
		//[self sendPL2Command:nil];
	}else if (note == [settingsModel.pl3Note intValue] && currentPL != 3) {
		currentNote = 3;
		//currentPL=3;
		//[self sendPL3Command:nil];
	}
	
	//return;
	
}
@end
