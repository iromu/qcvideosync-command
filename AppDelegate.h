//
//  AppDelegate.h
//  command
//
//  Created by wantez on 03/08/10.
//  Copyright 2010 Ivan Rodriguez Murillo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SocketController.h"
#import "MIDIController.h"
#import "CommandWindowController.h"
#import "CommandWindowControllerDelegate.h"
//@class CommandWindowController;

@interface AppDelegate : NSObject<CommandWindowControllerDelegate>
{

    SocketController *       listenSocket;
    MIDIController *         midiController;
    @private
    CommandWindowController * cmdWindowController;
    /*
       @private
       NSManagedObjectContext *managedObjectContext_;
       NSManagedObjectModel *managedObjectModel_;
       NSPersistentStoreCoordinator *persistentStoreCoordinator_;
     */
}

@property (readonly) SocketController *  listenSocket;

/*
   @property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
   @property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
   @property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

   - (NSString *)applicationDocumentsDirectory;
 */
- (IBAction) openSettings:(id)sender;
- (void)handleStartScriptCommandSent:(NSNotification *)note;

@end
