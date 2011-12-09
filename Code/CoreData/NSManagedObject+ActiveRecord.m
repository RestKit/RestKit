//
//  NSManagedObject+ActiveRecord.m
//
//  Adapted from https://github.com/magicalpanda/MagicalRecord
//  Created by Saul Mora on 11/15/09.
//  Copyright 2010 Magical Panda Software, LLC All rights reserved.
//
//  Created by Chad Podoski on 3/18/11.
//

#import <objc/runtime.h>
#import "NSManagedObject+ActiveRecord.h"
#import "RKObjectManager.h"
#import "RKLog.h"
#import "RKFixCategoryBug.h"

RK_FIX_CATEGORY_BUG(NSManagedObject_ActiveRecord)

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitCoreData

static NSUInteger const kActiveRecordDefaultBatchSize = 10;
static NSNumber *defaultBatchSize = nil;

@implementation NSManagedObject (ActiveRecord)

#pragma mark - RKManagedObject methods

+ (NSManagedObjectContext*)managedObjectContext {
    NSAssert([RKObjectManager sharedManager], @"[RKObjectManager sharedManager] cannot be nil");
    NSAssert([RKObjectManager sharedManager].objectStore, @"[RKObjectManager sharedManager].objectStore cannot be nil");
	return [[[RKObjectManager sharedManager] objectStore] managedObjectContext];
}

+ (NSEntityDescription*)entity {
	NSString* className = [NSString stringWithCString:class_getName([self class]) encoding:NSASCIIStringEncoding];
	return [NSEntityDescription entityForName:className inManagedObjectContext:[self managedObjectContext]];
}

+ (NSFetchRequest*)fetchRequest {
	NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
	NSEntityDescription *entity = [self entity];
	[fetchRequest setEntity:entity];
	return fetchRequest;
}

+ (NSArray*)objectsWithFetchRequest:(NSFetchRequest*)fetchRequest {
	NSError* error = nil;
	NSArray* objects = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
	if (objects == nil) {
		RKLogError(@"Error: %@", [error localizedDescription]);
	}
	return objects;
}

+ (NSArray*)objectsWithFetchRequests:(NSArray*)fetchRequests {
	NSMutableArray* mutableObjectArray = [[NSMutableArray alloc] init];
	for (NSFetchRequest* fetchRequest in fetchRequests) {
		[mutableObjectArray addObjectsFromArray:[self objectsWithFetchRequest:fetchRequest]];
	}
	NSArray* objects = [NSArray arrayWithArray:mutableObjectArray];
	[mutableObjectArray release];
	return objects;
}

+ (id)objectWithFetchRequest:(NSFetchRequest*)fetchRequest {
	[fetchRequest setFetchLimit:1];
	NSArray* objects = [self objectsWithFetchRequest:fetchRequest];
	if ([objects count] == 0) {
		return nil;
	} else {
		return [objects objectAtIndex:0];
	}
}

+ (NSArray*)objectsWithPredicate:(NSPredicate*)predicate {
	NSFetchRequest* fetchRequest = [self fetchRequest];
	[fetchRequest setPredicate:predicate];
	return [self objectsWithFetchRequest:fetchRequest];
}

+ (id)objectWithPredicate:(NSPredicate*)predicate {
	NSFetchRequest* fetchRequest = [self fetchRequest];
	[fetchRequest setPredicate:predicate];
	return [self objectWithFetchRequest:fetchRequest];
}

+ (NSArray*)allObjects {
	return [self objectsWithPredicate:nil];
}

+ (NSUInteger)count:(NSError**)error {
	NSFetchRequest* fetchRequest = [self fetchRequest];
	return [[self managedObjectContext] countForFetchRequest:fetchRequest error:error];
}

+ (NSUInteger)count {
	NSError *error = nil;
	return [self count:&error];
}

+ (id)object {
	id object = [[self alloc] initWithEntity:[self entity] insertIntoManagedObjectContext:[self managedObjectContext]];
	return [object autorelease];
}

- (BOOL)isNew {
    NSDictionary *vals = [self committedValuesForKeys:nil];
    return [vals count] == 0;
}

