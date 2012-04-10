//
//  MIDIController.m
//  command
//
//  Created by wantez on 10/08/10.
//  Copyright 2010 Ivan Rodriguez Murillo. All rights reserved.
//

#import "MIDIController.h"


@interface MIDIController (private)

- (NSString*)channelFilterDescription;
- (NSString*)noteFilterDescription;
- (NSString*)clockDescription;
- (void)processMIDIMessage:(Byte*)message ;//ofLength:(unsigned int)length;
@end

@implementation MIDIController

@synthesize theDelegate;

BOOL isDataByte (Byte b)		{ return b < 0x80; }
BOOL isStatusByte (Byte b)		{ return b >= 0x80 && b < 0xF8; }
BOOL isRealtimeByte (Byte b)	{ return b >= 0xF8; }



- (MIDIController *) initWithDelegate: (id) delegate {
	self = [super init];
	[self setTheDelegate: delegate];
	DDLogVerbose (@"MIDIController.initWithDelegate.");
	
	return self;
}

- (void) updateMIDISources{
	DDLogVerbose(@"Entering 'MIDIController.updateMIDISources'.");
	
	NSArray*		realSources;
	//NSArray*		names;
    NSEnumerator*	enumerator;
    PYMIDIEndpoint*	inputDetected;
	
	//if ([theDelegate respondsToSelector:@selector(inputPopUpRemoveAllItems)])
		[theDelegate inputPopUpRemoveAllItems];
	
	//[inputPopUp removeAllItems];
	
	PYMIDIManager*	manager = [PYMIDIManager sharedInstance];
	realSources = [manager realSources];
    
	//- (void)inputPopUpAddItems:(NSArray*)items 
	//[theDelegate inputPopUpAddItems: inputDetected];
	
    enumerator = [realSources objectEnumerator];
    while (inputDetected = [enumerator nextObject]) {
		DDLogVerbose(@"Detected MIDI source %@", [inputDetected displayName]);
		//if ([theDelegate respondsToSelector:@selector(inputPopUpAddItem:)])
			[theDelegate inputPopUpAddItem: inputDetected];

		input  = inputDetected;
		[input addReceiver:self];
    }
}



unsigned int
midiPacketListSize (const MIDIPacketList* packetList)
{
	//DDLogVerbose(@"Entering 'MIDIController.midiPacketListSize'.");
    const MIDIPacket*	packet;
    int					i;
    
    packet = &packetList->packet[0];
    for (i = 0; i < packetList->numPackets; i++)
        packet = MIDIPacketNext (packet);
	
    return (void*)packet - (void*)packetList;
}


unsigned int
findEndOfMessage (const MIDIPacket* packet, unsigned int startIndex)
{
	//DDLogVerbose(@"Entering 'MIDIController.findEndOfMessage'.");
    unsigned int i;
    
    // Look for the status byte of the next message, or the end of the packet
    for (i = startIndex + 1; i < packet->length && !isStatusByte (packet->data[i]); i++);
	
    // Skip backwords over any realtime data at the end of the packet
    while (isRealtimeByte (packet->data[--i]));
    
    return i;
}


- (void)processMIDIPacketList:(const MIDIPacketList*)inPacketList sender:(id)sender
{
	DDLogVerbose(@"Entering 'MIDIController.processMIDIPacketList'.");
	
    //NSMutableData*		data;
   // MIDIPacketList*		outPacketList;
    const MIDIPacket*	inPacket;
    //MIDIPacket*			outPacket;
    int					i, j;
    int					messageStart;//, messageEnd;
    //int					outMessageStart;
    //int					outMessageLength;
    
	
   // data = [NSMutableData dataWithLength:midiPacketListSize (inPacketList)];
    inPacket = &inPacketList->packet[0];
    for (i = 0; i < inPacketList->numPackets; i++) {
        
        // First we skip over any SysEx continuation at the start of the packet
        // and simply copy it to the output packet without changing it.
        for (j = 0; j < inPacket->length && !isStatusByte (inPacket->data[j]); j++) {
           // if (shouldTransmitClock || !isRealtimeByte (inPacket->data[j]))
                //outPacket->data[outPacket->length++] = inPacket->data[j];
        }
        
        // Now we loop over the remaining MIDI messages in the packet
        messageStart = j;
        if (messageStart < inPacket->length) {
            //messageEnd = findEndOfMessage (inPacket, messageStart);
			@try {
				[self processMIDIMessage:(Byte*)&inPacket->data[messageStart]];
			} 
			@catch (id theException) {
				DDLogVerbose(@"%@", theException);
			} 
			
			
			//messageStart = j++;
        }
		return;
        inPacket = MIDIPacketNext (inPacket);
    }

}


- (void)processMIDIMessage:(Byte*)message
{
	//DDLogVerbose(@"Entering 'MIDIController.processMIDIMessage'.");
	//CFRunLoopRef runLoop;
    // If this is a system message we don't touch it
    if (message[0] >= 0xF0){
		DDLogVerbose(@"SYS");
		return;
	}

    if (message[0] < 0xB0) {
		DDLogVerbose(@"filter notes");
		PYMIDIManager* manager = [PYMIDIManager sharedInstance];
		if(message[1] < 128) {
			DDLogVerbose(@"note %@", [manager nameOfNote:message[1]]);
			
			
			//[NSThread detachNewThreadSelector:@selector(processMIDINote:) toTarget:theDelegate withObject:(int)message[1]];
			//runLoop = CFRunLoopGetCurrent();
			/*
			[runLoop performSelector:@selector(processMIDINote:) 
							  target:theDelegate argument:(int)message[1] order:0 
							   modes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
	
			*/
			/*
			 [NSTimer scheduledTimerWithTimeInterval:1.0f
											 target:theDelegate selector:@selector(processMIDINote:)
										   userInfo:nil repeats:NO];
			
			*/
			//NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
			
			[theDelegate processMIDINote: (int)message[1]];
			
			//[pool release];
		}
		
        
    }
    return;
}


@end
