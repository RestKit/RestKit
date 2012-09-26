//
//  RKTestAddress.h
//  RestKit
//
//  Created by Blake Watters on 8/5/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RKTestAddress : NSObject {
    NSNumber *_addressID;
    NSString *_city;
    NSString *_state;
    NSString *_country;
}

@property (nonatomic, strong) NSNumber *addressID;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *state;
@property (nonatomic, strong) NSString *country;

+ (RKTestAddress *)address;

@end
