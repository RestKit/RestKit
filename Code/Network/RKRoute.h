//
//  RKRoute.h
//  RestKit
//
//  Created by Blake Watters on 5/31/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKRequest.h"

// Class cluster. Not to be directly instantiated.
@interface RKRoute : NSObject

@property (nonatomic, retain, readonly) NSString *name;
@property (nonatomic, retain, readonly) Class objectClass;
@property (nonatomic, assign, readonly) RKRequestMethod method;
@property (nonatomic, retain, readonly) NSString *resourcePathPattern;

@property (nonatomic, assign) BOOL shouldEscapeResourcePath; // when YES, the path will be escaped when interpolated

+ (id)routeWithName:(NSString *)name resourcePathPattern:(NSString *)resourcePathPattern method:(RKRequestMethod)method;
+ (id)routeWithClass:(Class)objectClass resourcePathPattern:(NSString *)resourcePathPattern method:(RKRequestMethod)method;
+ (id)routeWithRelationshipName:(NSString *)name objectClass:(Class)objectClass resourcePathPattern:(NSString *)resourcePathPattern method:(RKRequestMethod)method;

- (BOOL)isNamedRoute;
- (BOOL)isClassRoute;
- (BOOL)isRelationshipRoute;

- (NSString *)resourcePathForObject:(id)object;

@end