#pragma mark - MagicalRecord Ported Methods

+ (NSManagedObjectContext*)currentContext; {
    return [self managedObjectContext];
}

+ (void)setDefaultBatchSize:(NSUInteger)newBatchSize
{
	@synchronized(defaultBatchSize)
	{
		defaultBatchSize = [NSNumber numberWithUnsignedInteger:newBatchSize];
	}
}

+ (NSInteger)defaultBatchSize
{
	if (defaultBatchSize == nil)
	{
		[self setDefaultBatchSize:kActiveRecordDefaultBatchSize];
	}
	return [defaultBatchSize integerValue];
}

+ (void)handleErrors:(NSError *)error
{
	if (error)
	{
		NSDictionary *userInfo = [error userInfo];
		for (NSArray *detailedError in [userInfo allValues])
		{
			if ([detailedError isKindOfClass:[NSArray class]])
			{
				for (NSError *e in detailedError)
				{
					if ([e respondsToSelector:@selector(userInfo)])
					{
						RKLogError(@"Error Details: %@", [e userInfo]);
					}
					else
					{
						RKLogError(@"Error Details: %@", e);
					}
				}
			}
			else
			{
				RKLogError(@"Error: %@", detailedError);
			}
		}
		RKLogError(@"Error Domain: %@", [error domain]);
		RKLogError(@"Recovery Suggestion: %@", [error localizedRecoverySuggestion]);	
	}
}

//- (void)handleErrors:(NSError *)error
//{
//	[[self class] handleErrors:error];
//}

+ (NSArray *)executeFetchRequest:(NSFetchRequest *)request inContext:(NSManagedObjectContext *)context
{
	NSError *error = nil;
	
	NSArray *results = [context executeFetchRequest:request error:&error];
	[self handleErrors:error];
	return results;	
}

+ (NSArray *)executeFetchRequest:(NSFetchRequest *)request 
{
	return [self executeFetchRequest:request inContext:[self currentContext]];
}

+ (id)executeFetchRequestAndReturnFirstObject:(NSFetchRequest *)request inContext:(NSManagedObjectContext *)context
{
	[request setFetchLimit:1];
	
	NSArray *results = [self executeFetchRequest:request inContext:context];
	if ([results count] == 0)
	{
		return nil;
	}
	return [results objectAtIndex:0];
}

+ (id)executeFetchRequestAndReturnFirstObject:(NSFetchRequest *)request
{
	return [self executeFetchRequestAndReturnFirstObject:request inContext:[self currentContext]];
}

#if TARGET_OS_IPHONE
+ (void)performFetch:(NSFetchedResultsController *)controller
{
	NSError *error = nil;
	if (![controller performFetch:&error])
	{
		[self handleErrors:error];
	}
}
#endif

+ (NSEntityDescription *)entityDescriptionInContext:(NSManagedObjectContext *)context
{
    NSString *entityName = NSStringFromClass([self class]);
    return [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
}

+ (NSEntityDescription *)entityDescription
{
	return [self entityDescriptionInContext:[self currentContext]];
}

+ (NSArray *)propertiesNamed:(NSArray *)properties
{
	NSEntityDescription *description = [self entityDescription];
	NSMutableArray *propertiesWanted = [NSMutableArray array];
	
	if (properties)
	{
		NSDictionary *propDict = [description propertiesByName];
		
		for (NSString *propertyName in properties)
		{
			NSPropertyDescription *property = [propDict objectForKey:propertyName];
			if (property)
			{
				[propertiesWanted addObject:property];
			}
			else
			{
				RKLogError(@"Property '%@' not found in %@ properties for %@", propertyName, [propDict count], NSStringFromClass(self));
			}
		}
	}
	return propertiesWanted;
}

+ (NSArray *)sortAscending:(BOOL)ascending attributes:(id)attributesToSortBy, ...
{
	NSMutableArray *attributes = [NSMutableArray array];
	
	if ([attributesToSortBy isKindOfClass:[NSArray class]])
	{
		id attributeName;
		va_list variadicArguments;
		va_start(variadicArguments, attributesToSortBy);
		while ((attributeName = va_arg(variadicArguments, id))!= nil)
		{
			NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:attributeName ascending:ascending];
			[attributes addObject:sortDescriptor];
			[sortDescriptor release];
		}
		va_end(variadicArguments);
        
	}
	else if ([attributesToSortBy isKindOfClass:[NSString class]])
	{
		va_list variadicArguments;
		va_start(variadicArguments, attributesToSortBy);
		[attributes addObject:[[[NSSortDescriptor alloc] initWithKey:attributesToSortBy ascending:ascending] autorelease] ];
		va_end(variadicArguments);
	}
	
	return attributes;
}

