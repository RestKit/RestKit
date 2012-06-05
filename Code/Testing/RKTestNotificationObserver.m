//
//  RKTestNotificationObserver.m
//  RestKit
//
//  Created by Jeff Arena on 8/23/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKTestNotificationObserver.h"

@interface RKTestNotificationObserver ()
@property (nonatomic, assign, getter = isAwaitingNotification) BOOL awaitingNotification;
@end

@implementation RKTestNotificationObserver

@synthesize object;
@synthesize name;
@synthesize timeout;
@synthesize awaitingNotification;

+ (void)waitForNotificationWithName:(NSString *)name object:(id)object usingBlock:(void(^)())block
{
    RKTestNotificationObserver *observer = [RKTestNotificationObserver notificationObserverForName:name object:object];
    block();
    [observer waitForNotification];
}

+ (void)waitForNotificationWithName:(NSString *)name usingBlock:(void(^)())block
{
    [self waitForNotificationWithName:name object:nil usingBlock:block];
}

+ (RKTestNotificationObserver *)notificationObserver
{
    return [[[self alloc] init] autorelease];
}

+ (RKTestNotificationObserver *)notificationObserverForName:(NSString *)notificationName object:(id)object
{
    RKTestNotificationObserver *notificationObserver = [self notificationObserver];
    notificationObserver.object = object;
    notificationObserver.name = notificationName;
    return notificationObserver;
}

+ (RKTestNotificationObserver *)notificationObserverForName:(NSString *)notificationName
{
    return [self notificationObserverForName:notificationName object:nil];
}

- (id)init
{
    self = [super init];
    if (self) {
        timeout = 5;
        awaitingNotification = NO;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)waitForNotification
{
    NSAssert(name, @"Notification name cannot be nil");

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(processNotification:)
                                                 name:self.name
                                               object:self.object];

    awaitingNotification = YES;
    NSDate *startDate = [NSDate date];

    while (self.isAwaitingNotification) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        if ([[NSDate date] timeIntervalSinceDate:startDate] > self.timeout) {
            [NSException raise:nil format:@"*** Operation timed out after %f seconds...", self.timeout];
            awaitingNotification = NO;
        }
    }
}

- (void)processNotification:(NSNotification *)notification
{
    NSAssert([name isEqualToString:notification.name],
             @"Received notification (%@) differs from expected notification (%@)",
             notification.name, name);
    awaitingNotification = NO;
}

@end
