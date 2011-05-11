//
//  RKObjectSeeder.m
//  RestKit
//
//  Created by Blake Watters on 3/4/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKManagedObjectSeeder.h"
#import "RKManagedObjectStore.h"

@interface RKManagedObjectSeeder (Private)
- (id)initWithObjectManager:(RKObjectManager*)manager;
- (void)seedObjectsFromFileNames:(NSArray*)fileNames;
@end

NSString* const RKDefaultSeedDatabaseFileName = @"RKSeedDatabase.sqlite";

@implementation RKManagedObjectSeeder

@synthesize delegate = _delegate;

+ (void)generateSeedDatabaseWithObjectManager:(RKObjectManager*)objectManager fromFiles:(NSString*)firstFileName, ... {
    RKManagedObjectSeeder* seeder = [RKManagedObjectSeeder objectSeederWithObjectManager:objectManager];
    
    va_list args;
    va_start(args, firstFileName);
	NSMutableArray* fileNames = [NSMutableArray array];
    for (NSString* fileName = firstFileName; fileName != nil; fileName = va_arg(args, id)) {
        [fileNames addObject:fileName];
    }
    va_end(args);
    
    // Seed the files
    for (NSString* fileName in fileNames) {
        [seeder seedObjectsFromFile:fileName toClass:nil keyPath:nil];
    }
    
    [seeder finalizeSeedingAndExit];
}

+ (RKManagedObjectSeeder*)objectSeederWithObjectManager:(RKObjectManager*)objectManager {
    return [[[RKManagedObjectSeeder alloc] initWithObjectManager:objectManager] autorelease];
}

- (id)initWithObjectManager:(RKObjectManager*)manager {
    self = [self init];
	if (self) {
		_manager = [manager retain];
        
        // If the user hasn't configured an object store, set one up for them
        if (nil == _manager.objectStore) {
            _manager.objectStore = [RKManagedObjectStore objectStoreWithStoreFilename:RKDefaultSeedDatabaseFileName];
        }
        
        // Delete any existing persistent store
        [_manager.objectStore deletePersistantStore];
	}
	
	return self;
}

- (void)dealloc {
	[_manager release];
	[super dealloc];
}

- (NSString*)pathToSeedDatabase {
    return _manager.objectStore.pathToStoreFile;
}

- (void)seedObjectsFromFiles:(NSString*)firstFileName, ... {
    va_list args;
    va_start(args, firstFileName);
	NSMutableArray* fileNames = [NSMutableArray array];
    for (NSString* fileName = firstFileName; fileName != nil; fileName = va_arg(args, id)) {
        [fileNames addObject:fileName];
    }
    va_end(args);
    
    for (NSString* fileName in fileNames) {
        [self seedObjectsFromFile:fileName toClass:nil keyPath:nil];
    }
}

- (void)seedObjectsFromFile:(NSString*)fileName toClass:(Class<RKObjectMappable>)nilOrMppableClass keyPath:(NSString*)nilOrKeyPath {
    NSError* error = nil;
    NSArray* mappedObjects;
	NSString* filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:nil];
	NSString* payload = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    
	if (payload != nil) {
        // TODO: When we support multiple parsers, we should auto-detect the MIME Type from the file extension
        // and pass it through to the mapper
		id objects = [_manager.mapper parseString:payload];
		NSAssert1(objects != nil, @"Unable to parse data from file %@", filePath);
        if (nilOrKeyPath) {
            objects = [objects valueForKeyPath:nilOrKeyPath];
        }
		NSAssert1([objects isKindOfClass:[NSArray class]], @"Expected an NSArray of objects, got %@", objects);
		NSAssert1([[objects objectAtIndex:0] isKindOfClass:[NSDictionary class]], @"Expected an array of NSDictionaries, got %@", [objects objectAtIndex:0]);
		
        if (nilOrMppableClass) {
            mappedObjects = [_manager.mapper mapObjectsFromArrayOfDictionaries:objects toClass:nilOrMppableClass];
        } else {
            mappedObjects = [_manager.mapper mapObjectsFromArrayOfDictionaries:objects];
        }
        
        // Inform the delegate
        if (self.delegate) {
            for (NSObject<RKObjectMappable>* object in mappedObjects) {
                [self.delegate didSeedObject:object fromFile:fileName];
            }
        }
        
		NSLog(@"[RestKit] RKManagedObjectSeeder: Seeded %d objects from %@...", [mappedObjects count], [NSString stringWithFormat:@"%@", fileName]);
	} else {
		NSLog(@"Unable to read file %@: %@", fileName, [error localizedDescription]);
	}
}

- (void)finalizeSeedingAndExit {
	NSError* error = [[_manager objectStore] save];
	if (error != nil) {
		NSLog(@"[RestKit] RKManagedObjectSeeder: Error saving object context: %@", [error localizedDescription]);
	}
	
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
	NSString* storeFileName = [[_manager objectStore] storeFilename];
	NSString* destinationPath = [basePath stringByAppendingPathComponent:storeFileName];
	NSLog(@"[RestKit] RKManagedObjectSeeder: A seeded database has been generated at '%@'. "
          @"Please execute `open \"%@\"` in your Terminal and copy %@ to your app. Be sure to add the seed database to your \"Copy Resources\" build phase.", 
          destinationPath, basePath, storeFileName);
	
	exit(1);
}

@end
