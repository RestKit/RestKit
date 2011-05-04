//
//  RKDynamicRouter.m
//  RestKit
//
//  Created by Blake Watters on 10/18/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKDynamicRouter.h"
#import "RKDynamicRouter.h"
#import "NSDictionary+RKRequestSerialization.h"

@implementation RKDynamicRouter

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

- (NSString*)resourcePathForObject:(NSObject<RKObjectMappable>*)object method:(RKRequestMethod)method {
	NSString* methodName = [self HTTPVerbForMethod:method];
	NSString* className  = NSStringFromClass([object class]);
	NSDictionary* classRoutes = [_routes objectForKey:className];
	
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

- (void)handlePrimaryKeyWithClass:(Class)objectClass andAttributes:(NSMutableDictionary*)attributes forObject:(id)object {
    if ([objectClass respondsToSelector:@selector(primaryKeyProperty)]) { 
        NSString *primaryKey = [objectClass performSelector:@selector(primaryKeyProperty)]; 
        id primaryKeyValue = [object valueForKey:primaryKey]; 
        NSString* primaryKeyValueString = [NSString stringWithFormat:@"%@", primaryKeyValue];
        
        // Primary key value isn't defined
        if (primaryKeyValue == nil || [primaryKeyValueString isEqualToString:@"0"]) { 
            // Exclude id
            [attributes removeObjectForKey:@"id"];
        }
    }
}

- (NSObject<RKRequestSerializable>*)serializationForObject:(NSObject<RKObjectMappable>*)object method:(RKRequestMethod)method {
    // Don't return a serialization for a GET request
    // There is an extensive discussion about this on the ASIHTTPRequest list
    // See http://groups.google.com/group/asihttprequest/browse_thread/thread/ef79a8333dde6acb
    if (method == RKRequestMethodGET) {
        return nil;
    }
    
	// set up dictionary containers
	NSDictionary* elementsAndProperties = [object propertiesForSerialization];
    NSDictionary* relationships = [object relationshipsForSerialization];
    int propertyCount = [elementsAndProperties count];
    int relationshipCount = [relationships count];
    int entryCount = propertyCount + relationshipCount;
	NSMutableDictionary* resourceParams = [NSMutableDictionary dictionaryWithCapacity:entryCount];	
	
    // add elements and properties
	for (NSString* elementName in [elementsAndProperties allKeys]) {
		id value = [elementsAndProperties valueForKey:elementName];
		NSString* attributeName = [elementName stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
		if (![attributeName isEqualToString:@"id"]) {
			NSString* keyName = [NSString stringWithFormat:@"%@", attributeName];
			[resourceParams setValue:value forKey:keyName];
		}
	}
    
    // add nested relationships
    for (NSString* elementName in [relationships allKeys]) {
        NSObject *relationship = [relationships objectForKey:elementName];
        NSString *relationshipPath = [NSString stringWithFormat:@"%@", elementName];
        // to-many relation 
        if ([relationship isKindOfClass:[NSArray class]] || 
            [relationship isKindOfClass:[NSSet class]]) { 
            NSMutableArray *children = [NSMutableArray array]; 
            for (id child in (NSEnumerator *)relationship) { 
                Class class = [child class];
                NSMutableDictionary* childAttributes = [RKObjectMappableGetPropertiesByElement(child) mutableCopy];                
                [self handlePrimaryKeyWithClass:class andAttributes:childAttributes forObject:child];
                
                [children addObject:[NSDictionary dictionaryWithDictionary:childAttributes]];
            } 
            
            [resourceParams setValue:children 
                              forKey:relationshipPath]; 
        // to-one relation
        } else {
            Class class = [relationship class];
            NSMutableDictionary* childAttributes = [RKObjectMappableGetPropertiesByElement(relationship) mutableCopy];
            [self handlePrimaryKeyWithClass:class andAttributes:childAttributes forObject:relationship];
            [resourceParams setValue:childAttributes 
                              forKey:relationshipPath]; 
        }
        
	}

	return resourceParams;

}

@end
