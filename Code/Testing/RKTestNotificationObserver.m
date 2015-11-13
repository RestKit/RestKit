//
//  RKTestNotificationObserver.m
//  RestKit
//
//  Created by Jeff Arena on 8/23/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <RestKit/Testing/RKTestNotificationObserver.h>

@interface RKTestNotificationObserver ()
@property (nonatomic, assign, getter = isObserverAdded) BOOL observerAdded;
@property (nonatomic, assign, getter = isAwaitingNotification) BOOL awaitingNotification;
@property (nonatomic, strong) NSDate *startDate;
@end

@implementation RKTestNotificationObserver


+ (void)waitForNotificationWithName:(NSString *)name object:(id)object usingBlock:(void(^)())block
{
    RKTestNotificationObserver *observer = [RKTestNotificationObserver notificationObserverForName:name object:object];
    [observer addObserver];
    block();
    [observer waitForNotification];
}

+ (void)waitForNotificationWithName:(NSString *)name usingBlock:(void(^)())block
{
    [self waitForNotificationWithName:name object:nil usingBlock:block];
}

+ (RKTestNotificationObserver *)notificationObserver
{
    return [[self alloc] init];
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

- (instancetype)init
{
    self = [super init];
    if (self) {
        _timeout = 5;
        _awaitingNotification = NO;
    }
    return self;
}

- (void)dealloc
{
    [self removeObserver];
}

- (void)addObserver
{
    if (self.isObserverAdded) return;

    NSAssert(_name, @"Notification name cannot be nil");

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(processNotification:)
                                                 name:self.name
                                               object:self.object];
    self.observerAdded = YES;
    self.awaitingNotification = YES;
    self.startDate = [NSDate date];
}

- (void)removeObserver
{
    if (! self.isObserverAdded) return;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)waitForNotification
{
    [self addObserver];

    while (self.isAwaitingNotification) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        if ([[NSDate date] timeIntervalSinceDate:self.startDate] > self.timeout) {
            [NSException raise:nil format:@"*** Operation timed out after %f seconds...", self.timeout];
            self.awaitingNotification = NO;
        }
    }

    [self removeObserver];
}

- (void)processNotification:(NSNotification *)notification
{
    NSAssert([self.name isEqualToString:notification.name],
             @"Received notification (%@) differs from expected notification (%@)",
             notification.name, self.name);
    self.awaitingNotification = NO;
}

@end
