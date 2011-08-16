//
//  RKObjectPropertyInspector+CoreData.h
//  RestKit
//
//  Created by Blake Watters on 8/14/11.
//  Copyright (c) 2011 RestKit. All rights reserved.
//

#import "../ObjectMapping/RKObjectPropertyInspector.h"

@interface RKObjectPropertyInspector (CoreData)

- (NSDictionary *)propertyNamesAndTypesForEntity:(NSEntityDescription*)entity;

/**
 Returns the Class type of the specified property on the object class
 */
- (Class)typeForProperty:(NSString*)propertyName ofEntity:(NSEntityDescription*)entity;

@end
