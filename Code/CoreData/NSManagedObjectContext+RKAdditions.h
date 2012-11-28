//
//  NSManagedObjectContext+RKAdditions.h
//  RestKit
//
//  Created by Blake Watters on 3/14/12.
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

#import <CoreData/CoreData.h>

@class RKManagedObjectStore;

/**
 Provides extensions to `NSManagedObjectContext` for various common tasks.
 */
@interface NSManagedObjectContext (RKAdditions)

///---------------------------------
/// @name Inserting a Managed Object
///---------------------------------

/**
 Inserts a new managed object for the entity for the given name.

 This method is functionally equivalent to the follow code example.

    [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self];

 @param entityName The name of an entity.
 @return A new, autoreleased, fully configured instance of the class for the entity named entityName. The instance has its entity description set and is inserted into the receiver.
 */
- (id)insertNewObjectForEntityForName:(NSString *)entityName;

///-------------------------------
/// @name Counting Managed Objects
///-------------------------------

/**
 Convenience method for performing a count of the number of instances of an entity with the given name.

 This method is functionally equivalent to the following code example.

    NSError *error;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
    fetchRequest.predicate = predicate;
    NSUInteger count = [managedObjectContext countForFetchRequest:fetchRequest error:&error];

 @param entityName The name of an entity.
 @param predicate A predicate to limit the search. May be nil.
 @param error If there is a problem executing the fetch, upon return contains an instance of NSError that describes the problem.
 @return The number of objects a fetch request for the given entity name with the given predicate would have returned if it had been passed to executeFetchRequest:error:, or NSNotFound if an error occurs.
 */
- (NSUInteger)countForEntityForName:(NSString *)entityName predicate:(NSPredicate *)predicate error:(NSError **)error;

///-------------------------------------------------
/// @name Saving the Context to the Persistent Store
///-------------------------------------------------

/**
 Saves the receiver and then traverses up the parent context chain until a parent managed object context with a nil parent is found. If the final ancestor context does not have a reference to the persistent store coordinator, then a warning is generated and the method returns NO.

 @param error If there is a problem saving the receiver or any of its ancestor contexts, upon return contains an pointer to an instance of NSError that describes the problem.
 @return YES if the save to the persistent store was successful, else NO.
 */
- (BOOL)saveToPersistentStore:(NSError **)error;

@end
