//
//  RKSpecNotificationObserver.m
//  RestKit
//
//  Created by Jeff Arena on 8/23/11.
//  Copyright 2011 RestKit. All rights reserved.
//

#import "RKSpecNotificationObserver.h"

@implementation RKSpecNotificationObserver

@synthesize object = _object;
@synthesize name = _name;
@synthesize timeout = _timeout;

+ (void)waitForNotificationWithName:(NSString *)name object:(id)object usingBlock:(void(^)())block {
    RKSpecNotificationObserver *observer = [RKSpecNotificationObserver notificationObserverForName:name object:object];
    block();
    [observer waitForNotification];
}

+ (void)waitForNotificationWithName:(NSString *)name usingBlock:(void(^)())block {
    [self waitForNotificationWithName:name object:nil usingBlock:block];
}

+ (RKSpecNotificationObserver *)notificationObserver {
    return [[[self alloc] init] autorelease];
}

+ (RKSpecNotificationObserver *)notificationObserverForName:(NSString *)notificationName object:(id)object {
    RKSpecNotificationObserver *notificationObserver = [self notificationObserver];
    notificationObserver.object = object;
    notificationObserver.name = notificationName;
    return notificationObserver;
}

+ (RKSpecNotificationObserver *)notificationObserverForName:(NSString *)notificationName {
    return [self notificationObserverForName:notificationName object:nil];
}

- (id)init {
    self = [super init];
	if (self) {
        _timeout = 5;
		_awaitingResponse = NO;
	}
	return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void)waitForNotification {
    NSAssert(_name, @"Notification name cannot be nil");
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(processNotification:)
                                                 name:self.name
                                               object:self.object];
    
	_awaitingResponse = YES;
	NSDate *startDate = [NSDate date];

	while (_awaitingResponse) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
		if ([[NSDate date] timeIntervalSinceDate:startDate] > self.timeout) {
			[NSException raise:nil format:@"*** Operation timed out after %f seconds...", self.timeout];
			_awaitingResponse = NO;
		}
	}
}

- (void)processNotification:(NSNotification*)notification {
    NSAssert([_name isEqualToString:notification.name],
             @"Received notification (%@) differs from expected notification (%@)",
             notification.name, _name);
    _awaitingResponse = NO;
}

@end
