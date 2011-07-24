//
//  RKObjectRouter.m
//  RestKit
//
//  Created by Blake Watters on 10/18/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKObjectRouter.h"
#import "RKClient.h"
#import "NSDictionary+RKRequestSerialization.h"

@implementation RKObjectRouter

- (id)init {
	if ((self = [super init])) {
		_routes = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (void)dealloc {
	[_routes release];
	[super dealloc];
}

- (void)routeClass:(Class)class toResourcePath:(NSString*)resourcePath forMethodName:(NSString*)methodName {
	NSString* className = NSStringFromClass(class);
	if (nil == [_routes objectForKey:class]) {
		NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
		[_routes setObject:dictionary forKey:class];		 
	}
	
	NSMutableDictionary* classRoutes = [_routes objectForKey:class];
	if ([classRoutes objectForKey:methodName]) {
		[NSException raise:nil format:@"A route has already been registered for class '%@' and HTTP method '%@'", className, methodName];
	}
	
	[classRoutes setValue:resourcePath forKey:methodName];
}

- (NSString*)HTTPVerbForMethod:(RKRequestMethod)method {
	switch (method) {
		case RKRequestMethodGET:
			return @"GET";
			break;
		case RKRequestMethodPOST:
			return @"POST";
			break;
		case RKRequestMethodPUT:
			return @"PUT";
			break;
		case RKRequestMethodDELETE:
			return @"DELETE";
			break;
		default:
			return nil;
			break;
	}
}

// Public

- (void)routeClass:(Class)class toResourcePath:(NSString*)resourcePath {
	[self routeClass:class toResourcePath:resourcePath forMethodName:@"ANY"];
}

- (void)routeClass:(Class)class toResourcePath:(NSString*)resourcePath forMethod:(RKRequestMethod)method {
	NSString* methodName = [self HTTPVerbForMethod:method];
	[self routeClass:class toResourcePath:resourcePath forMethodName:methodName];
}

#pragma mark RKRouter

- (NSString*)resourcePathForObject:(NSObject*)object method:(RKRequestMethod)method {
	NSString* methodName = [self HTTPVerbForMethod:method];
	NSString* className  = NSStringFromClass([object class]);    
	NSDictionary* classRoutes = nil;
    
    // Check for exact matches
    for (Class possibleClass in _routes) {
        if ([object isMemberOfClass:possibleClass]) {
            classRoutes = [_routes objectForKey:possibleClass];
            break;
        }
    }
    
    // Check for superclass matches
    if (! classRoutes) {
        for (Class possibleClass in _routes) {
            if ([object isKindOfClass:possibleClass]) {
                classRoutes = [_routes objectForKey:possibleClass];
                break;
            }
        }
    }
	
	NSString* resourcePath = nil;
	if ((resourcePath = [classRoutes objectForKey:methodName])) {
		return RKMakePathWithObject(resourcePath, object);
	}
	
	if ((resourcePath = [classRoutes objectForKey:@"ANY"])) {
		return RKMakePathWithObject(resourcePath, object);
	}
	
	[NSException raise:nil format:@"Unable to find a routable path for object of type '%@' for HTTP Method '%@'", className, methodName];
	
	return nil;
}

@end
