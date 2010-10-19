//
//  RKRequestModel.m
//  RestKit
//
//  Created by Jeff Arena on 4/26/10.
//  Copyright 2010 RestKit. All rights reserved.
//

#import "RKRequestModel.h"
#import "RKManagedObjectStore.h"
#import <Three20/Three20.h>

@implementation RKRequestModel
@synthesize objects = _objects;
@synthesize loaded = _loaded;
@synthesize resourcePath = _resourcePath;
@synthesize params = _params;
@synthesize objectLoader = _objectLoader;
@synthesize method = _method;
@synthesize refreshRate = _refreshRate;

- (id)initWithResourcePath:(NSString*)resourcePath delegate:(id)delegate {
	if (self = [self init]) {
		_resourcePath = [resourcePath retain];
		_delegate = [delegate retain];
	}
	[self loadFromObjectCache];
	
	return self;
}

- (id)initWithResourcePath:(NSString*)resourcePath params:(NSDictionary*)params delegate:(id)delegate {
	if (self = [self initWithResourcePath:resourcePath delegate:delegate]) {
		_params = [params retain];
	}	
	return self;
}

- (id)initWithResourcePath:(NSString*)resourcePath params:(NSDictionary*)params objectClass:(Class)klass delegate:(id)delegate {
	if (self = [self initWithResourcePath:resourcePath params:params delegate:delegate]) {
		_objectClass = [klass retain];
	}
	return self;
}

- (id)initWithResourcePath:(NSString*)resourcePath params:(NSDictionary*)params objectClass:(Class)klass keyPath:(NSString*)keyPath delegate:(id)delegate {
	if (self = [self initWithResourcePath:resourcePath params:params objectClass:klass delegate:delegate]) {
		_keyPath = [keyPath retain];
	}
	return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// NSObject

- (id)init {
	if (self = [super init]) {
		_method = RKRequestMethodGET;
		_refreshRate = NSTimeIntervalSince1970; // Essentially, default to never
	}
	return self;
}

- (void)dealloc {
	[_delegate release];
	[_objectLoader.request cancel];
	[_objectLoader release];
	[_params release];
	[_objects release];
	[_objectClass release];
	[_keyPath release];
	[super dealloc];
}
	
///////////////////////////////////////////////////////////////////////////////////////////////////
// RKRequestDelegate

- (void)requestDidFinishLoad:(RKRequest*)request {
	[self saveLoadedTime];
	if ([_delegate respondsToSelector:@selector(rkModelDidFinishLoad)]) {
		[_delegate rkModelDidFinishLoad];
	}
}

//// TODO: I get replaced...
- (void)request:(RKRequest*)request didFailLoadWithError:(NSError*)error {
	if ([_delegate respondsToSelector:@selector(rkModelDidFailLoadWithError:)]) {
		[_delegate rkModelDidFailLoadWithError:error];
	}
}

- (void)requestDidCancelLoad:(RKRequest*)request {
	if ([_delegate respondsToSelector:@selector(rkModelDidCancelLoad)]) {
		[_delegate rkModelDidCancelLoad];
	}
}

- (BOOL)needsRefresh {
	NSDate* loadedTime = self.loadedTime;
	BOOL outdated = NO;
	if (loadedTime) {
		outdated = -[loadedTime timeIntervalSinceNow] > _refreshRate;
	} else {
		[self saveLoadedTime];
	}
	return outdated;
}

- (void)clearLoadedTime {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:_resourcePath];
}

- (void)saveLoadedTime {
	[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:_resourcePath];
}

- (NSDate*)loadedTime {
	return [[NSUserDefaults standardUserDefaults] objectForKey:_resourcePath];
}

- (void)loadFromObjectCache {
	RKManagedObjectStore* store = [RKObjectManager globalManager].objectStore;
	NSArray* cachedObjects = nil;
	
	if (store.managedObjectCache) {
		cachedObjects = [RKManagedObject objectsWithFetchRequests:[store.managedObjectCache fetchRequestsForResourcePath:self.resourcePath]];
		
		if (cachedObjects && [cachedObjects count] > 0) {
			if ([_delegate respondsToSelector:@selector(rkModelDidStartLoad)]) {
				[_delegate rkModelDidStartLoad];
			}
			
			_objects = [cachedObjects retain];
			_loaded = YES;
			
			if ([_delegate respondsToSelector:@selector(rkModelDidLoad)]) {
				[_delegate rkModelDidLoad];
			}
		}
	}
	
	if (cachedObjects == nil || [cachedObjects count] == 0 || [self needsRefresh]) {
		[self load];
	}
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

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	// Go Offline button
	if (1 == buttonIndex) {
		[[RKObjectManager globalManager] goOffline];
	}
}

- (void)modelsDidLoad:(NSArray*)models {
	[models retain];
	[_objects release];
	_objects = models;
	_loaded = YES;
	
	// NOTE: You must finish load after clearing the loadingRequest and setting the loaded flag	
	if ([_delegate respondsToSelector:@selector(rkModelDidLoad)]) {
		[_delegate rkModelDidLoad];
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// RKModelLoaderDelegate

// This callback is invoked after the request has been fully serviced. Finish the load here.
- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects {
	[objectLoader release];
	_objectLoader = nil;
	[self modelsDidLoad:objects];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
	[objectLoader release];
	_objectLoader = nil;
	if ([self errorWarrantsOptionToGoOffline:error]) {
		[self showAlertWithOptionToGoOfflineForError:error];
	} else {
		[_delegate didFailLoadWithError:error];
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// public

- (void)reset {
	[self clearLoadedTime];
}

- (void)load {
	if ([_delegate respondsToSelector:@selector(rkModelDidStartLoad)]) {
		[_delegate rkModelDidStartLoad];
	}
	
	_objectLoader = [[[RKObjectManager globalManager] objectLoaderWithResourcePath:_resourcePath delegate:self] retain];
	_objectLoader.method = _method;
	_objectLoader.objectClass = _objectClass;
	_objectLoader.keyPath = _keyPath;
	_objectLoader.params = _params;
	[_objectLoader send];
}

@end
