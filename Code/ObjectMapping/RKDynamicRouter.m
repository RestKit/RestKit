//
//  RKDynamicRouter.m
//  RestKit
//
//  Created by Blake Watters on 10/18/10.
//
//

#import "RKDynamicRouter.h"
#import "RKDynamicRouter.h"
#import "NSDictionary+RKRequestSerialization.h"

@implementation RKDynamicRouter

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

- (void)routeClass:(Class)class toResourcePath:(NSString*)resourcePath forMethodName:(NSString*)methodName {
	NSString* className = NSStringFromClass(class);
	if (nil == [_routes objectForKey:className]) {
		NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
		[_routes setObject:dictionary forKey:className];		 
	}
	
	NSMutableDictionary* classRoutes = [_routes objectForKey:className];
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

- (void)routeClass:(Class<RKObjectMappable>)class toResourcePath:(NSString*)resourcePath {
	[self routeClass:class toResourcePath:resourcePath forMethodName:@"ANY"];
}

- (void)routeClass:(Class)class toResourcePath:(NSString*)resourcePath forMethod:(RKRequestMethod)method {
	NSString* methodName = [self HTTPVerbForMethod:method];
	[self routeClass:class toResourcePath:resourcePath forMethodName:methodName];
}

#pragma mark RKRouter

- (NSString*)resourcePath:(NSString*)resourcePath withPropertiesInterpolatedForObject:(NSObject<RKObjectMappable>*)object {
	NSMutableDictionary* substitutions = [NSMutableDictionary dictionary];
	NSScanner* scanner = [NSScanner scannerWithString:resourcePath];
	
	BOOL startsWithParentheses = [[resourcePath substringToIndex:1] isEqualToString:@"("];
	while ([scanner isAtEnd] == NO) {
		NSString* keyPath = nil;
		if (startsWithParentheses || [scanner scanUpToString:@"(" intoString:nil]) {
			// Advance beyond the opening parentheses
			if (NO == [scanner isAtEnd]) {
				[scanner setScanLocation:[scanner scanLocation] + 1];
			}
			if ([scanner scanUpToString:@")" intoString:&keyPath]) {
				NSString* searchString = [NSString stringWithFormat:@"(%@)", keyPath];
				NSString* propertyStringValue = [NSString stringWithFormat:@"%@", [object valueForKeyPath:keyPath]];
				[substitutions setObject:propertyStringValue forKey:searchString];
			}
		}
	}
	
	if (0 == [substitutions count]) {
		return resourcePath;
	}
	
	NSMutableString* interpolatedResourcePath = [[resourcePath mutableCopy] autorelease];
	for (NSString* find in substitutions) {
		NSString* replace = [substitutions valueForKey:find];
		[interpolatedResourcePath replaceOccurrencesOfString:find withString:replace 
													 options:NSLiteralSearch range:NSMakeRange(0, [interpolatedResourcePath length])];
	}
	
	return [NSString stringWithString:interpolatedResourcePath];
}

- (NSString*)resourcePathForObject:(NSObject<RKObjectMappable>*)object method:(RKRequestMethod)method {
	NSString* methodName = [self HTTPVerbForMethod:method];
	NSString* className  = NSStringFromClass([object class]);
	NSDictionary* classRoutes = [_routes objectForKey:className];
	
	NSString* resourcePath = nil;
	if (resourcePath = [classRoutes objectForKey:methodName]) {
		return [self resourcePath:resourcePath withPropertiesInterpolatedForObject:object];
	}
	
	if (resourcePath = [classRoutes objectForKey:@"ANY"]) {
		return [self resourcePath:resourcePath withPropertiesInterpolatedForObject:object];
	}
	
	[NSException raise:nil format:@"Unable to find a routable path for object of type '%@' for HTTP Method '%@'", className, methodName];
	
	return nil;
}

- (NSObject<RKRequestSerializable>*)serializationForObject:(NSObject<RKObjectMappable>*)object method:(RKRequestMethod)method {
	// By default return a form encoded serializable dictionary
	return [object paramsForSerialization];
}

@end
