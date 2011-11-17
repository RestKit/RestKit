//
//  RKSpecUser.m
//  RestKit
//
//  Created by Blake Watters on 8/5/11.
//  Copyright 2011 RestKit. All rights reserved.
//

#import "RKSpecUser.h"
#import "RKLog.h"

@implementation RKSpecUser

@synthesize userID = _userID;
@synthesize name = _name;
@synthesize birthDate = _birthDate;
@synthesize favoriteColors = _favoriteColors;
@synthesize addressDictionary = _addressDictionary;
@synthesize website = _website;
@synthesize isDeveloper = _isDeveloper;
@synthesize luckyNumber = _luckyNumber;
@synthesize weight = _weight;
@synthesize interests = _interests;
@synthesize country = _country;
@synthesize address = _address;
@synthesize friends = _friends;
@synthesize friendsSet = _friendsSet;

+ (RKSpecUser*)user {
    return [[self new] autorelease];
}

// isEqual: is consulted by the mapping operation
// to determine if assocation values should be set
- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[RKSpecUser class]]) {
        return [[(RKSpecUser*)object userID] isEqualToNumber:self.userID];
    } else {
        return NO;
    }
}

- (id)valueForUndefinedKey:(NSString *)key {
    RKLogError(@"Unexpectedly asked for undefined key '%@'", key);
    return [super valueForUndefinedKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    RKLogError(@"Asked to set value '%@' for undefined key '%@'", value, key);
    [super setValue:value forUndefinedKey:key];
}

@end