+ (NSArray *)ascendingSortDescriptors:(id)attributesToSortBy, ...
{
	return [self sortAscending:YES attributes:attributesToSortBy];
}

+ (NSArray *)descendingSortDescriptors:(id)attributesToSortyBy, ...
{
	return [self sortAscending:NO attributes:attributesToSortyBy];
}

+ (NSFetchRequest *)createFetchRequestInContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[self entityDescriptionInContext:context]];
	
	return request;	
}

+ (NSFetchRequest *)createFetchRequest
{
	return [self createFetchRequestInContext:[self currentContext]];
}

#pragma mark -
#pragma mark Number of Entities

+ (NSNumber *)numberOfEntitiesWithContext:(NSManagedObjectContext *)context
{
	NSError *error = nil;
	NSUInteger count = [context countForFetchRequest:[self createFetchRequestInContext:context] error:&error];
	[self handleErrors:error];
	
	return [NSNumber numberWithUnsignedInteger:count];	
}

+ (NSNumber *)numberOfEntities
{
	return [self numberOfEntitiesWithContext:[self currentContext]];
}

+ (NSNumber *)numberOfEntitiesWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context
{
	NSError *error = nil;
	NSFetchRequest *request = [self createFetchRequestInContext:context];
	[request setPredicate:searchTerm];
	
	NSUInteger count = [context countForFetchRequest:request error:&error];
	[self handleErrors:error];
	
	return [NSNumber numberWithUnsignedInteger:count];	
}

+ (NSNumber *)numberOfEntitiesWithPredicate:(NSPredicate *)searchTerm;
{
	return [self numberOfEntitiesWithPredicate:searchTerm 
									 inContext:[self currentContext]];
}

+ (BOOL)hasAtLeastOneEntityInContext:(NSManagedObjectContext *)context
{
    return [[self numberOfEntitiesWithContext:context] intValue] > 0;
}

+ (BOOL)hasAtLeastOneEntity
{
    return [self hasAtLeastOneEntityInContext:[self currentContext]];
}

#pragma mark -
#pragma mark Reqest Helpers
+ (NSFetchRequest *)requestAll
{
	return [self createFetchRequestInContext:[self currentContext]];
}

+ (NSFetchRequest *)requestAllInContext:(NSManagedObjectContext *)context
{
	return [self createFetchRequestInContext:context];
}

+ (NSFetchRequest *)requestAllWhere:(NSString *)property isEqualTo:(id)value inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [self createFetchRequestInContext:context];
    [request setPredicate:[NSPredicate predicateWithFormat:@"%K = %@", property, value]];
    
    return request;
}

+ (NSFetchRequest *)requestAllWhere:(NSString *)property isEqualTo:(id)value
{
    return [self requestAllWhere:property isEqualTo:value inContext:[self currentContext]];
}

+ (NSFetchRequest *)requestFirstWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [self createFetchRequestInContext:context];
    [request setPredicate:searchTerm];
    [request setFetchLimit:1];
    
    return request;
}

+ (NSFetchRequest *)requestFirstWithPredicate:(NSPredicate *)searchTerm
{
    return [self requestFirstWithPredicate:searchTerm inContext:[self currentContext]];
}

