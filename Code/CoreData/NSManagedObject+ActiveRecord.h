//
//  RKManagedObject+ActiveRecord.h
//
//  Adapted from https://github.com/magicalpanda/MagicalRecord
//  Created by Saul Mora on 11/15/09.
//  Copyright 2010 Magical Panda Software, LLC All rights reserved.
//
//  Created by Chad Podoski on 3/18/11.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (ActiveRecord)

/**
 * The Core Data managed object context from the RKObjectManager's objectStore
 * that is managing this model
 */
+ (NSManagedObjectContext*)managedObjectContext;

/**
 *	The NSEntityDescription for the Subclass 
 *	defaults to the subclass className, may be overridden
 */
+ (NSEntityDescription*)entity;

/**
 *	Returns an initialized NSFetchRequest for the entity, with no predicate
 */
+ (NSFetchRequest*)fetchRequest;

/**
 * Fetches all objects from the persistent store identified by the fetchRequest
 */
+ (NSArray*)objectsWithFetchRequest:(NSFetchRequest*)fetchRequest;

/**
 * Fetches all objects from the persistent store via a set of fetch requests and
 * returns all results in a single array.
 */
+ (NSArray*)objectsWithFetchRequests:(NSArray*)fetchRequests;

/**
 * Fetches the first object identified by the fetch request. A limit of one will be
 * applied to the fetch request before dispatching.
 */
+ (id)objectWithFetchRequest:(NSFetchRequest*)fetchRequest;

/**
 * Fetches all objects from the persistent store by constructing a fetch request and
 * applying the predicate supplied. A short-cut for doing filtered searches on the objects
 * of this class under management.
 */
+ (NSArray*)objectsWithPredicate:(NSPredicate*)predicate;

/**
 * Fetches the first object matching a predicate from the persistent store. A fetch request
 * will be constructed for you and a fetch limit of 1 will be applied.
 */
+ (id)objectWithPredicate:(NSPredicate*)predicate;

/**
 * Fetches all managed objects of this class from the persistent store as an array
 */
+ (NSArray*)allObjects;

/**
 * Returns a count of all managed objects of this class in the persistent store. On
 * error, will populate the error argument
 */
+ (NSUInteger)count:(NSError**)error;

/**
 * Returns a count of all managed objects of this class in the persistent store. Deprecated
 * use the error form above
 *
 * @deprecated
 */
+ (NSUInteger)count DEPRECATED_ATTRIBUTE;

/**
 *	Creates a new managed object and inserts it into the managedObjectContext.
 */
+ (id)object;

/**
 * Returns YES when an object has not been saved to the managed object context yet
 */
- (BOOL)isNew;

////////////////////////////////////////////////////////////////////////////////////////////////////

+ (NSManagedObjectContext*)currentContext;

+ (void)handleErrors:(NSError *)error;

+ (NSArray *)executeFetchRequest:(NSFetchRequest *)request;
+ (NSArray *)executeFetchRequest:(NSFetchRequest *)request inContext:(NSManagedObjectContext *)context;
+ (NSFetchRequest *)createFetchRequest;
+ (NSFetchRequest *)createFetchRequestInContext:(NSManagedObjectContext *)context;
+ (NSEntityDescription *)entityDescription;
+ (NSEntityDescription *)entityDescriptionInContext:(NSManagedObjectContext *)context;
+ (NSArray *)propertiesNamed:(NSArray *)properties;

+ (id)createEntity;
+ (id)createInContext:(NSManagedObjectContext *)context;
- (BOOL)deleteEntity;
- (BOOL)deleteInContext:(NSManagedObjectContext *)context;

+ (BOOL)truncateAll;
+ (BOOL)truncateAllInContext:(NSManagedObjectContext *)context;

+ (NSArray *)ascendingSortDescriptors:(id)attributesToSortBy, ...;
+ (NSArray *)descendingSortDescriptors:(id)attributesToSortyBy, ...;

+ (NSNumber *)numberOfEntities;
+ (NSNumber *)numberOfEntitiesWithContext:(NSManagedObjectContext *)context;
+ (NSNumber *)numberOfEntitiesWithPredicate:(NSPredicate *)searchTerm;
+ (NSNumber *)numberOfEntitiesWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context;

+ (BOOL) hasAtLeastOneEntity;
+ (BOOL) hasAtLeastOneEntityInContext:(NSManagedObjectContext *)context;

