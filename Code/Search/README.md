# RestKit Managed Object Searching

RestKit includes a component for easily indexing and searching Core Data entities. This document details how to configure search indexing, perform searches against indexed entities, and explains the implementation details of the search support.

## Setup and Usage

For the sample code below, imagine that we have a `Recipe` entity containing string attributes `name` and `description`.

### Configuring Indexing

Indexing is configured through the managed object store and **must** be done before the managed object contexts have been created, as the search support modifies the searchable entity to include a new relationship.

```objc
#import <RestKit/CoreData.h>
#import <RestKit/Search.h>

// Initialize the managed object model and RestKit managed object store
NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:managedObjectModel];

// Configure indexing for the Recipe entity
[managedObjectStore addSearchIndexingToEntityForName:@"Recipe" onAttributes:@[ @"name", @"description" ]];

// Create the managed object contexts and start indexing
[managedObjectStore createManagedObjectContexts];
[managedObjectStore startIndexingPersistentStoreManagedObjectContext];

```

Once indexing is configured, an instance of `RKSearchIndexer` will observe the persistent store managed object context for save notifications. On save, any managed objects whose entities were configured for indexing will have their searchable attributes tokenized and stored as a to-many relationship to the `RKSearchWordEntity` entity.

### Performing a Search

Searching an indexed entity is performed via a standard Core Data fetch request with a compound predicate that will match your search text against a list of search words associated with the target managed object.

```objc
#import <RestKit/CoreData.h>
#import <RestKit/Search.h>

/* Construct the predicate.
	
   Supported predicate types are NSNotPredicateType, NSAndPredicateType, and NSOrPredicateType. 
   See NSCompoundPredicate.h for details.
 */
RKSearchPredicate *searchPredicate = [RKSearchPredicate predicateWithSearchText:@"vietnamese food" type:NSAndPredicateType];

NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestForEntityWithName:@"Recipe"];
fetchRequest.predicate = searchPredicate;
NSError *error;	
NSArray *matches = [managedObjectStore.mainQueueManagedObjectContext executeFetchRequest:fetchRequest error:&error];

NSLog(@"Found the following matching recipes: %@", matches);

```

### Using an Indexing Context

For applications loading payloads containing a large number of searchable entities, it may become desirable to make use of a dedicated managed object context for the purposes of search indexing. When observing the persistent store context for changes, the indexer awaits the posting of a `NSManagedObjectContextWillSave` notification and performs indexing before the save is complete. Because of the nature of parent/child managed object contexts in Core Data, this can introduce blockage of any managed object contexts with the `NSMainQueueConcurrencyType` that are children of the persistent store context. 

To avoid this, a dedicated `indexingContext` can be assigned to the search indexer. When an indexing context is provided, the indexing is performed in response to a `NSManagedObjectContextDidSave` notification on the indexing context. It is recommended that the indexing context have a direct connection to the persistent store coordinator and that its changes are merged back into the persistent store and main queue managed object contexts via observation of the `NSManagedObjectContextDidSave`.

### Using a Cache to Accelerate Indexing

Indexing is an intensive operation and can take a significant amount of time to complete. By default, `RKSearchIndexer` uses fetch requests to search the store for an existing `RKSearchWord` object for each search word tokenized during indexing. This repeated execution of fetch requests is not the most efficient strategy from a CPU or real time consumption standpoint, but has the advantage of being very simple and requires no external dependencies beyond Core Data, making it ideal for small applications with basic search indexing needs.

Larger applications may begin to feel constrained from a performance standpoint by the fetch request implementation. The search indexer provides an affordance for introducing a caching strategy to accelerate the indexing operation via the `RKSearchIndexerDelegate` protocol. The search indexer's delegate is consulted during indexing and may provide an implementation of the method `searchIndexer:searchWordForWord:inManagedObjectContext:error:` method to return a `RKSearchWord` object for a given word.

If your application's searchable text is not extremely large (i.e. you are searching across names, addresses, etc as opposed to large paragraphs of text) then you may be able to leverage the RestKit `RKEntityByAttributeCache` to accelerate the indexing process. This cache class uses a specially crafted dictionary based fetch request to select out only the managed object ID and the value for an attribute and maintains an in memory cache. Look-ups are then performed entirely in memory, providing a dramatic speed-up. Within one large production application containing roughly 16,000 unique search words, indexing time for a seed database was reduced from 10 minutes to roughly 45 seconds using this cache strategy. But keep in mind that this cache keeps the entire index in memory, so you must profile your application to evaluate its suitability.

To configure an `RKEntityByAttributeCache` for indexing your application, add the following class to your application:

