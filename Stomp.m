//
//  Stomp.m
//  Stomp Framework
//
// Copyright (C) 2007 Sandeep Chayapathi (csandeep@gmail.com)
//
// This software is provided 'as-is', without any express or implied 
// warranty. In no event will the authors be held liable for any damages 
// arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose, 
// including commercial applications, and to alter it and redistribute it 
// freely, subject to the following restrictions:
//
//     1. The origin of this software must not be misrepresented; you must 
//        not claim that you wrote the original software. If you use this 
//        software in a product, an acknowledgment in the product 
//        documentation (and/or about box) would be appreciated but is not 
//        required.
//
//     2. Altered source versions must be plainly marked as such, and must
//        not be misrepresented as being the original software.
//
//     3. This notice may not be removed or altered from any source 
//        distribution.
//        


#import "Stomp.h"


@implementation Stomp

-(Stomp *) init {
    
    self = [super init];
    
    if(self){
        [self setSessionId:@""];
        [self setClientId: @""];
    }
    
    return self;
}

/**
    called after initialization, to connect to an ActiveMQ server.
    @param Port - the port on which activemq's stomp interface listens to
    @param User - username
    @param Passcode - the password
*/

-(void) connectToHost: (NSString *) h 
                   Port: (int) p 
                   User: (NSString *) u 
               Passcode: (NSString *) pa; {
    
    host = h;
    port = p;
    username = u;
    passcode = pa;
        
    socket = [[Socket alloc] init];
    [socket setReadBufferSize: 1];
    
    [socket connectToHostName:host port:port];
    
    //send connect frame
    [self connect];
    
    //get the response string
    NSString *str_resp = [self read];
    
    //split on newline
    NSString *element;
    NSEnumerator *enumerator = [[str_resp componentsSeparatedByString:@"\n"] objectEnumerator];
    
    while(element = [enumerator nextObject]){
        
        //look for "session:" in each string
        NSRange range = [element rangeOfString:@"session:"];

        if(range.location == NSNotFound){
            continue;
        }
        
        NSMutableString *tmp_str = [NSMutableString 
                                        stringWithString:[element substringFromIndex:range.length]];
        
        NSRange tmp_range = NSMakeRange(0, [tmp_str length]);
        
        [tmp_str replaceOccurrencesOfString:@"\n" 
                                 withString:@"" 
                                    options:0 
                                      range:tmp_range];
        
        //get the session-id
        [self setSessionId: tmp_str];
        break;
    }
    
    //throw exception on error
    if([self sessionId] == @""){
        NSException *exception = [NSException 
                                    exceptionWithName:@"Error connecting to ActiveMQ"
                                    reason: str_resp 
                                             userInfo:nil];
        [exception raise];
    }

}

//Setters
-(void) setHost: (NSString *) h; {
    host = h;
}

-(void) setPort: (int) p; {
    port = p;
}

-(void) setSessionId: (NSString *) s; {
    sessionId = s;
}

-(void) setClientId: (NSString *) s; {
    clientId = s;
}


//Getters
-(NSString *) host; {
    return host;
}

-(NSString *) sessionId; {
    return sessionId;
}

-(int) port; {
    return port;
}


-(Socket *) socket {
    return socket;
}

-(NSString *) clientId; {
    return clientId;
}

-(NSString *) destination {
    return destination;
}

-(void) setDestination: (NSString *) s {
    destination = s;
}

//stomp protocol

/**
    send a CONNECT frame, the server will respond with a session-id.
*/

-(void) connect {
    NSArray *param = [NSArray arrayWithObjects: [@"login:" stringByAppendingString:username],
        [@"pascode:" stringByAppendingString:passcode], nil];
    
    [self transmitCommand:@"CONNECT" withBody: @"" andParam: param];
}

/**
    send a DISCONNECT frame. This will also unset the session & client id's and 
    close the socket. It is quite polite to use this before closing the socket.
*/

-(void) disconnect {
    NSArray *param = [NSArray arrayWithObjects: [@"session-id:" stringByAppendingString: [self sessionId]]
        , nil];
    
    [self transmitCommand:@"DISCONNECT" withBody: @"" andParam: param];
    
    //unset the destination & session
    [self setDestination:@""];
    [self setSessionId:@""];
    [self setClientId: @""];
    
    [[self socket] close];
        
}