+ (NSFetchRequest *)requestFirstByAttribute:(NSString *)attribute withValue:(id)searchValue inContext:(NSManagedObjectContext *)context;
{
    NSFetchRequest *request = [self createFetchRequestInContext:context];
    [request setPropertiesToFetch:[self propertiesNamed:[NSArray arrayWithObject:attribute]]];
    [request setPredicate:[NSPredicate predicateWithFormat:@"%K = %@", attribute, searchValue]];
    
    return request;
}

+ (NSFetchRequest *)requestFirstByAttribute:(NSString *)attribute withValue:(id)searchValue;
{
    return [self requestFirstByAttribute:attribute withValue:searchValue inContext:[self currentContext]];
}

+ (NSFetchRequest *)requestAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [self requestAllInContext:context];
	
	NSSortDescriptor *sortBy = [[NSSortDescriptor alloc] initWithKey:sortTerm ascending:ascending];
	[request setSortDescriptors:[NSArray arrayWithObject:sortBy]];
	[sortBy release];
	
	return request;
}

+ (NSFetchRequest *)requestAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending
{
	return [self requestAllSortedBy:sortTerm 
						  ascending:ascending
						  inContext:[self currentContext]];
}

+ (NSFetchRequest *)requestAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [self requestAllInContext:context];
	[request setPredicate:searchTerm];
	[request setIncludesSubentities:NO];
	[request setFetchBatchSize:[self defaultBatchSize]];
	
	if (sortTerm != nil){
		NSSortDescriptor *sortBy = [[NSSortDescriptor alloc] initWithKey:sortTerm ascending:ascending];
		[request setSortDescriptors:[NSArray arrayWithObject:sortBy]];
		[sortBy release];
	}
	
	return request;
}

+ (NSFetchRequest *)requestAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm;
{
	NSFetchRequest *request = [self requestAllSortedBy:sortTerm 
											 ascending:ascending
										 withPredicate:searchTerm 
											 inContext:[self currentContext]];
	return request;
}


#pragma mark Finding Data
#pragma mark -

+ (NSArray *)findAllInContext:(NSManagedObjectContext *)context
{
	return [self executeFetchRequest:[self requestAllInContext:context] inContext:context];	
}

+ (NSArray *)findAll
{
	return [self findAllInContext:[self currentContext]];
}

+ (NSArray *)findAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [self requestAllSortedBy:sortTerm ascending:ascending inContext:context];
	
	return [self executeFetchRequest:request inContext:context];
}

+ (NSArray *)findAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending
{
	return [self findAllSortedBy:sortTerm 
					   ascending:ascending 
					   inContext:[self currentContext]];
}

+ (NSArray *)findAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [self requestAllSortedBy:sortTerm 
											 ascending:ascending
										 withPredicate:searchTerm
											 inContext:context];
	
	return [self executeFetchRequest:request inContext:context];
}

+ (NSArray *)findAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm
{
	return [self findAllSortedBy:sortTerm 
					   ascending:ascending
				   withPredicate:searchTerm 
					   inContext:[self currentContext]];
}

#pragma mark -
#pragma mark NSFetchedResultsController helpers

#if TARGET_OS_IPHONE

+ (NSFetchedResultsController *)fetchRequestAllGroupedBy:(NSString *)group withPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context
{
	NSString *cacheName = nil;
#ifdef STORE_USE_CACHE
	cacheName = [NSString stringWithFormat:@"ActiveRecord-Cache-%@", NSStringFromClass(self)];
#endif
	
	NSFetchRequest *request = [self requestAllSortedBy:sortTerm 
											 ascending:ascending 
										 withPredicate:searchTerm
											 inContext:context];
	
	NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest:request 
																				 managedObjectContext:context
																				   sectionNameKeyPath:group
																							cacheName:cacheName];
	return [controller autorelease];
}

+ (NSFetchedResultsController *)fetchRequestAllGroupedBy:(NSString *)group withPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending 
{
	return [self fetchRequestAllGroupedBy:group
							withPredicate:searchTerm
								 sortedBy:sortTerm
								ascending:ascending
								inContext:[self currentContext]];
}

