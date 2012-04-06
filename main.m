//
//  main.m
//  command
//
//  Created by wantez on 19/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	int retVal = NSApplicationMain(argc,  (const char **) argv);
	
	[pool release];
	//[pool drain];
	
    return retVal;
}
