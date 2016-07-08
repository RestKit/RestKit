# RestKit

[![Build Status](http://img.shields.io/travis/RestKit/RestKit/development.svg?style=flat)](https://travis-ci.org/RestKit/RestKit)
[![Pod Version](http://img.shields.io/cocoapods/v/RestKit.svg?style=flat)](http://cocoadocs.org/docsets/RestKit/)
[![Pod Platform](http://img.shields.io/cocoapods/p/RestKit.svg?style=flat)](http://cocoadocs.org/docsets/RestKit/)
[![Pod License](http://img.shields.io/cocoapods/l/RestKit.svg?style=flat)](https://www.apache.org/licenses/LICENSE-2.0.html)
[![Visit our IRC channel](http://img.shields.io/badge/IRC-%23RestKit-green.svg?style=flat)](https://kiwiirc.com/client/irc.freenode.net/?nick=rkuser|?&theme=basic#RestKit)

RestKit is a modern Objective-C framework for implementing RESTful web services clients on iOS and Mac OS X. It provides a powerful [object mapping](https://github.com/RestKit/RestKit/wiki/Object-mapping) engine that seamlessly integrates with [Core Data](http://developer.apple.com/library/mac/#documentation/cocoa/Conceptual/CoreData/cdProgrammingGuide.html) and a simple set of networking primitives for mapping HTTP requests and responses built on top of [AFNetworking](https://github.com/AFNetworking/AFNetworking). It has an elegant, carefully designed set of APIs that make accessing and modeling RESTful resources feel almost magical. For example, here's how to access the Twitter public timeline and turn the JSON contents into an array of Tweet objects:

```  objective-c
@interface RKTweet : NSObject
@property (nonatomic, copy) NSNumber *userID;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *text;
@end

RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTweet class]];
[mapping addAttributeMappingsFromDictionary:@{
    @"user.name":   @"username",
    @"user.id":     @"userID",
    @"text":        @"text"
}];

RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:nil];
NSURL *url = [NSURL URLWithString:@"http://api.twitter.com/1/statuses/public_timeline.json"];
NSURLRequest *request = [NSURLRequest requestWithURL:url];
RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
[operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result) {
    NSLog(@"The public timeline Tweets: %@", [result array]);
} failure:nil];
[operation start];
```

## Getting Started

- [Download RestKit](https://github.com/RestKit/RestKit/releases) and play with the [examples](https://github.com/RestKit/RestKit/tree/development/Examples) for iPhone and Mac OS X
- First time with RestKit? Read the ["Overview"](#overview) section below and then check out the ["Getting Acquainted with RestKit"](https://github.com/RestKit/RKGist/blob/master/TUTORIAL.md) tutorial and [Object Mapping Reference](https://github.com/RestKit/RestKit/wiki/Object-mapping) documents in the wiki to jump right in.
- Upgrading from RestKit 0.9.x or 0.10.x? Read the ["Upgrading to RestKit 0.20.x"](https://github.com/RestKit/RestKit/wiki/Upgrading-from-v0.10.x-to-v0.20.0) guide in the wiki
- Adding RestKit to an existing [AFNetworking](https://github.com/AFNetworking/AFNetworking) application? Read the [AFNetworking Integration](https://github.com/RestKit/RestKit/wiki/AFNetworking-Integration) document to learn details about how the frameworks fit together.
- Review the [source code API documentation](http://cocoadocs.org/docsets/RestKit/) for a detailed look at the classes and API's in RestKit. A great place to start is [RKObjectManager](http://restkit.org/api/latest/Classes/RKObjectManager.html).
- Still need some help? Ask questions on [Stack Overflow](http://stackoverflow.com/questions/tagged/restkit) or the [mailing list](http://groups.google.com/group/restkit), ping us on [Twitter](http://twitter.com/RestKit) or chat with us on [IRC](https://kiwiirc.com/client/irc.freenode.net/?nick=rkuser|?&theme=basic#RestKit).

## Overview

RestKit is designed to be modular and each module strives to maintain a minimal set of dependencies across the framework and with the host platform. At the core of library sits the object mapping engine, which is responsible for transforming objects between representations (such as JSON/XML <-> local domain objects).

### Object Mapping Fundamentals

The object mapping engine is built on top of the [Key-Value Coding](https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/KeyValueCoding/Articles/KeyValueCoding.html) (KVC) informal protocol that is foundational to numerous Cocoa technologies such as key-value observing, bindings, and Core Data. Object mappings are expressed as pairs of KVC key paths that specify the source and destination attributes or relationships that are to be transformed.

RestKit leverages the highly dynamic Objective-C runtime to infer the developers desired intent by examining the type of the source and destination properties and performing appropriate type transformations. For example, given a source key path of `created_at` that identifies a string within a parsed JSON document and a destination key path of `creationDate` that identifies an `NSDate` property on a target object, RestKit will transform the date from a string into an `NSDate` using an `NSDateFormatter`. Numerous other transformations are provided out of the box and the engine is pluggable to allow the developer to define new transformations or replace an existing transformation with a new implementation.

The mapper fully supports both simple attribute as well as relationship mappings in which nested to-one or to-many child objects are mapped recursively. Through relationship mappings, one object mapping can be added to another to compose aggregate mappings that are capable of processing arbitrarily complex source documents.

Object mapping is a deep topic and is explored in exhaustive detail in the [Object Mapping Guide](https://github.com/RestKit/RestKit/wiki/Object-mapping) on the wiki.

### API Quickstart

RestKit is broken into several modules that cleanly separate the mapping engine from the HTTP and Core Data integrations to provide maximum flexibility. Key classes in each module are highlighted below and each module is hyperlinked to the README.md contained within the source code.

<table>
  <tr><th colspan="2" style="text-align:center;"><a href="https://github.com/RestKit/RestKit/wiki/Object-mapping">Object Mapping</a></th></tr>
  <tr>
    <td><a href="http://restkit.org/api/latest/Classes/RKObjectMapping.html">RKObjectMapping</a></td>
    <td>Encapsulates configuration for transforming object representations as expressed by key-value coding keypaths.</td>
  </tr>
  <tr>
    <td><a href="http://restkit.org/api/latest/Classes/RKAttributeMapping.html">RKAttributeMapping</a></td>
    <td>Specifies a desired transformation between attributes within an object or entity mapping in terms of a source and destination key path.</td>
  </tr>
  <tr>
    <td><a href="http://restkit.org/api/latest/Classes/RKRelationshipMapping.html">RKRelationshipMapping</a></td>
    <td>Specifies a desired mapping of a nested to-one or to-many child objects in in terms of a source and destination key path and an <tt>RKObjectMapping</tt> with which to map the attributes of the child object.</td>
  </tr>  
  <tr>
    <td><a href="http://restkit.org/api/latest/Classes/RKDynamicMapping.html">RKDynamicMapping</a></td>
    <td>Specifies a flexible mapping in which the decision about which <tt>RKObjectMapping</tt> is to be used to process a given document is deferred to run time.</td>
  </tr>
  <tr>
    <td><a href="http://restkit.org/api/latest/Classes/RKMapperOperation.html">RKMapperOperation</a></td>
    <td>Provides an interface for mapping a deserialized document into a set of local domain objects.</td>
  </tr>
  <tr>
    <td><a href="http://restkit.org/api/latest/Classes/RKMappingOperation.html">RKMappingOperation</a></td>
    <td>An <tt>NSOperation</tt> that performs a mapping between object representations using an <tt>RKObjectMapping</tt>.</td>
  </tr>  
  <tr><th colspan="2" style="text-align:center;"><a href="Code/Network/README.md">Networking</a></th></tr>
  <tr>
    <td><a href="http://restkit.org/api/latest/Classes/RKRequestDescriptor.html">RKRequestDescriptor</a></td>
    <td>Describes a request that can be sent from the application to a remote web application for a given object type.</td>
  </tr>
  <tr>
    <td><a href="http://restkit.org/api/latest/Classes/RKResponseDescriptor.html">RKResponseDescriptor</a></td>
    <td>Describes an object mappable response that may be returned from a remote web application in terms of an object mapping, a key path, a <a href="http://cocoadocs.org/docsets/SOCKit/">SOCKit pattern</a> for matching the URL, and a set of status codes that define the circumstances in which the mapping is appropriate for a given response.</td>
  </tr>
  <tr>
    <td><a href="http://restkit.org/api/latest/Classes/RKObjectParameterization.html">RKObjectParameterization</a></td>
    <td>Performs mapping of a given object into an <tt>NSDictionary</tt> representation suitable for use as the parameters of an HTTP request.</td>
  </tr>
  <tr>
    <td><a href="http://restkit.org/api/latest/Classes/RKObjectRequestOperation.html">RKObjectRequestOperation</a></td>
    <td>An <tt>NSOperation</tt> that sends an HTTP request and performs object mapping on the parsed response body using the configurations expressed in a set of <tt>RKResponseDescriptor</tt> objects.</td>
  </tr>
  <tr>
    <td><a href="http://restkit.org/api/latest/Classes/RKResponseMapper.html">RKResponseMapperOperation</a></td>
    <td>An <tt>NSOperation</tt> that provides support for object mapping an <tt>NSHTTPURLResponse</tt> using a set of <tt>RKResponseDescriptor</tt> objects.</td>
  </tr>  
  <tr>
    <td><a href="http://restkit.org/api/latest/Classes/RKObjectManager.html">RKObjectManager</a></td>
    <td>Captures the common patterns for communicating with a RESTful web application over HTTP using object mapping including:
    	<ul>
    		<li>Centralizing <tt>RKRequestDescriptor</tt> and <tt>RKResponseDescriptor</tt> configurations</li>
    		<li>Describing URL configuration with an <tt>RKRouter</tt></li>
    		<li>Serializing objects and sending requests with the serialized representations</li>
    		<li>Sending requests to load remote resources and object mapping the response bodies</li>
    		<li>Building multi-part form requests for objects</li>
    	</ul>
    </td>
  </tr>
  <tr>
    <td><a href="http://restkit.org/api/latest/Classes/RKRouter.html">RKRouter</a></td>
    <td>Generates <tt>NSURL</tt> objects from a base URL and a set of <tt>RKRoute</tt> objects describing relative paths used by the application.</td>
  </tr>
  <tr>
    <td><a href="http://restkit.org/api/latest/Classes/RKRoute.html">RKRoute</a></td>
    <td>Describes a single relative path for a given object type and HTTP method, the relationship of an object, or a symbolic name.</td>
  </tr>
  <tr><th colspan="2" style="text-align:center;"><a href="Code/CoreData/README.md">Core Data</a></th></tr>
  <tr>
    <td><a href="http://restkit.org/api/latest/Classes/RKManagedObjectStore.html">RKManagedObjectStore</a></td>
    <td>Encapsulates Core Data configuration including an <tt>NSManagedObjectModel</tt>, a <tt>NSPersistentStoreCoordinator</tt>, and a pair of <tt>NSManagedObjectContext</tt> objects.</td>
  </tr>
  <tr>
    <td><a href="http://restkit.org/api/latest/Classes/RKEntityMapping.html">RKEntityMapping</a></td>
    <td>Models a mapping for transforming an object representation into a <tt>NSManagedObject</tt> instance for a given <tt>NSEntityDescription</tt>.</td>
  </tr>
  <tr>
    <td><a href="http://restkit.org/api/latest/Classes/RKConnectionDescription.html">RKConnectionDescription</a></td>
    <td>Describes a mapping for establishing a relationship between Core Data entities using foreign key attributes.</td>
  </tr>  
  <tr>
    <td><a href="http://restkit.org/api/latest/Classes/RKManagedObjectRequestOperation.html">RKManagedObjectRequestOperation</a></td>
    <td>An <tt>NSOperation</tt> subclass that sends an HTTP request and performs object mapping on the parsed response body to create <tt>NSManagedObject</tt> instances, establishes relationships between objects using <tt>RKConnectionDescription</tt> objects, and cleans up orphaned objects that no longer exist in the remote backend system.</td>
  </tr>
  <tr>
    <td><a href="http://restkit.org/api/latest/Classes/RKManagedObjectImporter.html">RKManagedObjectImporter</a></td>
    <td>Provides support for bulk mapping of managed objects using <tt>RKEntityMapping</tt> objects for two use cases:
    	<ol>
    		<li>Bulk importing of parsed documents into an <tt>NSPersistentStore.</tt></li>
    		<li>Generating a <a href="Docs for database seeding">seed database</a> for initializing an application's Core Data store with an initial data set upon installation.</li>
    	</ol>
    </td>
  </tr>
  <tr><th colspan="2" style="text-align:center;"><a href="Code/Search/README.md">Search</a></th></tr>
  <tr>
    <td><a href="http://restkit.org/api/latest/Classes/RKSearchIndexer.html">RKSearchIndexer</a></td>
    <td>Provides support for generating a full-text searchable index within Core Data for string attributes of entities within an application.</td>
  </tr>
  <tr>
    <td><a href="http://restkit.org/api/latest/Classes/RKSearchPredicate.html">RKSearchPredicate</a></td>
    <td>Generates an <tt>NSCompoundPredicate</tt> given a string of text that will search an index built with an <tt>RKSearchIndexer</tt> across any indexed entity.</td>
  </tr>
  <tr><th colspan="2" style="text-align:center;"><a href="Code/Testing/README.md">Testing</a></th></tr>
  <tr>
    <td><a href="http://restkit.org/api/latest/Classes/RKMappingTest.html">RKMappingTest</a></td>
    <td>Provides support for unit testing object mapping configurations given a parsed document and an object or entity mapping. Expectations are configured in terms of expected key path mappings and/or expected transformation results.</td>
  </tr>
  <tr>
    <td><a href="http://restkit.org/api/latest/Classes/RKTestFixture.html">RKTestFixture</a></td>
    <td>Provides an interface for easily generating test fixture data for unit testing.</td>
  </tr>
  <tr>
    <td><a href="http://restkit.org/api/latest/Classes/RKTestFactory.html">RKTestFactory</a></td>
    <td>Provides support for creating objects for use in testing.</td>
  </tr>
</table>

###

## Examples

### Object Request
``` objective-c
// GET a single Article from /articles/1234.json and map it into an object
// JSON looks like {"article": {"title": "My Article", "author": "Blake", "body": "Very cool!!"}}
RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[Article class]];
[mapping addAttributeMappingsFromArray:@[@"title", @"author", @"body"]];
NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:@"/articles/:articleID" keyPath:@"article" statusCodes:statusCodes];

NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://restkit.org/articles/1234.json"]];
RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
[operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result) {
    Article *article = [result firstObject];
	NSLog(@"Mapped the article: %@", article);
} failure:^(RKObjectRequestOperation *operation, NSError *error) {
	NSLog(@"Failed with error: %@", [error localizedDescription]);
}];
[operation start];
```

### Managed Object Request
``` objective-c
// GET an Article and its Categories from /articles/888.json and map into Core Data entities
// JSON looks like {"article": {"title": "My Article", "author": "Blake", "body": "Very cool!!", "categories": [{"id": 1, "name": "Core Data"]}
NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:managedObjectModel];
NSError *error = nil;
BOOL success = RKEnsureDirectoryExistsAtPath(RKApplicationDataDirectory(), &error);
if (! success) {
    RKLogError(@"Failed to create Application Data Directory at path '%@': %@", RKApplicationDataDirectory(), error);
}
NSString *path = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"Store.sqlite"];
NSPersistentStore *persistentStore = [managedObjectStore addSQLitePersistentStoreAtPath:path fromSeedDatabaseAtPath:nil withConfiguration:nil options:nil error:&error];
if (! persistentStore) {
    RKLogError(@"Failed adding persistent store at path '%@': %@", path, error);
}
[managedObjectStore createManagedObjectContexts];

RKEntityMapping *categoryMapping = [RKEntityMapping mappingForEntityForName:@"Category" inManagedObjectStore:managedObjectStore];
[categoryMapping addAttributeMappingsFromDictionary:@{ "id": "categoryID", @"name": "name" }];
RKEntityMapping *articleMapping = [RKEntityMapping mappingForEntityForName:@"Article" inManagedObjectStore:managedObjectStore];
[articleMapping addAttributeMappingsFromArray:@[@"title", @"author", @"body"]];
[articleMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"categories" toKeyPath:@"categories" withMapping:categoryMapping]];

NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:articleMapping method:RKRequestMethodAny pathPattern:@"/articles/:articleID" keyPath:@"article" statusCodes:statusCodes];

NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://restkit.org/articles/888.json"]];
RKManagedObjectRequestOperation *operation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
operation.managedObjectContext = managedObjectStore.mainQueueManagedObjectContext;
operation.managedObjectCache = managedObjectStore.managedObjectCache;
[operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result) {
  Article *article = [result firstObject];
	NSLog(@"Mapped the article: %@", article);
	NSLog(@"Mapped the category: %@", [article.categories anyObject]);
} failure:^(RKObjectRequestOperation *operation, NSError *error) {
	NSLog(@"Failed with error: %@", [error localizedDescription]);
}];
NSOperationQueue *operationQueue = [NSOperationQueue new];
[operationQueue addOperation:operation];
```

### Map a Client Error Response to an NSError
``` objective-c
// GET /articles/error.json returns a 422 (Unprocessable Entity)
// JSON looks like {"errors": "Some Error Has Occurred"}

// You can map errors to any class, but `RKErrorMessage` is included for free
RKObjectMapping *errorMapping = [RKObjectMapping mappingForClass:[RKErrorMessage class]];
// The entire value at the source key path containing the errors maps to the message
[errorMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:nil toKeyPath:@"errorMessage"]];

NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassClientError);
// Any response in the 4xx status code range with an "errors" key path uses this mapping
RKResponseDescriptor *errorDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:errorMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"errors" statusCodes:statusCodes];

NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://restkit.org/articles/error.json"]];
RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[errorDescriptor]];
[operation setCompletionBlockWithSuccess:nil failure:^(RKObjectRequestOperation *operation, NSError *error) {
    // The `description` method of the class the error is mapped to is used to construct the value of the localizedDescription
	NSLog(@"Loaded this error: %@", [error localizedDescription]);

    // You can access the model object used to construct the `NSError` via the `userInfo`
    RKErrorMessage *errorMessage =  [[error.userInfo objectForKey:RKObjectMapperErrorObjectsKey] firstObject];
}];
```

### Centralize Configuration in an Object Manager
``` objective-c
// Set up Article and Error Response Descriptors
// Successful JSON looks like {"article": {"title": "My Article", "author": "Blake", "body": "Very cool!!"}}
RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[Article class]];
[mapping addAttributeMappingsFromArray:@[@"title", @"author", @"body"]];
NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
RKResponseDescriptor *articleDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:@"/articles" keyPath:@"article" statusCodes:statusCodes];

// Error JSON looks like {"errors": "Some Error Has Occurred"}
RKObjectMapping *errorMapping = [RKObjectMapping mappingForClass:[RKErrorMessage class]];
// The entire value at the source key path containing the errors maps to the message
[errorMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:nil toKeyPath:@"errorMessage"]];
NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassClientError);
// Any response in the 4xx status code range with an "errors" key path uses this mapping
RKResponseDescriptor *errorDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:errorMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"errors" statusCodes:statusCodes];

// Add our descriptors to the manager
RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
[manager addResponseDescriptorsFromArray:@[ articleDescriptor, errorDescriptor ]];

[manager getObjectsAtPath:@"/articles/555.json" parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
	// Handled with articleDescriptor
} failure:^(RKObjectRequestOperation *operation, NSError *error) {
	// Transport error or server error handled by errorDescriptor
}];
```

### Configure Core Data Integration with the Object Manager
``` objective-c
NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:managedObjectModel];
BOOL success = RKEnsureDirectoryExistsAtPath(RKApplicationDataDirectory(), &error);
if (! success) {
    RKLogError(@"Failed to create Application Data Directory at path '%@': %@", RKApplicationDataDirectory(), error);
}
NSString *path = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"Store.sqlite"];
NSPersistentStore *persistentStore = [managedObjectStore addSQLitePersistentStoreAtPath:path fromSeedDatabaseAtPath:nil withConfiguration:nil options:nil error:&error];
if (! persistentStore) {
    RKLogError(@"Failed adding persistent store at path '%@': %@", path, error);
}
[managedObjectStore createManagedObjectContexts];

RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
manager.managedObjectStore = managedObjectStore;
```

### Load a Collection of Objects at a Path
``` objective-c
RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
[manager getObjectsAtPath:@"/articles" parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
} failure:^(RKObjectRequestOperation *operation, NSError *error) {
}];
```

### Manage a Queue of Object Request Operations
``` objective-c
RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];

NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://restkit.org/articles/1234.json"]];
RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];

[manager enqueueObjectRequestOperation:operation];
[manager cancelAllObjectRequestOperationsWithMethod:RKRequestMethodANY matchingPathPattern:@"/articles/:articleID\\.json"];
```

### POST, PATCH, and DELETE an Object
``` objective-c
RKObjectMapping *responseMapping = [RKObjectMapping mappingForClass:[Article class]];
[responseMapping addAttributeMappingsFromArray:@[@"title", @"author", @"body"]];
NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
RKResponseDescriptor *articleDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:responseMapping method:RKRequestMethodAny pathPattern:@"/articles" keyPath:@"article" statusCodes:statusCodes];

RKObjectMapping *requestMapping = [RKObjectMapping requestMapping]; // objectClass == NSMutableDictionary
[requestMapping addAttributeMappingsFromArray:@[@"title", @"author", @"body"]];

// For any object of class Article, serialize into an NSMutableDictionary using the given mapping and nest
// under the 'article' key path
RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:requestMapping objectClass:[Article class] rootKeyPath:@"article" method:RKRequestMethodAny];

RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
[manager addRequestDescriptor:requestDescriptor];
[manager addResponseDescriptor:articleDescriptor];

Article *article = [Article new];
article.title = @"Introduction to RestKit";
article.body = @"This is some text.";
article.author = @"Blake";

// POST to create
[manager postObject:article path:@"/articles" parameters:nil success:nil failure:nil];

// PATCH to update
article.body = @"New Body";
[manager patchObject:article path:@"/articles/1234" parameters:nil success:nil failure:nil];

// DELETE to destroy
[manager deleteObject:article path:@"/articles/1234" parameters:nil success:nil failure:nil];
```

### Configure Logging
``` objective-c
// Log all HTTP traffic with request and response bodies
RKLogConfigureByName("RestKit/Network", RKLogLevelTrace);

// Log debugging info about Core Data
RKLogConfigureByName("RestKit/CoreData", RKLogLevelDebug);

// Raise logging for a block
RKLogWithLevelWhileExecutingBlock(RKLogLevelTrace, ^{
    // Do something that generates logs
});
```

### Configure Routing
``` objective-c
RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];

// Class Routing
[manager.router.routeSet addRoute:[RKRoute routeWithClass:[GGSegment class] pathPattern:@"/segments/:segmentID\\.json" method:RKRequestMethodGET]];

// Relationship Routing
[manager.router.routeSet addRoute:[RKRoute routeWithRelationshipName:@"amenities" objectClass:[GGAirport class] pathPattern:@"/airports/:airportID/amenities.json" method:RKRequestMethodGET]];

// Named Routes
[manager.router.routeSet addRoute:[RKRoute routeWithName:@"thumbs_down_review" resourcePathPattern:@"/reviews/:reviewID/thumbs_down" method:RKRequestMethodPOST]];
```

### POST an Object with a File Attachment
``` objective-c
Article *article = [Article new];
UIImage *image = [UIImage imageNamed:@"some_image.png"];

// Serialize the Article attributes then attach a file
NSMutableURLRequest *request = [[RKObjectManager sharedManager] multipartFormRequestWithObject:article method:RKRequestMethodPOST path:nil parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
    [formData appendPartWithFileData:UIImagePNGRepresentation(image)
                                name:@"article[image]"
                            fileName:@"photo.png"
                            mimeType:@"image/png"];
}];

RKObjectRequestOperation *operation = [[RKObjectManager sharedManager] objectRequestOperationWithRequest:request success:nil failure:nil];
[[RKObjectManager sharedManager] enqueueObjectRequestOperation:operation]; // NOTE: Must be enqueued rather than started
```

### Enqueue a Batch of Object Request Operations
``` objective-c

RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];

Airport *jfk = [Airport new];
jfk.code = @"jfk";
Airport *lga = [Airport new];
lga.code = @"lga";
Airport *rdu = [Airport new];
rdu.code = @"rdu";

// Enqueue a GET for '/airports/jfk/weather', '/airports/lga/weather', '/airports/rdu/weather'
RKRoute *route = [RKRoute routeWithName:@"airport_weather" resourcePathPattern:@"/airports/:code/weather" method:RKRequestMethodGET];

[manager enqueueBatchOfObjectRequestOperationsWithRoute:route
                                                objects:@[ jfk, lga, rdu]
                                               progress:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations) {
                                                   NSLog(@"Finished %d operations", numberOfFinishedOperations);
                                               } completion:^ (NSArray *operations) {
                                                   NSLog(@"All Weather Reports Loaded!");
                                               }];
```

### Generate a Seed Database
``` objective-c
NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:managedObjectModel];
NSError *error = nil;
BOOL success = RKEnsureDirectoryExistsAtPath(RKApplicationDataDirectory(), &error);
if (! success) {
    RKLogError(@"Failed to create Application Data Directory at path '%@': %@", RKApplicationDataDirectory(), error);
}
NSString *path = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"Store.sqlite"];
NSPersistentStore *persistentStore = [managedObjectStore addSQLitePersistentStoreAtPath:path fromSeedDatabaseAtPath:nil withConfiguration:nil options:nil error:&error];
if (! persistentStore) {
    RKLogError(@"Failed adding persistent store at path '%@': %@", path, error);
}
[managedObjectStore createManagedObjectContexts];

RKEntityMapping *articleMapping = [RKEntityMapping mappingForEntityForName:@"Article" inManagedObjectStore:managedObjectStore];
[articleMapping addAttributeMappingsFromArray:@[@"title", @"author", @"body"]];

NSString *seedPath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"MySeedDatabase.sqlite"];
RKManagedObjectImporter *importer = [[RKManagedObjectImporter alloc] initWithManagedObjectModel:managedObjectStore.managedObjectModel storePath:seedPath];

// Import the files "articles.json" from the Main Bundle using our RKEntityMapping
// JSON looks like {"articles": [ {"title": "Article 1", "body": "Text", "author": "Blake" ]}
NSError *error;
NSBundle *mainBundle = [NSBundle mainBundle];
[importer importObjectsFromItemAtPath:[mainBundle pathForResource:@"articles" ofType:@"json"]
                          withMapping:articleMapping
                              keyPath:@"articles"
                                error:&error];

BOOL success = [importer finishImporting:&error];
if (success) {
	[importer logSeedingInfo];
}
```

### Index and Search an Entity
``` objective-c
NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:managedObjectModel];
NSError *error = nil;
BOOL success = RKEnsureDirectoryExistsAtPath(RKApplicationDataDirectory(), &error);
if (! success) {
    RKLogError(@"Failed to create Application Data Directory at path '%@': %@", RKApplicationDataDirectory(), error);
}
NSString *path = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"Store.sqlite"];
NSPersistentStore *persistentStore = [managedObjectStore addSQLitePersistentStoreAtPath:path fromSeedDatabaseAtPath:nil withConfiguration:nil options:nil error:&error];
if (! persistentStore) {
    RKLogError(@"Failed adding persistent store at path '%@': %@", path, error);
}
[managedObjectStore createManagedObjectContexts];
[managedObjectStore addSearchIndexingToEntityForName:@"Article" onAttributes:@[ @"title", @"body" ]];
[managedObjectStore addInMemoryPersistentStore:nil];
[managedObjectStore createManagedObjectContexts];
[managedObjectStore startIndexingPersistentStoreManagedObjectContext];

Article *article1 = [NSEntityDescription insertNewObjectForEntityForName:@"Article" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
article1.title = @"First Article";
article1.body = "This should match search";

Article *article2 = [NSEntityDescription insertNewObjectForEntityForName:@"Article" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
article2.title = @"Second Article";
article2.body = "Does not";

BOOL success = [managedObjectStore.mainQueueManagedObjectContext saveToPersistentStore:nil];

RKSearchPredicate *predicate = [RKSearchPredicate searchPredicateWithText:@"Match" type:NSAndPredicateType];
NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Article"];
fetchRequest.predicate = predicate;

// Contains article1 due to body text containing 'match'
NSArray *matches = [managedObjectStore.mainQueueManagedObjectContext executeFetchRequest:fetchRequest error:nil];
NSLog(@"Found the matching articles: %@", matches);
```

### Unit Test a Mapping
``` objective-c
// JSON looks like {"article": {"title": "My Article", "author": "Blake", "body": "Very cool!!"}}
RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[Article class]];
[mapping addAttributeMappingsFromArray:@[@"title", @"author", @"body"]];

NSDictionary *article = @{ @"article": @{ @"title": @"My Title", @"body": @"The article body", @"author": @"Blake" } };
RKMappingTest *mappingTest = [[RKMappingTest alloc] initWithMapping:mapping sourceObject:article destinationObject:nil];

[mappingTest expectMappingFromKeyPath:@"title" toKeyPath:@"title" value:@"My Title"];
[mappingTest performMapping];
[mappingTest verify];
```

## Requirements

RestKit requires [iOS 8.0](https://developer.apple.com/library/ios/releasenotes/General/WhatsNewIniOS/Articles/iOS8.html#//apple_ref/doc/uid/TP40014205-SW1) and above or [Mac OS X 10.9](https://developer.apple.com/library/mac/releasenotes/MacOSX/WhatsNewInOSX/Articles/MacOSX10_9.html#//apple_ref/doc/uid/TP40013207-CH100) and above.

Several third-party open source libraries are used within RestKit, including:

1. [AFNetworking](https://github.com/AFNetworking/AFNetworking) - Networking Support
2. [LibComponentLogging](http://0xc0.de/LibComponentLogging) - Logging Support
3. [SOCKit](https://github.com/NimbusKit/sockit) - String <-> Object Coding
4. [iso8601parser](http://boredzo.org/iso8601parser/) - Support for parsing and generating ISO-8601 dates

The following Cocoa frameworks must be linked into the application target for proper compilation:

1. **CFNetwork.framework** on iOS
1. **CoreData.framework**
1. **Security.framework**
1. **MobileCoreServices.framework** on iOS or **CoreServices.framework** on OS X

And the following linker flags must be set:

1. **-ObjC**
1. **-all_load**

### ARC

As of [version 0.20.0](https://github.com/RestKit/RestKit/wiki/Restkit-0.20.0), RestKit has migrated the entire codebase to ARC.

If you are including the RestKit sources directly into a project that does not yet use [Automatic Reference Counting](http://clang.llvm.org/docs/AutomaticReferenceCounting.html), you will need to set the `-fobjc-arc` compiler flag on all of the RestKit source files. To do this in Xcode, go to your active target and select the "Build Phases" tab. Now select all RestKit source files, press Enter, insert `-fobjc-arc` and then "Done" to enable ARC for RestKit.

### Serialization Formats

RestKit provides a pluggable interface for handling arbitrary serialization formats via the [`RKSerialization`](http://restkit.org/api/latest/Classes/RKSerialization.html) protocol and the [`RKMIMETypeSerialization`](http://restkit.org/api/latest/Classes/RKMIMETypeSerialization.html) class. Out of the box, RestKit supports handling the [JSON](http://www.json.org/) format for serializing and deserializing object representations via the [`NSJSONSerialization`](http://developer.apple.com/library/mac/#documentation/Foundation/Reference/NSJSONSerialization_Class/Reference/Reference.html) class.

#### Additional Serializations

Support for additional formats and alternate serialization backends is provided via external modules that can be added to the project. Currently the following serialization implementations are available for use:

* JSONKit
* SBJSON
* YAJL
* NextiveJson
* XMLReader + XMLWriter

## Installation

The recommended approach for installing RestKit is via the [CocoaPods](http://cocoapods.org/) package manager, as it provides flexible dependency management and dead simple installation. For best results, it is recommended that you install via CocoaPods **>= 0.19.1** using Git **>= 1.8.0** installed via Homebrew.

### via CocoaPods

Install CocoaPods if not already available:

``` bash
$ [sudo] gem install cocoapods
$ pod setup
```

Change to the directory of your Xcode project, and Create and Edit your Podfile and add RestKit:

``` bash
$ cd /path/to/MyProject
$ touch Podfile
$ edit Podfile
platform :ios, '5.0'
# Or platform :osx, '10.7'
pod 'RestKit', '~> 0.24.0'

# Testing and Search are optional components
pod 'RestKit/Testing', '~> 0.24.0'
pod 'RestKit/Search',  '~> 0.24.0'
```

Install into your project:

``` bash
$ pod install
```

Open your project in Xcode from the .xcworkspace file (not the usual project file)

``` bash
$ open MyProject.xcworkspace
```

Please note that if your installation fails, it may be because you are installing with a version of Git lower than CocoaPods is expecting. Please ensure that you are running Git **>= 1.8.0** by executing `git --version`. You can get a full picture of the installation details by executing `pod install --verbose`.

### From a Release Package or as a Git submodule

Detailed installation instructions are available in the [Visual Install Guide](https://github.com/RestKit/RestKit/wiki/Installing-RestKit-v0.20.x-as-a-Git-Submodule) on the Wiki.

## Using RestKit in a Swift Project

Install RestKit using one of the above methods. Then add `@import RestKit;` (if RestKit is built as a dynamic framework) or `#import <RestKit/RestKit.h>` (if RestKit is built as a static library) into the bridging header for your Swift project. To enable the Core Data functionality in RestKit, add `@import CoreData;` into your bridging header _before_ you import RestKit.

## License

RestKit is licensed under the terms of the [Apache License, version 2.0](http://www.apache.org/licenses/LICENSE-2.0.html). Please see the [LICENSE](LICENSE) file for full details.

## Credits

RestKit is brought to you by [Blake Watters](http://twitter.com/blakewatters) and the RestKit team.

Support is provided by the following organizations:

* [GateGuru](http://www.gateguruapp.com/)
* [Two Toasters](http://www.twotoasters.com/)