+ (NSFetchedResultsController *)fetchAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm groupBy:(NSString *)groupingKeyPath inContext:(NSManagedObjectContext *)context
{
	NSFetchedResultsController *controller = [self fetchRequestAllGroupedBy:groupingKeyPath 
															  withPredicate:searchTerm
																   sortedBy:sortTerm 
																  ascending:ascending
																  inContext:context];
	
	[self performFetch:controller];
	return controller;
}

+ (NSFetchedResultsController *)fetchAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm groupBy:(NSString *)groupingKeyPath
{
	return [self fetchAllSortedBy:sortTerm 
						ascending:ascending
					withPredicate:searchTerm 
						  groupBy:groupingKeyPath 
						inContext:[self currentContext]];
}

+ (NSFetchedResultsController *)fetchRequest:(NSFetchRequest *)request groupedBy:(NSString *)group inContext:(NSManagedObjectContext *)context
{
	NSString *cacheName = nil;
#ifdef STORE_USE_CACHE
	cacheName = [NSString stringWithFormat:@"ActiveRecord-Cache-%@", NSStringFromClass([self class])];
#endif
	NSFetchedResultsController *controller =
    [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                        managedObjectContext:context
                                          sectionNameKeyPath:group
                                                   cacheName:cacheName];
    [self performFetch:controller];
	return [controller autorelease];
}

+ (NSFetchedResultsController *)fetchRequest:(NSFetchRequest *)request groupedBy:(NSString *)group
{
	return [self fetchRequest:request 
					groupedBy:group
					inContext:[self currentContext]];
}
#endif

#pragma mark -

+ (NSArray *)findAllWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [self createFetchRequestInContext:context];
	[request setPredicate:searchTerm];
	
	return [self executeFetchRequest:request 
						   inContext:context];
}

+ (NSArray *)findAllWithPredicate:(NSPredicate *)searchTerm
{
	return [self findAllWithPredicate:searchTerm 
							inContext:[self currentContext]];
}

+ (id)findFirstInContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [self createFetchRequestInContext:context];
	
	return [self executeFetchRequestAndReturnFirstObject:request inContext:context];
}

+ (id)findFirst
{
	return [self findFirstInContext:[self currentContext]];
}

+ (id)findFirstByAttribute:(NSString *)attribute withValue:(id)searchValue inContext:(NSManagedObjectContext *)context
{	
	NSFetchRequest *request = [self requestFirstByAttribute:attribute withValue:searchValue inContext:context];
    [request setPropertiesToFetch:[self propertiesNamed:[NSArray arrayWithObject:attribute]]];
    
	return [self executeFetchRequestAndReturnFirstObject:request inContext:context];
}

+ (id)findFirstByAttribute:(NSString *)attribute withValue:(id)searchValue
{
	return [self findFirstByAttribute:attribute 
							withValue:searchValue 
							inContext:[self currentContext]];
}

+ (id)findFirstWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [self requestFirstWithPredicate:searchTerm];
    
    return [self executeFetchRequestAndReturnFirstObject:request inContext:context];
}

+ (id)findFirstWithPredicate:(NSPredicate *)searchTerm
{
    return [self findFirstWithPredicate:searchTerm inContext:[self currentContext]];
}

+ (id)findFirstWithPredicate:(NSPredicate *)searchterm sortedBy:(NSString *)property ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [self requestAllSortedBy:property ascending:ascending withPredicate:searchterm inContext:context];
    
	return [self executeFetchRequestAndReturnFirstObject:request inContext:context];
}

+ (id)findFirstWithPredicate:(NSPredicate *)searchterm sortedBy:(NSString *)property ascending:(BOOL)ascending
{
	return [self findFirstWithPredicate:searchterm 
							   sortedBy:property 
							  ascending:ascending 
							  inContext:[self currentContext]];
}

+ (id)findFirstWithPredicate:(NSPredicate *)searchTerm andRetrieveAttributes:(NSArray *)attributes inContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [self createFetchRequestInContext:context];
	[request setPredicate:searchTerm];
	[request setPropertiesToFetch:[self propertiesNamed:attributes]];
	
	return [self executeFetchRequestAndReturnFirstObject:request inContext:context];
}

