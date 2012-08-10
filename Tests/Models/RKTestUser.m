//
//  RKTestUser.m
//  RestKit
//
//  Created by Blake Watters on 8/5/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKTestUser.h"
#import "RKLog.h"

@implementation RKTestUser

@synthesize userID = _userID;
@synthesize name = _name;
@synthesize birthDate = _birthDate;
@synthesize favoriteDate = _favoriteDate;
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
@synthesize friendsOrderedSet = _friendsOrderedSet;

+ (RKTestUser *)user
{
    return [[self new] autorelease];
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
            return [[(RKTestUser *)object userID] isEqualToNumber:self.userID];
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