+ (NSFetchRequest *)requestAll;
+ (NSFetchRequest *)requestAllInContext:(NSManagedObjectContext *)context;
+ (NSFetchRequest *)requestAllWhere:(NSString *)property isEqualTo:(id)value;
+ (NSFetchRequest *)requestAllWhere:(NSString *)property isEqualTo:(id)value inContext:(NSManagedObjectContext *)context;
+ (NSFetchRequest *)requestFirstWithPredicate:(NSPredicate *)searchTerm;
+ (NSFetchRequest *)requestFirstWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context;
+ (NSFetchRequest *)requestFirstByAttribute:(NSString *)attribute withValue:(id)searchValue;
+ (NSFetchRequest *)requestFirstByAttribute:(NSString *)attribute withValue:(id)searchValue inContext:(NSManagedObjectContext *)context;
+ (NSFetchRequest *)requestAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending;
+ (NSFetchRequest *)requestAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context;
+ (NSFetchRequest *)requestAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm;
+ (NSFetchRequest *)requestAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context;

+ (NSArray *)findAll;
+ (NSArray *)findAllInContext:(NSManagedObjectContext *)context;
+ (NSArray *)findAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending;
+ (NSArray *)findAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context;
+ (NSArray *)findAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm;
+ (NSArray *)findAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context;
+ (NSFetchRequest *)requestAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context;

+ (NSArray *)findAllWithPredicate:(NSPredicate *)searchTerm;
+ (NSArray *)findAllWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context;

+ (NSNumber *)maxValueFor:(NSString *)property;
+ (id) objectWithMinValueFor:(NSString *)property;
+ (id) objectWithMinValueFor:(NSString *)property inContext:(NSManagedObjectContext *)context;

+ (id)findFirst;
+ (id)findFirstInContext:(NSManagedObjectContext *)context;
+ (id)findFirstWithPredicate:(NSPredicate *)searchTerm;
+ (id)findFirstWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context;
+ (id)findFirstWithPredicate:(NSPredicate *)searchterm sortedBy:(NSString *)property ascending:(BOOL)ascending;
+ (id)findFirstWithPredicate:(NSPredicate *)searchterm sortedBy:(NSString *)property ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context;
+ (id)findFirstWithPredicate:(NSPredicate *)searchTerm andRetrieveAttributes:(NSArray *)attributes;
+ (id)findFirstWithPredicate:(NSPredicate *)searchTerm andRetrieveAttributes:(NSArray *)attributes inContext:(NSManagedObjectContext *)context;
+ (id)findFirstWithPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortBy ascending:(BOOL)ascending andRetrieveAttributes:(id)attributes, ...;
+ (id)findFirstWithPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortBy ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context andRetrieveAttributes:(id)attributes, ...;

+ (id)findFirstByAttribute:(NSString *)attribute withValue:(id)searchValue;
+ (id)findFirstByAttribute:(NSString *)attribute withValue:(id)searchValue inContext:(NSManagedObjectContext *)context;
+ (NSArray *)findByAttribute:(NSString *)attribute withValue:(id)searchValue;
+ (NSArray *)findByAttribute:(NSString *)attribute withValue:(id)searchValue inContext:(NSManagedObjectContext *)context;
+ (NSArray *)findByAttribute:(NSString *)attribute withValue:(id)searchValue andOrderBy:(NSString *)sortTerm ascending:(BOOL)ascending;
+ (NSArray *)findByAttribute:(NSString *)attribute withValue:(id)searchValue andOrderBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context;

#if TARGET_OS_IPHONE

+ (NSFetchedResultsController *)fetchAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm groupBy:(NSString *)groupingKeyPath;
+ (NSFetchedResultsController *)fetchAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm groupBy:(NSString *)groupingKeyPath inContext:(NSManagedObjectContext *)context;

+ (NSFetchedResultsController *)fetchRequest:(NSFetchRequest *)request groupedBy:(NSString *)group;
+ (NSFetchedResultsController *)fetchRequest:(NSFetchRequest *)request groupedBy:(NSString *)group inContext:(NSManagedObjectContext *)context;

+ (NSFetchedResultsController *)fetchRequestAllGroupedBy:(NSString *)group withPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending;
+ (NSFetchedResultsController *)fetchRequestAllGroupedBy:(NSString *)group withPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context;

#endif

@end
