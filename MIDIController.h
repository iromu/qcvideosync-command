//
//  MIDIController.h
//  command
//
//  Created by wantez on 10/08/10.
//  Copyright 2010 Ivan Rodriguez Murillo. All rights reserved.
//
#include <common.h>

#import <PYMIDI/PYMIDI.h>
#import <PYMIDI/PYMIDIEndpoint.h>

@protocol MIDIControllerDelegate
-(void)inputPopUpRemoveAllItems;
- (void)inputPopUpAddItem:(PYMIDIEndpoint*)input;
- (void)inputPopUpAddItems:(NSArray*)items;
- (void) processMIDINote: (int) note;
@end

@interface MIDIController : NSObject   {
	id	<MIDIControllerDelegate>			theDelegate;
	
	BOOL			isInLimbo;
    
    BOOL			isEnabled;
    
    PYMIDIEndpoint*	input;
    
    BOOL			shouldFilterChannel;
    unsigned int	channelMask;
    
    BOOL			shouldAllowNotes;
    BOOL			shouldFilterRange;
    Byte			lowestAllowedNote;
    Byte			highestAllowedNote;
    
    BOOL			shouldTranspose;
    int				transposeDistance;
    
    BOOL			shouldRemapChannel;
    int				remappingChannel;
    
    BOOL			shouldTransmitClock;
    
    PYMIDIEndpoint*	output;

}

@property (readwrite, retain) id<MIDIControllerDelegate> theDelegate;	

-(MIDIController *) initWithDelegate: (id<MIDIControllerDelegate>) delegate;

- (void) updateMIDISources;
#pragma mark MIDI packet handling

- (void)processMIDIPacketList:(const MIDIPacketList*)packetList sender:(id)sender;
@end



