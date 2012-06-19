//
//  RKObjectMappingProvider+CoreData.h
//  RestKit
//
//  Created by Jeff Arena on 1/26/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKObjectMappingProvider.h"
#import <CoreData/CoreData.h>

typedef NSFetchRequest *(^RKObjectMappingProviderFetchRequestBlock)(NSString *resourcePath);

/**
 Provides extensions to RKObjectMappingProvider to support Core Data specific
 functionality.
 */
@interface RKObjectMappingProvider (CoreData)

/**
 Configures an object mapping to be used when during a load event where the resourcePath of
 the RKObjectLoader instance matches resourcePathPattern.

 The resourcePathPattern is a SOCKit pattern matching property names preceded by colons within
 a path. For example, if a collection of reviews for a product were loaded from a remote system
 at the resourcePath @"/products/1234/reviews", object mapping could be configured to handle
 this request with a resourcePathPattern of @"/products/:productID/reviews".

 **NOTE** that care must be taken when configuring patterns within the provider. The patterns
 will be evaluated in the order they are added to the provider, so more specific patterns must
 precede more general patterns where either would generate a match.

 @param objectMapping The object mapping to use when the resourcePath matches the specified
 resourcePathPattern.
 @param resourcePathPattern A pattern to be evaluated using an RKPathMatcher against a resourcePath
 to determine if objectMapping is the appropriate mapping.
 @param fetchRequestBlock A block that accepts an individual resourcePath and returns an NSFetchRequest
 that should be used to fetch the local objects associated with resourcePath from CoreData, for use in
 properly processing local deletes
 @see RKPathMatcher
 @see RKURL
 @see RKObjectLoader
 */
- (void)setObjectMapping:(RKObjectMappingDefinition *)objectMapping forResourcePathPattern:(NSString *)resourcePathPattern withFetchRequestBlock:(RKObjectMappingProviderFetchRequestBlock)fetchRequestBlock;

/**
 Retrieves the NSFetchRequest object that will retrieve cached objects for a given resourcePath.

 @param resourcePath A resourcePath to retrieve the fetch request for.
 @return An NSFetchRequest object for fetching objects for the given resource path or nil.
 */
- (NSFetchRequest *)fetchRequestForResourcePath:(NSString *)resourcePath;

@end
