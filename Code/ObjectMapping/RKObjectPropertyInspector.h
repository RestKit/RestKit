//
//  RKObjectPropertyInspector.h
//  RestKit
//
//  Created by Blake Watters on 3/4/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface RKObjectPropertyInspector : NSObject {
	NSMutableDictionary* _cachedPropertyNamesAndTypes;
}

+ (RKObjectPropertyInspector*)sharedInspector;

/**
 * Returns a dictionary of names and types for the properties of a given class
 */
- (NSDictionary *)propertyNamesAndTypesForClass:(Class)objectClass;

/**
 Returns the Class type of the specified property on the object class
 */
- (Class)typeForProperty:(NSString*)propertyName ofClass:(Class)objectClass;

@end
