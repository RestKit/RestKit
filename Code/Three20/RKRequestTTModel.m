//
//  RKRequestTTModel.m
//  RestKit
//
//  Created by Blake Watters on 2/9/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKRequestTTModel.h"
#import "RKManagedObjectStore.h"

static NSTimeInterval defaultRefreshRate = NSTimeIntervalSince1970;
static NSString* const kDefaultLoadedTimeKey = @"RKRequestTTModelDefaultLoadedTimeKey";

@interface RKRequestTTModel (Private)

- (void)clearLoadedTime;
- (void)saveLoadedTime;
- (BOOL)errorWarrantsOptionToGoOffline:(NSError*)error;
- (void)showAlertWithOptionToGoOfflineForError:(NSError*)error;
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;
- (void)modelsDidLoad:(NSArray*)models;
- (void)load;

@end


@implementation RKRequestTTModel

@synthesize objects = _objects;
@synthesize resourcePath = _resourcePath;
@synthesize params = _params;
@synthesize objectLoader = _objectLoader;
@synthesize method = _method;
@synthesize refreshRate = _refreshRate;

+ (NSDate*)defaultLoadedTime {
	NSDate* defaultLoadedTime = [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultLoadedTimeKey];
	if (defaultLoadedTime == nil) {
		defaultLoadedTime = [NSDate date];
		[[NSUserDefaults standardUserDefaults] setObject:defaultLoadedTime forKey:kDefaultLoadedTimeKey];
	}
	return defaultLoadedTime;
}

+ (NSTimeInterval)defaultRefreshRate {
	return defaultRefreshRate;
}

+ (void)setDefaultRefreshRate:(NSTimeInterval)newDefaultRefreshRate {
	defaultRefreshRate = defaultRefreshRate;
}

- (id)initWithResourcePath:(NSString*)resourcePath {
	if (self = [self init]) {
		_resourcePath = [resourcePath retain];
	}
	return self;
}

- (id)initWithResourcePath:(NSString*)resourcePath params:(NSDictionary*)params {
	if (self = [self initWithResourcePath:resourcePath]) {
		self.params = [params retain];
	}	
	return self;
}

- (id)initWithResourcePath:(NSString*)resourcePath params:(NSDictionary*)params objectClass:(Class)klass {
	if (self = [self initWithResourcePath:resourcePath params:params]) {
		_objectClass = [klass retain];
	}
	return self;
}

- (id)initWithResourcePath:(NSString*)resourcePath params:(NSDictionary*)params objectClass:(Class)klass keyPath:(NSString*)keyPath {
	if (self = [self initWithResourcePath:resourcePath params:params objectClass:klass]) {
		_keyPath = [keyPath retain];
	}
	return self;
}

