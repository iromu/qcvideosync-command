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
	id			pl1Note;
	id			pl2Note;
	id			pl3Note;
}

@property(nonatomic, retain) id  interval;
@property(nonatomic, retain) id pl1Note, pl2Note, pl3Note;
@property(nonatomic, retain) id fullscreen;
@property(nonatomic, retain) id port;

@end
/*
@property (nonatomic, retain) NSNumber * interval;

// coalesce these into one @interface settings (CoreDataGeneratedAccessors) section
@interface settings (CoreDataGeneratedAccessors)
@end
*/