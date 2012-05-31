//
//  RKRoute.h
//  RestKit
//
//  Created by Blake Watters on 5/31/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKRequest.h"

@interface RKRoute : NSObject

@property (nonatomic, retain) NSString *name; // can be nil
@property (nonatomic, retain) Class objectClass; // can be nil
@property (nonatomic, assign) RKRequestMethod method;
@property (nonatomic, retain) NSString *resourcePathPattern;
@property (nonatomic, assign) BOOL shouldEscapeResourcePath; // when YES, the path will be escaped when interpolated

- (BOOL)isNamedRoute;
- (BOOL)isClassRoute;

@end
