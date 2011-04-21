//
//  RKRailsRouter.m
//  RestKit
//
//  Created by Blake Watters on 10/18/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKRailsRouter.h"
#import "../Support/NSString+InflectionSupport.h"

@implementation RKRailsRouter

- (id)init {
    self = [super init];
	if (self) {
		_classToModelMappings = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (void)dealloc {
	[_classToModelMappings release];	
	[super dealloc];
}

- (void)setModelName:(NSString*)modelName forClass:(Class<RKObjectMappable>)class {
	[_classToModelMappings setObject:modelName forKey:class];
}

#pragma mark RKRouter

- (NSObject<RKRequestSerializable>*)serializationForObject:(NSObject<RKObjectMappable>*)object method:(RKRequestMethod)method {
	// Rails does not send parameters for delete requests.
	if (method == RKRequestMethodDELETE) {
		return nil;
	}
	
    // set up dictionary containers
	NSDictionary* elementsAndProperties = [object propertiesForSerialization];
    NSDictionary* relationships = [object relationshipsForSerialization];
    int entryCount = [elementsAndProperties count] + [relationships count];
	NSMutableDictionary* resourceParams = [NSMutableDictionary dictionaryWithCapacity:entryCount];	
	
    // set up model name
    NSString* modelName = [_classToModelMappings objectForKey:[object class]];
	if (nil == modelName) {
		NSString* className = NSStringFromClass([object class]);
		[NSException raise:nil format:@"Unable to find registered modelName for class '%@'", className];
	}
	NSString* underscoredModelName = [modelName underscore];
	
    // add elements and properties
	for (NSString* elementName in [elementsAndProperties allKeys]) {
		id value = [elementsAndProperties valueForKey:elementName];
		NSString* attributeName = [elementName stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
		if (![attributeName isEqualToString:@"id"]) {
			NSString* keyName = [NSString stringWithFormat:@"%@[%@]", underscoredModelName, attributeName];
			[resourceParams setValue:value forKey:keyName];
		}
	}
    
    // add nested relationships
    for (NSString* elementName in [relationships allKeys]) {
        NSDictionary *relationshipElements = [relationships objectForKey:elementName];
        @try { 
            //for each item in this collection, add an entry with the primary key 
            //if the property is an array, set or dict, findorcreate the related item 
            if ([relationshipElements isKindOfClass:[NSArray class]] || 
                [relationshipElements isKindOfClass:[NSSet class]]) { 
                NSMutableArray *children = [NSMutableArray array]; 
                for (id child in relationshipElements) { 
                    //get the primary key for this object 
                    Class class = [child class]; 
                    if ([class respondsToSelector:@selector(primaryKeyProperty)]) { 
                        NSString* primaryKey = [class performSelector:@selector(primaryKeyProperty)]; 
                        id primaryKeyValue = [child valueForKey:primaryKey]; 
                        NSString* primaryKeyValueString = [NSString stringWithFormat:@"%@", primaryKeyValue];
                        if (primaryKeyValue == nil || [primaryKeyValueString isEqualToString:@"0"]) { 
                            // add child attributes, excluding id
                            NSMutableDictionary* childAttributes = [RKObjectMappableGetPropertiesByElement(child) mutableCopy];
                            [childAttributes removeObjectForKey:@"id"];
                            [children addObject:[NSDictionary dictionaryWithDictionary:childAttributes]];
                        } else { 
                            // add child attributes, including id
                            [children addObject:RKObjectMappableGetPropertiesByElement(child)];
                        } 
                    } else { 
                        NSLog(@"ERROR: expected %@ to respond to primaryKeyProperty", child); 
                    } 
                } 
                NSString *railsRelationshipPath = [NSString stringWithFormat:@"%@[%@_attributes]", 
                                                   underscoredModelName, elementName];
                [resourceParams setValue:children 
                                  forKey:railsRelationshipPath]; 
            } 
        } 
        @catch (NSException* e) { 
            NSLog(@"Caught exception:%@ when trying valueForKey with property: %@ for object:%@", e, elementName, object); 
        }
	}
	
	return resourceParams;
}

@end
