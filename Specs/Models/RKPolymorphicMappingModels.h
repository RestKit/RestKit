//
//  RKPolymorphicMappingModels.h
//  RestKit
//
//  Created by Blake Watters on 7/28/11.
//  Copyright 2011 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Person : NSObject
@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSArray* friends;
@end

@interface Boy : Person
@end

@interface Girl : Person
@end
