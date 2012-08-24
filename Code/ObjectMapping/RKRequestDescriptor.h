//
//  RKRequestDescriptor.h
//  RestKit
//
//  Created by Blake Watters on 8/24/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RKMapping;

@interface RKRequestDescriptor : NSObject

+ (id)requestDescriptorWithMapping:(RKMapping *)mapping
                       objectClass:(Class)objectClass
                       rootKeyPath:(NSString *)rootKeyPath;

@property (nonatomic, strong, readonly) RKMapping *mapping;
@property (nonatomic, strong, readonly) Class objectClass;
@property (nonatomic, copy, readonly) NSString *rootKeyPath;

@end