/**
    send a UNSUBSCRIBE frame. It is used to remove an existing subscription -
    to no longer receive messages from that destination. It requires either
    a destination header or an id header (if the previous SUBSCRIBE
    operation passed an id value)
*/

-(void) unSubscribe {
    NSArray *dict = [NSArray arrayWithObjects:[@"session-id:" stringByAppendingString: [self sessionId]],
        [@"destination:" stringByAppendingString: [self destination] ], 
                                        @"ack:auto", nil];
    
    [self transmitCommand:@"UNSUBSCRIBE" withBody: @"" andParam: dict];
    
    [self setDestination: @""];    
}

/**
    subscribe to a destination. The SUBSCRIBE command is used to register to 
    listen to a given destination. Like the SEND command, the SUBSCRIBE command requires a
    destination header indicating which destination to subscribe to.
*/

-(void) subscribeToDestination: (NSString *) dest {
                                            
    NSArray *dict = [NSArray arrayWithObjects:[@"session-id:" stringByAppendingString: [self sessionId]],
        [@"destination:" stringByAppendingString:dest], 
                                       @"ack:auto", nil];
    
    [self transmitCommand:@"SUBSCRIBE" withBody: @"" andParam: dict];
    
    [self setDestination:dest];
}

/**
    send a MESSAGE frame. The SEND command sends a message to a destination in 
    the messaging system.
    @param toDestination: the destination of the message.
*/

-(void) sendMessage: (NSString *) mesg toDestination: (NSString *) dest {
    
    NSArray *dict = [NSArray arrayWithObjects:[@"session-id:" stringByAppendingString: [self sessionId]],
        [@"destination:" stringByAppendingString:dest], nil];
    
    [self transmitCommand:@"\nSEND" withBody: mesg andParam: dict];
}

/**
    retrieve message from server. This method does a blocking read and returns 
    the "message" body. Use "read", to retrieve raw message.
*/

-(NSString *) getMessage {
    NSString *response = [self read];
    NSString *result;
    
    NSMutableArray *contents = (NSMutableArray *) [response componentsSeparatedByString:@"\n"];    
    // shift the last line, which is control-@ char
    [contents removeLastObject];
    
    // pop the first line, which is newline char
    [contents removeObjectAtIndex:0];
    
    unsigned count;
    unsigned arrayCount = [contents count];
    
    
    // walk till the first empty line
    for (count = 0; count < arrayCount; count++) { 
        if( [[contents objectAtIndex:count] isEqualTo:@""] ){
            break;  
        }
    }
    
    // the remaining data is the body, except for the line
    while(count+1 > 0) {
        [contents removeObjectAtIndex:count];
        count--;
    }
    
    result = [contents componentsJoinedByString:@"\n"];
    
    return result;
}


// internal methods


-(void) transmitCommand: (NSString *) cmd withBody: (NSString *) body andParam: (NSArray *) param {

    //put the command at the head of the frame
    NSMutableString *connect_frame = [NSMutableString stringWithString: [cmd stringByAppendingString:@"\n"]];

    //... followed by the parameters
    if(param != nil){
        NSEnumerator *objEnum = [param objectEnumerator];
        NSString *key;
        
        while(key = [objEnum nextObject]){
            [connect_frame appendString: [key stringByAppendingString:@"\n"]];
        }
    }
    
    //.. and the body at the end of the frame
    if(body != nil){
        [connect_frame appendString: @"\n"];
        [connect_frame appendString: body];
    }
    
    NSString *ctrl_str;
    ctrl_str = [NSString stringWithFormat:@"\n%C", 0];
    [connect_frame appendString: ctrl_str];

    
    [[self socket] writeString: connect_frame];
}

-(NSString *) read {
    
    NSString *ctrl_str;
    ctrl_str = [NSString stringWithFormat:@"%C", 0];
    
    NSMutableData *response = [NSMutableData data];
    
    while ([socket readData:response] > 0) {
        // each read appends to data, 
        // returns number of bytes read or 0 on EOF
        
        NSString *tmp_str = [[NSString alloc] 
                                initWithData:response encoding:[NSString defaultCStringEncoding]
            ];

        NSString *test =  [tmp_str substringFromIndex:[tmp_str length]-1 ] ;
        
        if ( [test isEqualToString:ctrl_str] ){
            //end of message
            break;
        }
    }

    //get the response string
    NSString *str_resp = [[NSString alloc] initWithData:response encoding:[NSString defaultCStringEncoding]];
    
    return str_resp;
}

@end
