# How To Use Stomp.framework: #


## Add Framework to Xcode project ##

  * Download and extract [stomp.framework](http://code.google.com/p/stompframework/downloads/list) into ~/Library/Framworks
  * In xcode, _Add To Project_ this framework
  * Also add a _New Copy Files Build Phase_ to the project's target and set the Destination as "Frameworks"
  * Drag the stomp.framework into this build phase


## To Send a Message to a destination ##

```
    Stomp *stmp;
    stmp = [[Stomp alloc] init];

    [stmp connectToHost:@"localhost"
                   Port: 61613
                   User:@"user"
               Passcode:@"password"];

    [stmp sendMessage: @"Hello World!" toDestination @"/queue/test"];
```

## To Subscribe to a destination ##

```
    Stomp *stmp;
    stmp = [[Stomp alloc] init];

    [stmp connectToHost:@"localhost"
                   Port: 61613
                   User:@"user"
               Passcode:@"password"];

    [stmp subscribeToDestination:@"/queue/test"];
    NSString *res = [stmp getMessage];
```