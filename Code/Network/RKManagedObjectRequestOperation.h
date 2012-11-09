//
//  RKManagedObjectRequestOperation.h
//  RestKit
//
//  Created by Blake Watters on 8/9/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
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
#import "RKObjectRequestOperation.h"
#import "RKManagedObjectCaching.h"

/**
 `RKManagedObjectRequestOperation` is a subclass of `RKObjectRequestOperation` that implements object mapping on the response body of an `NSHTTPResponse` loaded via an `RKHTTPRequestOperation` in which the mapping targets `NSManagedObject` objects managed by Core Data.

 The `RKManagedObjectRequestOperation` class extends the basic behavior of an `RKObjectRequestOperation` to meet the constraints imposed by Core Data. In particular, managed object request operations observe the threading requirements by making use of `NSManagedObjectContext` concurrency types, leverage the support for parent/child contexts, and handle obtaining a permanent `NSManagedObjectID` for objects being mapped so that they are addressable across contexts. Object mapping is internally performed within a block provided to the target context via `performBlockAndWait:`, ensuring execution on the appropriate queue.

 Aside from providing the basic infrastructure for successful object mapping into Core Data, a number of additional Core Data specific features are provided by the `RKManagedObjectRequestOperation` class that warrant discussion in detail.

 ## Parent Context

 Every `RKManagedObjectRequestOperation` object must be assigned an `NSManagedObjectContext` in which to persist the results of the underlying object mapping operation. This context is used as the parent context for a new, private `NSManagedObjectContext` with a concurrency type of `NSPrivateQueueConcurrencyType` in which the object mapping is actually performed. The use of this parent context has a number of benefits:

 1. If the context that was assigned to the managed object request operation has a concurrency type of `NSMainQueueConcurrencyType`, then directly mapping into the context would block the execution of the main thread for the duration of the mapping process. The use of the private child context isolates the mapping process from the main thread entirely.
 1. In the event of an error, the private context can be discarded, leaving the state of the parent context unchanged. On successful completion, the private context is saved and 'pushes' its changes up one level into the parent context.

 ## Permanent Managed Object IDs

 One of the confounding factors when working with asycnhronous processes interacting with Core Data is the addressability of managed objects that have not been saved to the persistent store across contexts. Unpersisted `NSManagedObject` instances have an `objectID` that is temporary and unsuitable for use in uniquely addressing a given object across two managed object contexts, even if they have common ancestry and share a persistent store coordinator. To mitigate this addressability issue without requiring objects to be saved to the persistent store, managed object request operations invoke `obtainPermanentIDsForObjects:` on the operation's target object (if any) and all managed objects that were inserted into the context during the mapping process. By the time the operation finishes, all managed objects in the mapping result can be referenced by `objectID` across contexts with no further action.

 ## Primary Keys &amp; Managed Object Caching

 When object mapping managed objects it is necessary to differentiate between objects that already exist in the local store and those that are being created as part of the mapping process. This ensures that the local store does not become populated with duplicate records. To make this differentiation, RestKit requires that each `NSEntityDescription` be configured with a primary key attribute. The primary key must correspond to a static attribute assigned by the remote backend system. During mapping, this key is used to search the managed object context for an existing managed object. If one is found, the object is updated else a new object is created. Primary keys are configured at the entity level and additional discussion accompanies the `NSEntityDescription (RKAdditions)` category.

 Primary key attributes are used in conjunction with the `RKManagedObjectCaching` protocol. Each managed object request operation is associated with an object conforming to the `RKManagedObjectCaching` protocol via the `managedObjectCache` proeprty. This cache is consulted during mapping to find existing objects and when establishing relationships between entities by primary key. Please see the documentation accompanying `RKManagedObjectCaching` and `RKConnectionMapping` for more information.

 ## Deleting Managed Objects for `DELETE` requests

 `RKManagedObjectRequestOperation` adds special behavior to `DELETE` requests. Upon retrieving a successful (2xx status code) response for a `DELETE`, the operation will invoke `deleteObject:` with the operations `targetObject` on the managed object context. This will delete the target object from the local store in conjunction the successfully deleted remote representation.

 ## Fetch Request Blocks and Deleting Orphaned Objects

 A common problem when accessing remote resources representing collections of objects is the problem of deletion of remote objects. The `RKManagedObjectRequestOperation` class provides support for the cleanup of such orphaned objects. In order to utilize the functionality, the operation must be able to compare a set of reference objects to the retrieved payload in order to determine which objects exist in the local store, but are no longer being returned by the server. This reference set of objects is built by executing an `NSFetchRequest` that corresponds to the URL being loaded. Configuration of this fetch request is done via an `RKFetchRequestBlock` block object. This block takes a single `NSURL` argument and returns an `NSFetchRequest` objects. An array of these blocks can be provided to the managed object request operation and the array will be searched in reverse order until a non-nil value is returned by a block. Any block that cannot build a fetch request for the given URL is expected to return `nil` to indicate that it does not match the given URL. Processing of the URL is typically performed using an `RKPathMatcher` object against the value returned from the `relativePath` or `relativeString` methods of `NSURL`.

 To illustrate this concept, please consider the following real-world example which builds a fetch request for retrieving the Terminals that exist in an Airport:

    RKObjectManager *manager = [RKObjectManager managerWithBaseURL:@"http://restkit.org"];
    [manager addFetchRequestBlock:^NSFetchRequest *(NSURL *URL) {
        RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPattern:@"/airports/:airport_id/terminals.json"];

        NSDictionary *argsDict = nil;
        BOOL match = [pathMatcher matchesPath:[URL relativePath] tokenizeQueryStrings:NO parsedArguments:&argsDict];
        NSString *airportID;
        if (match) {
            airportID = [argsDict objectForKey:@"airport_id"];
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Terminal"];
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"Airport" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
            fetchRequest.predicate = [entity predicateForPrimaryKeyAttributeWithValue:airportID];
            fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES] ];
            return fetchRequest;
        }

        return nil;
    }];

 The above example code defines an `RKFetchRequestBlock` block object that will match an `NSURL` with a relative path matching the pattern `@"/airports/:airport_id/terminals.json"`. If a match is found, the block extracts the `airport_id` key from the matched arguments and uses it to construct an `NSPredicate` for the primary key attribute of `GGAirport` entity. It then constructs an `NSFetchRequest` for the `GGTerminal` entity that will retrieve all the managed objects with an airport ID attribute whose value is equal to `airport_id` encoded within the URL's path.

 In more concrete terms, given the URL `http://restkit.org/airports/1234/terminals.json` the block would return an `NSFetchRequest` equal to:

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Terminal"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"airportID = 1234"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];

 Once configured and registered with the object manager, any `RKManagedObjectRequestOperation` created through the manager will automatically consult the fetch request blocks and perform orphaned object cleanup. No cleanup is performed if no block in the `fetchRequestBlocks` property is found to match the URL of the request.

 ## Managed Object Context Save Behaviors

 The results of the operation can either be 'pushed' to the parent context or saved to the persistent store. Configuration is available via the `savesToPersistentStore` property. If an error is encountered while saving the managed object context, then the operation is considered to have failed and the `error` property will be set to the `NSError` object returned by the failed save.
 
 ## 304 'Not Modified' Responses
 
 In the event that a managed object request operation loads a 304 'Not Modified' response for an HTTP request no object mapping is performed as Core Data is assumed to contain a managed object representation of the resource requested. No object mapping is performed on the cached response body, making a cache hit for a managed object request operation a very lightweight operation. To build the mapping result returned to the caller, all of the fetch request blocks matching the request URL will be invoked and each fetch request returned is executed against the managed object context and the objects returned are added to the mapping result. Please note that all managed objects returned in the mapping result for a 'Not Modified' response will be returned under the `[NSNull null]` key path.

 ## Limitations and Caveats

 @warning `RKManagedObjectRequestOperation` **does NOT** support object mapping that targets an `NSManagedObjectContext` with a `concurrencyType` of `NSConfinementConcurrencyType`.

 @see `RKObjectRequestOperation`
 @see `RKEntityMapping`
 @see `RKManagedObjectResponseMapperOperation`
 */