- (id)initWithResourcePath:(NSString*)resourcePath params:(NSDictionary*)params method:(RKRequestMethod)method {
	if (self = [self initWithResourcePath:resourcePath params:params]) {
		_method = method;
	}
	return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// NSObject

- (id)init {
	if (self = [super init]) {
		self.method = RKRequestMethodGET;
		self.refreshRate = [RKRequestTTModel defaultRefreshRate];
		self.params = nil;
		_cacheLoaded = NO;
		_objects = nil;
		_loaded = NO;
		_resourcePath = nil;
		_objectLoader = nil;
	}
	return self;
}

- (void)dealloc {
	[_objectLoader setDelegate:nil];
	[self cancel];
	[_objectLoader release];
	_objectLoader = nil;
	[_objects release];
	_objects = nil;
	[_objectClass release];
	_objectClass = nil;
	[_keyPath release];
	_keyPath = nil;
	self.params = nil;
	[super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// TTModel

- (BOOL)isLoaded {
	return _loaded;
}

- (BOOL)isLoading {
	return nil != _objectLoader;
}

- (BOOL)isLoadingMore {
	return NO;
}

- (BOOL)isOutdated {
	return (![self isLoading] && (-[self.loadedTime timeIntervalSinceNow] > _refreshRate));
}

- (void)cancel {
	if (_objectLoader && _objectLoader.request) {
		[_objectLoader.request cancel];
	}
}

- (void)invalidate:(BOOL)erase {
	// TODO: Note sure how to handle erase...
	[self clearLoadedTime];
}

- (void)load:(TTURLRequestCachePolicy)cachePolicy more:(BOOL)more {
	[self load];
}

- (NSDate*)loadedTime {
	NSDate* loadedTime = [[NSUserDefaults standardUserDefaults] objectForKey:_resourcePath];
	if (loadedTime == nil) {
		return [RKRequestTTModel defaultLoadedTime];
	}
	return loadedTime;
}

#pragma mark RKModelLoaderDelegate

// This callback is invoked after the request has been fully serviced. Finish the load here.
- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray*)objects {
	if (objectLoader == _objectLoader) {
		[_objectLoader release];
		_objectLoader = nil;
		[self modelsDidLoad:objects];
	}
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
	if (objectLoader == _objectLoader) {
		[_objectLoader release];
		_objectLoader = nil;
	}
	if ([self errorWarrantsOptionToGoOffline:error]) {
		[self showAlertWithOptionToGoOfflineForError:error];
	} else {
		[self didFailLoadWithError:error];
	}
}

- (void)objectLoaderDidLoadUnexpectedResponse:(RKObjectLoader*)objectLoader {
	[objectLoader release];
	_objectLoader = nil;
	[self didFailLoadWithError:nil];
}


#pragma mark RKRequestDelegate

- (void)requestDidFinishLoad:(RKRequest*)request {
	[self saveLoadedTime];
	[self didFinishLoad];
}

- (void)request:(RKRequest*)request didFailLoadWithError:(NSError*)error {
	[self didFailLoadWithError:error];
}

- (void)requestDidCancelLoad:(RKRequest*)request {
	[self didCancelLoad];
}


#pragma mark RKRequestTTModel (Private)

- (void)clearLoadedTime {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:_resourcePath];
}

- (void)saveLoadedTime {
	[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:_resourcePath];
}

- (BOOL)errorWarrantsOptionToGoOffline:(NSError*)error {
	switch ([error code]) {
		case NSURLErrorTimedOut:
		case NSURLErrorCannotFindHost:
		case NSURLErrorCannotConnectToHost:
		case NSURLErrorNetworkConnectionLost:
		case NSURLErrorDNSLookupFailed:
		case NSURLErrorNotConnectedToInternet:
		case NSURLErrorInternationalRoamingOff:
			return YES;
			break;
		default:
			return NO;
			break;
	}
}

- (void)showAlertWithOptionToGoOfflineForError:(NSError*)error {
	UIAlertView* alert = [[[UIAlertView alloc] initWithTitle:TTLocalizedString(@"Network Error", @"")
													 message:[error localizedDescription]
													delegate:self
										   cancelButtonTitle:TTLocalizedString(@"OK", @"")
										   otherButtonTitles:TTLocalizedString(@"Go Offline", @""), nil] autorelease];
	[alert show];
}

- (void)alertView:(UIAlertView*)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	// Go Offline button
	if (1 == buttonIndex) {
		[[RKObjectManager sharedManager] goOffline];
	}
}

- (void)modelsDidLoad:(NSArray*)models {
	[models retain];
	[_objects release];
	_objects = nil;
	
	_objects = models;
	_loaded = YES;
	
	[self didFinishLoad];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// public

- (void)load {		
	RKManagedObjectStore* store = [RKObjectManager sharedManager].objectStore;
	NSArray* cacheFetchRequests = nil;
	NSArray* cachedObjects = nil;
	if (store.managedObjectCache) {
		cacheFetchRequests = [store.managedObjectCache fetchRequestsForResourcePath:self.resourcePath];
		cachedObjects = [RKManagedObject objectsWithFetchRequests:cacheFetchRequests];
	}
	
	if (!store.managedObjectCache || !cacheFetchRequests || _cacheLoaded || [cachedObjects count] == 0) {
		_objectLoader = [[[RKObjectManager sharedManager] objectLoaderWithResourcePath:_resourcePath delegate:self] retain];
		_objectLoader.method = self.method;
		_objectLoader.objectClass = _objectClass;
		_objectLoader.keyPath = _keyPath;
		_objectLoader.params = self.params;
		
		[self didStartLoad];
		[_objectLoader send];
		
	} else if (cacheFetchRequests && !_cacheLoaded) {
		_cacheLoaded = YES;
		[self modelsDidLoad:cachedObjects];
	}
}

@end
