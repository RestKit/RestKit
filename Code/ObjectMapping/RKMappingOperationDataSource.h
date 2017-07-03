//
//  RKMappingOperationDataSource.h
//  RestKit
//
//  Created by Blake Watters on 7/3/12.
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

#import <Foundation/Foundation.h>

@class RKObjectMapping, RKMappingOperation, RKRelationshipMapping;

/**
 An object that adopts the `RKMappingOperationDataSource` protocol is responsible for the retrieval or creation of target objects within an `RKMapperOperation` or `RKMappingOperation`. A data source is responsible for meeting the requirements of the underlying data store implementation and must return a key-value coding compliant object instance that can be used as the target object of a mapping operation. It is also responsible for commiting any changes necessary to the underlying data store once a mapping operation has completed its work.

 At a minimum, a data source must implement the `mappingOperation:targetObjectForRepresentation:withMapping:` method. This method is responsible for finding an existing object instance to be updated or creating a new object if no existing object could be found or the underlying data store does not support persistence. Object mapping operations which target `NSObject` derived classes will always result in mapping to new transient objects, while persistent data stores such as Core Data can be queried to retrieve existing objects for update.

 @see `RKManagedObjectMappingOperationDataSource`
 */
@protocol RKMappingOperationDataSource <NSObject>

@required

/**
 Asks the data source for the target object for an object mapping operation given an `NSDictionary` representation of the object's properties and the mapping object that will be used to perform the mapping.

 The `representation` value is a fragment of content from a deserialized response that has been identified as containing content that is mappable using the given mapping.

 @param mappingOperation The mapping operation requesting the target object.
 @param representation A dictionary representation of the properties to be mapped onto the retrieved target object.
 @param mapping The object mapping to be used to perform a mapping from the representation to the target object.
 @return A key-value coding compliant object to perform the mapping on to.
 */
- (id)mappingOperation:(RKMappingOperation *)mappingOperation targetObjectForRepresentation:(NSDictionary *)representation withMapping:(RKObjectMapping *)mapping inRelationship:(RKRelationshipMapping *)relationshipMapping;

@optional

/**
 Asks the data source for the target object for an object mapping operation the mapping object that will be used to perform the mapping.
 
 If not implemented or it returns nil, then the
  `mappingOperation:targetObjectForRepresentation:withMapping:inRelationship:` method will be called to determine the target.
 
 It is preferable to implement this method if the `representation` is not needed to determine the target object,
 as obtaining that value is somewhat expensive.
 
 @param mappingOperation The mapping operation requesting the target object.
 @param mapping The object mapping to be used to perform a mapping from the representation to the target object.
 @param relationshipMapping A dictionary representation of the properties to be mapped onto the retrieved target object.
 @return A key-value coding compliant object to perform the mapping on to.
 */
- (id)mappingOperation:(RKMappingOperation *)mappingOperation targetObjectForMapping:(RKObjectMapping *)mapping inRelationship:(RKRelationshipMapping *)relationshipMapping;


/**
 Tells the data source to commit any changes to the underlying data store.

 @param mappingOperation The mapping operation that has completed its work.
 @param error A pointer to an error to be set in the event that the mapping operation could not be committed.
 @return A Boolean value indicating if the changes for the mapping operation were committed successfully.
 */
- (BOOL)commitChangesForMappingOperation:(RKMappingOperation *)mappingOperation error:(NSError **)error;

/**
 Tells the data source to delete the existing value for a relationship that has been mapped with an assignment policy of `RKReplaceAssignmentPolicy`.
 
 @param mappingOperation The mapping operation that is executing.
 @param relationshipMapping The relationship mapping for which the existing value is being replaced.
 @param error A pointer to an error to be set in the event that the deletion operation could not be completed.
 @return A Boolean value indicating if the existing objects for the relationship were successfully deleted.
 */
- (BOOL)mappingOperation:(RKMappingOperation *)mappingOperation deleteExistingValueOfRelationshipWithMapping:(RKRelationshipMapping *)relationshipMapping error:(NSError **)error;

/**
 Asks the data source if it should set values for properties without checking that the value has been changed. This method can result in a performance improvement during mapping as the mapping operation will not attempt to assess the change state of the property being mapped.
 
 If this method is not implemented by the data source, then the mapping operation defaults to `NO`.
 
 @param mappingOperation The mapping operation that is querying the data source.
 @return `YES` if the mapping operation should disregard property change status, else `NO`.
 */
- (BOOL)mappingOperationShouldSetUnchangedValues:(RKMappingOperation *)mappingOperation;

/**
 **Deprecated in v0.26.0**
 Asks the data source if it should skip mapping. This method can significantly improve performance if, for example, the data source has determined that the properties in the representation are not newer than the current target object's properties. See `modificationAttribute` in `RKEntityMapping` for an example of when skipping property mapping would be appropriate.
 
 If this method is not implemented by the data source, then the mapping operation defaults to `NO`.
 
 @param mappingOperation The mapping operation that is querying the data source.
 @return `YES` if the mapping operation should skip mapping properties, else `NO`.
 */
- (BOOL)mappingOperationShouldSkipPropertyMapping:(RKMappingOperation *)mappingOperation DEPRECATED_MSG_ATTRIBUTE("use mappingOperationShouldSkipAttributeMapping: and mappingOperationShouldSkipRelationshipMapping: instead");

/**
 Asks the data source if it should skip mapping attributes. This method can significantly improve performance if, for example, the data source has determined that the attributes in the representation are not newer than the current target object's attributes. See `modificationAttribute` in `RKEntityMapping` for an example of when skipping attribute mapping would be appropriate.
 
 If this method is not implemented by the data source, then the mapping operation defaults to `NO`.
 
 @param mappingOperation The mapping operation that is querying the data source.
 @return `YES` if the mapping operation should skip mapping attributes, else `NO`.
 */
- (BOOL)mappingOperationShouldSkipAttributeMapping:(RKMappingOperation *)mappingOperation;

/**
 Asks the data source if it should skip mapping relationships. This method can significantly improve performance if, for example, the data source has determined that the relationships in the representation are not newer than the current target object's relationships. See `modificationAttribute` and `shouldMapRelationshipsIfObjectIsUnmodified` in `RKEntityMapping` for an example of when skipping relationship mapping might be appropriate.
 
 If this method is not implemented by the data source, then the mapping operation defaults to `NO`.
 
 @param mappingOperation The mapping operation that is querying the data source.
 @return `YES` if the mapping operation should skip mapping relationships, else `NO`.
 */
- (BOOL)mappingOperationShouldSkipRelationshipMapping:(RKMappingOperation *)mappingOperation;

/**
 Asks the data source if the mapping operation should collect `RKMappingInfo` information during the mapping
 (stored in the `mappingInfo` property).  If not needed, it can be a substantially faster to skip it.  The
 `mappingInfo` property will be nil if not collected.

 If this method is not implemented by the data source, then the mapping operation defaults to `YES`.
 
 @param mappingOperation The mapping operation that is querying the data source.
 @return `YES` if the mapping operation should collect mapping information, else `NO`.
*/
- (BOOL)mappingOperationShouldCollectMappingInfo:(RKMappingOperation *)mappingOperation;

@end
