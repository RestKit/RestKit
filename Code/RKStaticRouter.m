//
//  RKStaticRouter.m
//  RestKit
//
//  Created by Blake Watters on 7/20/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKStaticRouter.h"

@implementation RKStaticRouter

- (id)init {
	if (self = [super init]) {
		_routes = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (void)dealloc {
	[_routes release];
	[super dealloc];
}

- (void)routeClass:(Class)class toPath:(NSString*)resourcePath forMethodName:(NSString*)methodName {
	NSString* className = NSStringFromClass(class);
	if (nil == [_routes objectForKey:className]) {
		NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
		[_routes setObject:dictionary forKey:className];		 
	}
	
	NSDictionary* classRoutes = [_routes objectForKey:className];
	if ([classRoutes objectForKey:methodName]) {
		[NSException raise:nil format:@"A route has already been registered for class '%@' and HTTP method '%@'", className, methodName];
	}
		
	[classRoutes setValue:resourcePath forKey:methodName];
}

// TODO: Should be RKStringFromRequestMethod and RKRequestMethodFromString
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

- (void)routeClass:(Class<RKResourceMappable>)class toPath:(NSString*)path {
	[self routeClass:class toPath:path forMethodName:@"ANY"];
}

- (void)routeClass:(Class)class toPath:(NSString*)path forMethod:(RKRequestMethod)method {
	NSString* methodName = [self HTTPVerbForMethod:method];
	[self routeClass:class toPath:path forMethodName:methodName];
}

#pragma mark RKRouter

- (NSString*)pathForObject:(NSObject<RKResourceMappable>*)object method:(RKRequestMethod)method {
	NSString* methodName = [self HTTPVerbForMethod:method];		
	NSString* className  = NSStringFromClass([object class]);		
	NSDictionary* classRoutes = [_routes objectForKey:className];
	
	NSString* path = nil;
	if (path = [classRoutes objectForKey:methodName]) {
		return path;
	}
	
	if (path = [classRoutes objectForKey:@"ANY"]) {
		return path;
	}
	
	[NSException raise:nil format:@"Unable to find a routable path for object of type '%@' for HTTP Method '%@'", className, methodName];

	return nil;
}

- (NSObject<RKRequestSerializable>*)serializationForObject:(NSObject<RKResourceMappable>*)object method:(RKRequestMethod)method {
	return [object paramsForSerialization];
}

@end
