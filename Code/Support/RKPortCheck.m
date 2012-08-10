//
//  RKPortCheck.m
//  RestKit
//
//  Created by Blake Watters on 5/10/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKPortCheck.h"

#include <netdb.h>
#include <arpa/inet.h>

@interface RKPortCheck ()
@property (nonatomic, assign) struct sockaddr_in remote_saddr;
@property (nonatomic, assign, getter = isOpen) BOOL open;
@property (nonatomic, assign, getter = hasRun) BOOL run;
@end

@implementation RKPortCheck

@synthesize host = _host;
@synthesize port = _port;
@synthesize remote_saddr = _remote_saddr;
@synthesize open = _open;
@synthesize run = _run;

- (id)initWithHost:(NSString *)hostNameOrIPAddress port:(NSUInteger)port
{
    self = [self init];
    if (self) {
        _run = NO;
        _host = [hostNameOrIPAddress retain];
        _port = port;

        struct sockaddr_in sa;
        char *hostNameOrIPAddressCString = (char *)[hostNameOrIPAddress UTF8String];
        int result = inet_pton(AF_INET, hostNameOrIPAddressCString, &(sa.sin_addr));
        if (result != 0) {
            // IP Address
            bzero(&_remote_saddr, sizeof(struct sockaddr_in));
            _remote_saddr.sin_len = sizeof(struct sockaddr_in);
            _remote_saddr.sin_family = AF_INET;
            _remote_saddr.sin_port = htons(port);
            inet_aton(hostNameOrIPAddressCString, &(_remote_saddr.sin_addr));
        } else {
            // Hostname
            struct hostent *hp;
            if ((hp = gethostbyname(hostNameOrIPAddressCString)) == 0) {
                return nil;
            }

            bzero(&_remote_saddr, sizeof(struct sockaddr_in));
            _remote_saddr.sin_family = AF_INET;
            _remote_saddr.sin_addr.s_addr = ((struct in_addr *)(hp->h_addr))->s_addr;
            _remote_saddr.sin_port = htons(port);
        }
    }

    return self;
}

- (void)dealloc
{
    [_host release];
    [super dealloc];
}

- (void)run
{
    int sd;
    _run = YES;

    // Create Internet domain socket
    if ((sd = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
        _open = NO;
        return;
    }

    // Try to connect to the port
    _open = (connect(sd, (struct sockaddr *)&_remote_saddr, sizeof(_remote_saddr)) == 0);

    if (_open) {
        close(sd);
    }
}

- (BOOL)isOpen
{
    NSAssert(self.hasRun, @"Cannot determine port availability. Check has not been run.");
    return _open;
}

- (BOOL)isClosed
{
    return !self.isOpen;
}

@end
