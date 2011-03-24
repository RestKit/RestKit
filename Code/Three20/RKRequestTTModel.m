//
//  RKRequestTTModel.m
//  RestKit
//
//  Created by Blake Watters on 2/9/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKRequestTTModel.h"
#import "RKManagedObjectStore.h"
#import "../Network/Network.h"


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
	defaultRefreshRate = newDefaultRefreshRate;
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
		_isLoaded = NO;
		_isLoading = NO;
		_resourcePath = nil;
		_emptyReloadAttempted = NO;
	}
	return self;
}

- (void)dealloc {
	[[RKRequestQueue sharedQueue] cancelRequestsWithDelegate:self];
	[_objects release];
	_objects = nil;
	[_resourcePath release];
	_resourcePath = nil;
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
	return _isLoaded;
}

- (BOOL)isLoading {
	return _isLoading;
}

- (BOOL)isLoadingMore {
	return NO;
}

- (BOOL)isOutdated {
	NSTimeInterval sinceNow = [self.loadedTime timeIntervalSinceNow];
	if (![self isLoading] && !_emptyReloadAttempted && _objects && [_objects count] == 0) {
		_emptyReloadAttempted = YES;
		return YES;
	}
	return (![self isLoading] && (-sinceNow > _refreshRate));
}

- (void)cancel {
	[[RKRequestQueue sharedQueue] cancelRequestsWithDelegate:self];
	[self didCancelLoad];
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

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray*)objects {
	_isLoading = NO;
	[self saveLoadedTime];
	[self modelsDidLoad:objects];
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
	_isLoading = NO;
	[self didFailLoadWithError:error];
//	if ([self errorWarrantsOptionToGoOffline:error]) {
//		[self showAlertWithOptionToGoOfflineForError:error];
//	}
}

- (void)objectLoaderDidLoadUnexpectedResponse:(RKObjectLoader*)objectLoader {
	_isLoading = NO;

	// TODO: Passing a nil error here does nothing for Three20.  Need to construct our
	// own error here to make Three20 happy??
	[self didFailLoadWithError:nil];
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
													delegate:nil
										   cancelButtonTitle:TTLocalizedString(@"OK", @"")
										   otherButtonTitles:nil] autorelease];
	[alert show];
}

- (void)modelsDidLoad:(NSArray*)models {
	[models retain];
	[_objects release];
	_objects = nil;

	_objects = models;
	_isLoaded = YES;

	[self didFinishLoad];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// public

- (void)load {
	RKManagedObjectStore* store = [RKObjectManager sharedManager].objectStore;
	NSArray* cacheFetchRequests = nil;
	if (store.managedObjectCache) {
		cacheFetchRequests = [store.managedObjectCache fetchRequestsForResourcePath:self.resourcePath];
	}

	if (!store.managedObjectCache || !cacheFetchRequests || _cacheLoaded) {
		RKObjectLoader* objectLoader = [[RKObjectManager sharedManager] objectLoaderWithResourcePath:_resourcePath delegate:self];
		objectLoader.method = self.method;
		objectLoader.objectClass = _objectClass;
		objectLoader.keyPath = _keyPath;
		objectLoader.params = self.params;

		_isLoading = YES;
		[self didStartLoad];
		[objectLoader send];
	} else if (cacheFetchRequests && !_cacheLoaded) {
		_cacheLoaded = YES;
		[self modelsDidLoad:[RKManagedObject objectsWithFetchRequests:cacheFetchRequests]];
	}
}

@end
