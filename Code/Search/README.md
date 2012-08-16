# RestKit Managed Object Searching

RestKit includes a component for easily indexing and searching Core Data entities. This document details how to configure search indexing, perform searches against indexed entities, and explains the implementation details of the search support.

## Setup and Usage

For the sample code below, imagine that we have a `Recipe` entity containing string attributes `name` and `description`.

### Configuring Indexing

Indexing is configured through the managed object store and **must** be done before the managed object contexts have been created, as the search support modifies the searchable entity to include a new relationship.

```
	#import <RestKit/CoreData.h>
	#import <RestKit/Search.h>
	
	// Initialize the managed object model and RestKit managed object store
	NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
	RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:managedObjectModel];
	
	// Configure indexing for the Recipe entity
	[managedObjectStore addSearchIndexingToEntityForName:@"Recipe" onAttributes:@[ @"name", @"description" ]];
	
	// Create the managed object contexts and start indexing
	[managedObjectStore createManagedObjectContexts];
	[managedObjectStore startIndexingPrimaryManagedObjectContext];

```

Once indexing is configured, an instance of `RKSearchIndexer` will observe the primary managed object context for save notifications. On save, any managed objects whose entities were configured for indexing will have their searchable attributes tokenized and stored as a to-many relationship to the `RKSearchWordEntity` entity.

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

## Sample Code and Help

An example project is provided in the Examples subdirectory of the RestKit distribution.

The unit tests and headers are very thoroughly documented for this component. If you still have trouble and need help, please reach out via Github issues.

## Implementation Details

Search is implemented using the Apple recommended pattern of maintaining a relationship from the searchable entity to a bundled `RKSearchWordEntity` entity modeling each word in the designated searchable attributes. The `RKSearchWordEntity` entity is bundled with RestKit and is dynamically related to your Core Data entities at run time via invocation of `[RKSearchIndexer addSearchIndexingToEntity: onAttributes:]`. For each searchable entity a to-many relationship called `searchWords` is added to the entity and an inverse relationship named after the searchable entity is added to the `RKSearchWordEntity`.

### Indexing

The `RKSearchIndexer` class does all of the heavy lifting with regards to maintaining the searchable content. The indexer can invoked in three ways to update the indexes:

1. Manually via `- (void)indexManagedObject:(NSManagedObject *)`. This method tells the indexer to update the given object.
2. For an entire context on demand via `- (void)indexChangedObjectsInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext`. This methods tells the indexer to update the `searchWords` of all managed objects in the given context that have been changed since the last save.
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
- **Managing Automatic Indexing**: `- (void)startIndexingPrimaryManagedObjectContext` and `- (void)stopIndexingPrimaryManagedObjectContext`. These methods provide quick control over automatic indexing of the primary managed object context on save.
