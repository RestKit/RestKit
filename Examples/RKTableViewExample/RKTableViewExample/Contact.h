//
//  Contact.h
//  RKTableViewExample
//
//  Created by Blake Watters on 8/3/11.
//  Copyright 2011 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Contact : NSObject

@property (nonatomic, copy)     NSString* firstName;
@property (nonatomic, copy)     NSString* lastName;
@property (nonatomic, readonly) NSString* fullName;
@property (nonatomic, copy)     NSString* emailAddress;

@end
