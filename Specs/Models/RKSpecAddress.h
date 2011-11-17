//
//  RKSpecAddress.h
//  RestKit
//
//  Created by Blake Watters on 8/5/11.
//  Copyright 2011 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RKSpecAddress : NSObject {
    NSNumber* _addressID;
    NSString* _city;
    NSString* _state;
    NSString* _country;
}

@property (nonatomic, retain) NSNumber* addressID;
@property (nonatomic, retain) NSString* city;
@property (nonatomic, retain) NSString* state;
@property (nonatomic, retain) NSString* country;

+ (RKSpecAddress*)address;

@end
