/*
 *  common.h
 *  command
 *
 *  Created by wantez on 13/08/10.
 *  Copyright 2010 Ivan Rodriguez Murillo. All rights reserved.
 *
 */
#define WELCOME_MSG  0
#define ECHO_MSG     1
#define WARNING_MSG  2
#define TICK_MSG     3


#define NO_TIMEOUT -1
#define READ_TIMEOUT 15.0
#define READ_TIMEOUT_EXTENSION 10.0

#define FORMAT(format, ...) [NSString stringWithFormat:(format), ##__VA_ARGS__]