```objc

// MyAppSearchIndexingDelegate.h
@interface MyAppSearchIndexingDelegate : NSObject <RKSearchIndexerDelegate>
@end

// MyAppSearchIndexingDelegate.m
#import <RestKit/CoreData/RKEntityByAttributeCache.h>

@interface MyAppSearchIndexingDelegate ()
@property (nonatomic, strong) RKEntityByAttributeCache *searchWordCache;
@end

@implementation MyAppSearchIndexingDelegate

- (id)init
{
	self = [super init];
	if (self) {
		NSEntityDescription *searchWordEntity = [[self.managedObjectModel entitiesByName] objectForKey:RKSearchWordEntityName];
    	self.searchWordCache = [[RKEntityByAttributeCache alloc] initWithEntity:searchWordEntity attributes:@[ @"word" ] managedObjectContext:indexingContext];
    	[self.searchWordCache load];
	}
	
	return self;
}

- (RKSearchWord *)searchIndexer:(RKSearchIndexer *)searchIndexer searchWordForWord:(NSString *)word inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext error:(NSError **)error
{
    return (RKSearchWord *)[self.searchWordCache objectWithAttributeValue:word inContext:managedObjectContext];
}

- (void)searchIndexer:(RKSearchIndexer *)searchIndexer didInsertSearchWord:(RKSearchWord *)searchWord forWord:(NSString *)word inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    [self.searchWordCache addObject:(NSManagedObject *)searchWord];
}

@end

```

## Sample Code and Help

An example project is provided in the Examples subdirectory of the RestKit distribution.

The unit tests and headers are very thoroughly documented for this component. If you still have trouble and need help, please reach out via Github issues.

## Implementation Details

Search is implemented using the Apple recommended pattern of maintaining a relationship from the searchable entity to a bundled `RKSearchWordEntity` entity modeling each word in the designated searchable attributes. The `RKSearchWordEntity` entity is bundled with RestKit and is dynamically related to your Core Data entities at run time via invocation of `[RKSearchIndexer addSearchIndexingToEntity: onAttributes:]`. For each searchable entity a to-many relationship called `searchWords` is added to the entity and an inverse relationship named after the searchable entity is added to the `RKSearchWordEntity`.

### Indexing

The `RKSearchIndexer` class does all of the heavy lifting with regards to maintaining the searchable content. The indexer can invoked in three ways to update the indexes:

1. Manually via `- (void)indexManagedObject:(NSManagedObject *)`. This method tells the indexer to update the given object.
2. For an entire context on demand via `- (void)indexChangedObjectsInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext waitUntilFinished:(BOOL)wait`. This methods tells the indexer to update the `searchWords` of all managed objects in the given context that have been changed since the last save. The `wait` parameter determines whether indexing will be performed synchronously or asynchronously.
3. Automatically at managed object context save time via `- (void)startObservingManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;`. This methods tells the indexer to watch the given context for the `NSManagedObjectContextWillSaveNotification` and to update all changed objects when the context changes.

### Stop Words

The indexer supports the use of a list of 'stop words' to prevent the index from becoming cluttered with common, low value words. By default the list is nil, but can be set by assigning an `NSSet` of `NSString` words to ignore to an instance of `RKSearchIndexer`. Words in this list will be removed from the tokenized set of searchable text and will not have `RKSearchWord` instances created.

### Tokenization

The `RKSearchIndexer` and the `RKSearchPredicate` classes both rely on common functionality provided by the `RKSearchTokenizer` class. The tokenizer is responsible for taking a string of text and breaking into a normalized list of search words. The search words are built by folding the text to remove any diacritic marks, coercing it to lowercase, and then splitting the text into words as appropriate for the system's current locale (i.e. at whitespace boundaries for English and other Latin derived languages). The list of words is then turned into an `NSSet` to remove any duplicates.

### Search Predicate

The `RKSearchPredicate` is a very lightweight subclass of `NSCompoundPredicate`. It provides functionality for taking a string of text (typically supplied by the user via a search interface) and building a compound predicate for searching for the given text with one of the basic boolean operators (AND, OR, and NOT). The search predicate using an `RKSearchTokenizer` to process given text into tokens and then creates a sub-predicate for each search word and joins them together with a given `NSCompoundPredicateType` (`NSAndPredicateType`, `NSOrPredicateType`, and `NSNotPredicateType`).

### Convenience Methods

The search support is designed to be very easy to configure and use by snapping into the `RKManagedObjectStore` class. The relevant API's are:

- **Configure an Entity for Search**: `- (void)addSearchIndexingToEntityForName:(NSString *)entityName onAttributes:(NSArray *)attributes` - Adds search indexing to the entity with the given name in the receiver's managed object model for the given set of searchable string attributes.
- **Accessing the Search Indexer**: `@property (nonatomic, readonly) RKSearchIndexer *searchIndexer` Once indexing is configured for an entity, the `searchIndexer` property becomes available for use.
- **Managing Automatic Indexing**: `- (void)startIndexingPersistentStoreManagedObjectContext` and `- (void)stopIndexingPersistentStoreManagedObjectContext`. These methods provide quick control over automatic indexing of the persistent store managed object context on save.
