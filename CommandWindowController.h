//
//  CommandWindowController.h
//  command
//
//  Created by wantez on 03/08/10.
//  Copyright 2010 Ivan Rodriguez Murillo. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import <PYMIDI/PYMIDI.h>
#import <PYMIDI/PYMIDIEndpoint.h>
#import "MIDIController.h"
#import "SettingsModel.h"
#import "SocketController.h"
#import "CommandWindowControllerDelegate.h"
//@class SocketController;

/*
   @protocol CommandWindowControllerDelegate <NSObject>
   -(SocketController*)	listenSocket;
   @end
 */

@interface CommandWindowController : NSWindowController<MIDIControllerDelegate, SocketControllerDelegate> {
    id<CommandWindowControllerDelegate>                             theDelegate;

    IBOutlet NSWindow *                      documentWindow;
    IBOutlet NSTextView *            logView;
    IBOutlet NSTextField *           connCounter;
    IBOutlet NSTextField *           portField;
    IBOutlet NSButton *                      startStopButton;
    IBOutlet NSButton *                      startCmdButton;
    IBOutlet NSButton *                      stopCmdButton;
    IBOutlet NSButton *                      pl1CmdButton;
    IBOutlet NSButton *                      pl2CmdButton;
    IBOutlet NSButton *                      pl3CmdButton;
    IBOutlet NSLevelIndicator *      indicator;
    IBOutlet NSTextField *           timeInterval;
    IBOutlet NSButton *                      fullScreenCheck;
    IBOutlet NSPopUpButton *         inputPopUp;
    IBOutlet NSPanel *                       settingsPanel;

    IBOutlet NSSlider *                      pl1NoteSlider;
    IBOutlet NSTextField *               pl1NoteField;
    IBOutlet NSStepper *                 pl1NoteStepper;

    IBOutlet NSSlider *                      pl2NoteSlider;
    IBOutlet NSTextField *               pl2NoteField;
    IBOutlet NSStepper *                 pl2NoteStepper;

    IBOutlet NSSlider *                      pl3NoteSlider;
    IBOutlet NSTextField *               pl3NoteField;
    IBOutlet NSStepper *                 pl3NoteStepper;

    IBOutlet NSTableView *       myTableView;
    IBOutlet NSArrayController *myContentArray;
    IBOutlet NSForm *myFormFields;


    NSTimer *                        __weak nextTimer;
    NSTimer *                        __weak updateIndicatorTimer;
    uint64_t start;
    NSUInteger nextIndex;
    NSUInteger currentPL;
    int currentNote;

    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;

    SettingsModel *          settingsModel;
}
@property (readwrite, strong) id<CommandWindowControllerDelegate> theDelegate;

@property (weak) NSTimer *       nextTimer;
@property (weak) NSTimer *       updateIndicatorTimer;
@property uint64_t start;

@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;

- (IBAction) startStop:(id)sender;

- (IBAction) sendStartCommand:(id)sender;
- (IBAction) sendStopCommand:(id)sender;

- (IBAction) sendPL1Command:(id)sender;
- (IBAction) sendPL2Command:(id)sender;
- (IBAction) sendPL3Command:(id)sender;

- (IBAction) openSettings:(id)sender;
- (IBAction) settingsPanelButtonPressed:(id)sender;

- (IBAction) toggleFullScreenCheck:(id)sender;

- (IBAction) ping:(id)sender;

- (IBAction)saveAction:sender;

- (void) settingsPanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
//- (void)updateConnectedSockets:(NSUInteger)connectedSockets;
//- (void)didConnectToHost:(NSString *)host port:(UInt16)port;
//- (void)onSocketwillDisconnectWithError:(NSString *)host port:(UInt16)port;
- (NSDictionary *) userInfo;
//- (void) dealloc;

- (IBAction)pl1NoteSliderChanged:(id)sender;
- (IBAction)pl1NoteStepperChanged:(id)sender;

- (IBAction)pl2NoteSliderChanged:(id)sender;
- (IBAction)pl2NoteStepperChanged:(id)sender;

- (IBAction)pl3NoteSliderChanged:(id)sender;
- (IBAction)pl3NoteStepperChanged:(id)sender;
- (void) processMIDINote:(int)note;
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;
- (void)mainThread_updatePeer:(NSArray *)note;
@end