+ (id)findFirstWithPredicate:(NSPredicate *)searchTerm andRetrieveAttributes:(NSArray *)attributes
{
	return [self findFirstWithPredicate:searchTerm 
				  andRetrieveAttributes:attributes 
							  inContext:[self currentContext]];
}


+ (id)findFirstWithPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortBy ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context andRetrieveAttributes:(id)attributes, ...
{
	NSFetchRequest *request = [self requestAllSortedBy:sortBy 
											 ascending:ascending
										 withPredicate:searchTerm
											 inContext:context];
	[request setPropertiesToFetch:[self propertiesNamed:attributes]];
	
	return [self executeFetchRequestAndReturnFirstObject:request inContext:context];
}

+ (id)findFirstWithPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortBy ascending:(BOOL)ascending andRetrieveAttributes:(id)attributes, ...
{
	return [self findFirstWithPredicate:searchTerm
							   sortedBy:sortBy 
							  ascending:ascending 
                              inContext:[self currentContext]
				  andRetrieveAttributes:attributes];
}

+ (NSArray *)findByAttribute:(NSString *)attribute withValue:(id)searchValue inContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [self createFetchRequestInContext:context];
	
	[request setPredicate:[NSPredicate predicateWithFormat:@"%K = %@", attribute, searchValue]];
	
	return [self executeFetchRequest:request inContext:context];
}

+ (NSArray *)findByAttribute:(NSString *)attribute withValue:(id)searchValue
{
	return [self findByAttribute:attribute 
					   withValue:searchValue 
					   inContext:[self currentContext]];
}

+ (NSArray *)findByAttribute:(NSString *)attribute withValue:(id)searchValue andOrderBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context
{
	NSPredicate *searchTerm = [NSPredicate predicateWithFormat:@"%K = %@", attribute, searchValue];
	NSFetchRequest *request = [self requestAllSortedBy:sortTerm ascending:ascending withPredicate:searchTerm inContext:context];
	
	return [self executeFetchRequest:request];
}

+ (NSArray *)findByAttribute:(NSString *)attribute withValue:(id)searchValue andOrderBy:(NSString *)sortTerm ascending:(BOOL)ascending
{
	return [self findByAttribute:attribute 
					   withValue:searchValue
					  andOrderBy:sortTerm 
					   ascending:ascending 
					   inContext:[self currentContext]];
}

+ (id)createInContext:(NSManagedObjectContext *)context
{
    NSString *entityName = NSStringFromClass([self class]);
    return [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:context];
}

+ (id)createEntity
{	
	NSManagedObject *newEntity = [self createInContext:[self currentContext]];
    
	return newEntity;
}

- (BOOL)deleteInContext:(NSManagedObjectContext *)context
{
	[context deleteObject:self];
	return YES;
}

- (BOOL)deleteEntity
{
	[self deleteInContext:[[self class] currentContext]];
	return YES;
}

+ (BOOL)truncateAllInContext:(NSManagedObjectContext *)context
{
    NSArray *allEntities = [self findAllInContext:context];
    for (NSManagedObject *obj in allEntities)
    {
        [obj deleteInContext:context];
    }
    return YES;
}

+ (BOOL)truncateAll
{
    [self truncateAllInContext:[self currentContext]];
    return YES;
}

+ (NSNumber *)maxValueFor:(NSString *)property
{
	NSManagedObject *obj = [[self class] findFirstByAttribute:property
													withValue:[NSString stringWithFormat:@"max(%@)", property]];
	
	return [obj valueForKey:property];
}

+ (id)objectWithMinValueFor:(NSString *)property inContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [[self class] createFetchRequestInContext:context];
    
	NSPredicate *searchFor = [NSPredicate predicateWithFormat:@"SELF = %@ AND %K = min(%@)", self, property, property];
	[request setPredicate:searchFor];
	
	return [[self class] executeFetchRequestAndReturnFirstObject:request inContext:context];
}

+ (id)objectWithMinValueFor:(NSString *)property 
{
	return [[self class] objectWithMinValueFor:property inContext:[self currentContext]];
}

@end
