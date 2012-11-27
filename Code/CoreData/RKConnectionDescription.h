//
//  RKConnectionDescription.h
//  RestKit
//
//  Created by Blake Watters on 11/20/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>

/**
 */
@interface RKConnectionDescription : NSObject <NSCopying>

@property (nonatomic, strong, readonly) NSRelationshipDescription *relationship;

- (id)initWithRelationship:(NSRelationshipDescription *)relationship attributes:(NSDictionary *)sourceToDestinationEntityAttributes;
- (id)initWithRelationship:(NSRelationshipDescription *)relationship keyPath:(NSString *)keyPath;

@property (nonatomic, copy, readonly) NSDictionary *attributes; // nil unless foreign key
- (BOOL)isForeignKeyConnection;

@property (nonatomic, copy, readonly) NSString *keyPath; // nil unless keyPath description
- (BOOL)isKeyPathConnection;

@end
