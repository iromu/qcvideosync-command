//
//  SettingsModel.h
//  command
//
//  Created by wantez on 19/08/10.
//  Copyright 2010 Ivan Rodriguez Murillo. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SettingsModel : NSObject {
	id port;
	id interval;
	id fullscreen;
	id pl1Note;
	id pl2Note;
	id pl3Note;
}

@property(nonatomic, strong) id  interval;
@property(nonatomic, strong) id pl1Note, pl2Note, pl3Note;
@property(nonatomic, strong) id fullscreen;
@property(nonatomic, strong) id port;

@end