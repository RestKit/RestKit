//
//  RKTestUser.m
//  RestKit
//
//  Created by Blake Watters on 8/5/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKTestUser.h"
#import "RKLog.h"

@implementation RKTestCoordinate

- (BOOL)isEqual:(id)object
{
    if (! [object isKindOfClass:[RKTestCoordinate class]]) return NO;
    return [object latitude] == self.latitude && [object longitude] == self.longitude;
}

@end

@implementation RKTestUser

+ (RKTestUser *)user
{
    return [self new];
}

// isEqual: is consulted by the mapping operation
// to determine if assocation values should be set
- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[RKTestUser class]]) {
        if ([(RKTestUser *)object userID] == nil && self.userID == nil) {
            // No primary key -- consult superclass
            return [super isEqual:object];
        } else {
            return self.userID && [[(RKTestUser *)object userID] isEqualToNumber:self.userID];
        }
    }

    return NO;
}

- (id)valueForUndefinedKey:(NSString *)key
{
    RKLogError(@"Unexpectedly asked for undefined key '%@'", key);
    return [super valueForUndefinedKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    RKLogError(@"Asked to set value '%@' for undefined key '%@'", value, key);
    [super setValue:value forUndefinedKey:key];
}

@end
