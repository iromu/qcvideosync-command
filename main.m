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
    @autoreleasepool {

        int retVal = NSApplicationMain(argc, (const char * *) argv);

        //[pool drain];

        return retVal;
    }
}

