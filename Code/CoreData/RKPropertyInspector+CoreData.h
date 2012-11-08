//
//  RKPropertyInspector+CoreData.h
//  RestKit
//
//  Created by Blake Watters on 8/14/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "RKPropertyInspector.h"

/**
 The `CoreData` category augments the `RKPropertyInspector` class with support for introspecting the property types for `NSManagedObject` and `NSEntityDescription` objects.
 */
@interface RKPropertyInspector (CoreData)

/**
 Returns a dictionary wherein the keys are the names of attribute and relationship properties and the values are the class used to represent the corresponding property for a given entity.
 
 @param entity The entity to retrieve the properties names and classes of.
 @return A dictionary containing the names and classes of the given entity.
 */
- (NSDictionary *)propertyNamesAndClassesForEntity:(NSEntityDescription *)entity;

/**
 Returns the class used to represent the property with the given name on the given entity.
 
 @param propertyName The name of the property to retrieve the class for.
 @param entity The entity containing the property to retrieve the class for.
 @return The class used to represent the property.
 */
- (Class)classForPropertyNamed:(NSString *)propertyName ofEntity:(NSEntityDescription *)entity;

@end
