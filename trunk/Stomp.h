//
//  Stomp.h
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


#import <Foundation/Foundation.h>
#import "Socket.h"

@interface Stomp : NSObject {
    @private
        NSString *host;
        int port;
        NSString *sessionId;
        Socket *socket;
        NSString *username;
        NSString *passcode;
        NSString *destination;
        NSString *clientId; /**< the JMS Client ID which is used in combination to
            the "activemq.subscriptionName" to denote a durable subscriber.*/
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
               Passcode: (NSString *) pa;

//Setters
-(void) setHost: (NSString *) h;
-(void) setPort: (int) p;
-(void) setSessionId: (NSString *) s;
-(void) setDestination: (NSString *) s;
-(void) setClientId: (NSString *) s;

//Getters
-(NSString *) host;
-(NSString *) sessionId;
-(int) port;
-(Socket *) socket;
-(NSString *) destination;
-(NSString *) clientId;

/**
    send a CONNECT frame, the server will respond with a session-id.
*/
-(void) connect;

/**
retrieve message from server. This method does a blocking read and returns 
 the "message" body. Use "read", to retrieve raw message.
 */
-(NSString *) getMessage;

/**
send a DISCONNECT frame. This will also unset the session & client id's and 
 close the socket. It is quite polite to use this before closing the socket.
 */
-(void) disconnect;

/**
send a UNSUBSCRIBE frame. It is used to remove an existing subscription -
 to no longer receive messages from that destination. It requires either
 a destination header or an id header (if the previous SUBSCRIBE
                                       operation passed an id value)
 */
-(void) unSubscribe;

/**
subscribe to a destination. The SUBSCRIBE command is used to register to 
 listen to a given destination. Like the SEND command, the SUBSCRIBE command requires a
 destination header indicating which destination to subscribe to.
 */
-(void) subscribeToDestination: (NSString *) dest;

/**
send a MESSAGE frame. The SEND command sends a message to a destination in 
 the messaging system.
 @param toDestination: the destination of the message.
 */
-(void) sendMessage: (NSString *) mesg toDestination: (NSString *) dest;

// private methods
-(void) transmitCommand: (NSString *) cmd withBody: (NSString *) body  andParam: (NSArray *) dict;
-(NSString *) read;

@end