@interface RKManagedObjectRequestOperation : RKObjectRequestOperation

///----------------------------------------
/// @name Configuring Core Data Integration
///----------------------------------------

/**
 The managed object context associated with the managed object request operation.

 This context acts as the parent context for a private managed object context in which the object mapping is performed and changes will be saved to this context upon successful completion of the operation.

 Please see the above discussion about 'Parent Context' for details.
 */
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

/**
 The managed object cache associated with the managed object request operation.

 The cache is used to look up existing objects by primary key to prevent the creation of duplicate objects during mapping. Please see the above discussion of 'Managed Object Caching' for more details.

 @warning A `nil` value for the `managedObjectCache` property is valid, but may result in the creation of duplicate objects.
 */
@property (nonatomic, weak) id<RKManagedObjectCaching> managedObjectCache;

/**
 An array of `RKFetchRequestBlock` block objects used to map `NSURL` objects into corresponding `NSFetchRequest` objects.

 Fetch requests corresponding to URL's are used when deleting orphaned objects and completing object request operations in which `avoidsNetworkAccess` has been set to `YES`. Please see the above discussion of 'Fetch Request Blocks' for more details.
 */
@property (nonatomic, copy) NSArray *fetchRequestBlocks;

///------------------------------------
/// @name Managing Completion Behaviors
///------------------------------------

/**
 A Boolean value that determines if the receiver will delete orphaned objects upon completion of the operation.

 Please see the above discussion of 'Deleting Managed Objects for `DELETE` requests' for more details.

 **Default**: `YES`
 */
@property (nonatomic, assign) BOOL deletesOrphanedObjects;

/**
 A Boolean value that determines if the operation saves the mapping results to the persistent store upon successful completion. If the network transport or mapping portions of the operation fail the operation then this option has no effect.
 
 When `YES`, the receiver will invoke `saveToPersistentStore:` on its private managed object context to persist the mapping results all the way back to the persistent store coordinator. If `NO`, the private mapping context will be saved causing the mapped objects to be 'pushed' to the parent context as represented by the `managedObjectContext` property.
 
 **Default**: `YES`
 */
@property (nonatomic, assign) BOOL savesToPersistentStore;

@end

/**
 A block object for returning an `NSFetchRequest` suitable for fetching the managed objects that corresponds to the contents of the resource at the given URL. It accepts a single `NSURL` argument and returns an `NSFetchRequest`.

 `RKFetchRequestBlock` objects are used to identify objects that exist in the local persistent store, but have been removed from the server-side. Such orphaned objects can optionally be auto-removed by `RKManagedObjectRequestOperation` objects.

 A block that returns `nil` is considered not to match the given URL.

 @param URL The URL object to build a fetch request for.
 @return An `NSFetchRequest` object corresponding to the given URL, or nil if the URL could not be processed.
 */
typedef NSFetchRequest *(^RKFetchRequestBlock)(NSURL *URL);

/**
 Returns an array of fetch request objects from an array of `RKFetchRequestBlock` objects given a URL.
 
 @param fetchRequestBlocks An array of `RKFetchRequestBlock` blocks to
 @param URL The URL for which to return a fetch request.
 @return An array of fetch requests from all blocks that match the given URL.
 */
NSArray *RKArrayOfFetchRequestFromBlocksWithURL(NSArray *fetchRequestBlocks, NSURL *URL);
