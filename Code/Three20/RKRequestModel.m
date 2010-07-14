//
//  RKRequestModel.m
//  RestKit
//
//  Created by Jeff Arena on 4/26/10.
//  Copyright 2010 RestKit. All rights reserved.
//

#import "RKRequestModel.h"
#import <Three20/Three20.h>

@implementation RKRequestModel
@synthesize objects = _objects;
@synthesize loaded = _loaded;
@synthesize resourcePath = _resourcePath;
@synthesize params = _params;
@synthesize loadingRequest = _loadingRequest;
@synthesize method = _method;
@synthesize fetchRequest = _fetchRequest;
@synthesize refreshRate = _refreshRate;

+ (id)modelWithResourcePath:(NSString*)resourcePath delegate:(id)delegate {
	return [[[self alloc] initWithResourcePath:resourcePath delegate:delegate] autorelease];
}

+ (id)modelWithResourcePath:(NSString*)resourcePath params:(NSDictionary*)params delegate:(id)delegate {
	return [[[self alloc] initWithResourcePath:resourcePath params:params delegate:delegate] autorelease];
}

- (id)initWithResourcePath:(NSString*)resourcePath delegate:(id)delegate {
	if (self = [self init]) {
		_resourcePath = [resourcePath retain];
		_delegate = [delegate retain];
	}
	
	return self;
}

- (id)initWithResourcePath:(NSString*)resourcePath params:(NSDictionary*)params delegate:(id)delegate {
	if (self = [self init]) {
		_resourcePath = [resourcePath retain];
		_params = [params retain];
		_delegate = [delegate retain];
	}
	
	return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// NSObject

- (id)init {
	if (self = [super init]) {
		_loadingRequest = nil;		
		_objects = nil;
		_delegate = nil;
		_params = nil;
		_loaded = NO;
		_method = RKRequestMethodGET;
		_fetchRequest = nil;
		_refreshRate = (60*60); // 1 hour default
	}
	return self;
}

- (void)dealloc {
	[_delegate release];
	[_loadingRequest cancel];
	[_loadingRequest release];
	_loadingRequest = nil;
	[_params release];
	_params = nil;
	[_objects release];
	_objects = nil;
	[_fetchRequest release];
	[super dealloc];
}
	
///////////////////////////////////////////////////////////////////////////////////////////////////
// RKRequestDelegate

- (void)requestDidStartLoad:(RKRequest*)request {
	if ([_delegate respondsToSelector:@selector(rkModelDidStartLoad)]) {
		[_delegate rkModelDidStartLoad];
	}
}

- (void)requestDidFinishLoad:(RKRequest*)request {
	[self saveLoadedTime];
	if ([_delegate respondsToSelector:@selector(rkModelDidFinishLoad)]) {
		[_delegate rkModelDidFinishLoad];
	}
	[_loadingRequest release];_loadingRequest=nil;	
}

// TODO: I get replaced...
- (void)request:(RKRequest*)request didFailLoadWithError:(NSError*)error {
	[_loadingRequest release];_loadingRequest=nil;
	if ([_delegate respondsToSelector:@selector(rkModelDidFailLoadWithError:)]) {
		[_delegate rkModelDidFailLoadWithError:error];
	}
}

- (void)requestDidCancelLoad:(RKRequest*)request {
	[_loadingRequest release];_loadingRequest=nil;
	if ([_delegate respondsToSelector:@selector(rkModelDidCancelLoad)]) {
		[_delegate rkModelDidCancelLoad];
	}
}

- (BOOL)needsRefresh {
	NSDate* loadedTime = self.loadedTime;
	if (loadedTime) {
		BOOL outdated = -[loadedTime timeIntervalSinceNow] > _refreshRate;
		return outdated;
	}
	return YES;
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
	if (_fetchRequest != nil) {
		if ([_delegate respondsToSelector:@selector(rkModelDidStartLoad)]) {
			[_delegate rkModelDidStartLoad];
		}
		
		_objects = [[RKManagedModel objectsWithRequest:_fetchRequest] retain];
		_loaded = YES;
		
		if ([_delegate respondsToSelector:@selector(rkModelDidFinishLoad)]) {
			[_delegate rkModelDidFinishLoad];
		}
		
		// TODO: What if self.needsRefresh does the update load???
		if ([self needsRefresh]) {
			[self load];
		}
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
		[[RKModelManager manager] goOffline];
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
- (void)modelLoaderRequest:(RKRequest*)request didLoadModels:(NSArray*)models response:(RKResponse*)response modelObject:(id<RKModelMappable>)modelObject {
	NSMutableArray* modelsArray = [[NSMutableArray alloc] init];
	for (NSObject* object in models) {
		if ([object isKindOfClass:[NSManagedObjectID class]]) {
			[modelsArray addObject:[RKManagedModel objectWithId:(NSManagedObjectID*)object]];
		} else {
			[modelsArray addObject:object];
		}
	}
	
	[self modelsDidLoad:[NSArray arrayWithArray:modelsArray]];
	[modelsArray release];
}

- (void)modelLoaderRequest:(RKRequest*)request didFailWithError:(NSError*)error response:(RKResponse*)response modelObject:(id<RKModelMappable>)modelObject {
	if ([self errorWarrantsOptionToGoOffline:error]) {
		[self showAlertWithOptionToGoOfflineForError:error];
	} else {
		[_delegate didFailLoadWithError:error];
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// public

- (void)setFetchRequest:(NSFetchRequest*)fetchRequest {
	[_fetchRequest release];
	_fetchRequest = [fetchRequest retain];
	[self loadFromObjectCache];
}

- (void)reset {
	[self clearLoadedTime];
}

- (void)load {
	if (_params) {
		_loadingRequest = [[RKModelManager manager] loadModels:_resourcePath fetchRequest:_fetchRequest method:_method params:_params delegate:self];
	} else {
		_loadingRequest = [[RKModelManager manager] loadModels:_resourcePath fetchRequest:_fetchRequest method:_method delegate:self];
	}	
}

@end
