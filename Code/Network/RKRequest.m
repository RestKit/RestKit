//
//  RKRequest.m
//  RestKit
//
//  Created by Jeremy Ellison on 7/27/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKRequest.h"
#import "RKRequestQueue.h"
#import "RKResponse.h"
#import "NSDictionary+RKRequestSerialization.h"
#import "RKNotifications.h"
#import "RKClient.h"
#import "../Support/Support.h"
#import "RKURL.h"
#import "NSData+MD5.h"
#import "NSString+MD5.h"
#import "RKLog.h"
#import "RKRequestCache.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitNetwork

@implementation RKRequest

@synthesize URL = _URL, URLRequest = _URLRequest, delegate = _delegate, additionalHTTPHeaders = _additionalHTTPHeaders,
            params = _params, userData = _userData, username = _username, password = _password, method = _method,
            forceBasicAuthentication = _forceBasicAuthentication, cachePolicy = _cachePolicy, cache = _cache,
            cacheTimeoutInterval = _cacheTimeoutInterval;

#if TARGET_OS_IPHONE
@synthesize backgroundPolicy = _backgroundPolicy, backgroundTaskIdentifier = _backgroundTaskIdentifier;
#endif

+ (RKRequest*)requestWithURL:(NSURL*)URL delegate:(id)delegate {
	return [[[RKRequest alloc] initWithURL:URL delegate:delegate] autorelease];
}

- (id)initWithURL:(NSURL*)URL {
    self = [self init];
	if (self) {
		_URL = [URL retain];
        [self reset];
        _forceBasicAuthentication = NO;
		_cachePolicy = RKRequestCachePolicyDefault;
        _cacheTimeoutInterval = 0;
	}
	return self;
}

- (id)initWithURL:(NSURL*)URL delegate:(id)delegate {
    self = [self initWithURL:URL];
	if (self) {
		_delegate = delegate;
	}
	return self;
}

- (id)init {
    self = [super init];
    if (self) {        
#if TARGET_OS_IPHONE
        _backgroundPolicy = RKRequestBackgroundPolicyNone;
        _backgroundTaskIdentifier = 0; 
        BOOL backgroundOK = &UIBackgroundTaskInvalid != NULL;
        if (backgroundOK) {
            _backgroundTaskIdentifier = UIBackgroundTaskInvalid; 
        }
#endif
    }
    
    return self;
}

- (void)reset {
    if (_isLoading) {
        RKLogWarning(@"Request was reset while loading: %@. Canceling.", self);
        [self cancel];
    }
    [_URLRequest release];
    _URLRequest = [[NSMutableURLRequest alloc] initWithURL:_URL];
    [_URLRequest setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    [_connection release];
    _connection = nil;
    _isLoading = NO;
    _isLoaded = NO;
}

- (void)cleanupBackgroundTask {
    #if TARGET_OS_IPHONE
    BOOL backgroundOK = &UIBackgroundTaskInvalid != NULL;
    if (backgroundOK && UIBackgroundTaskInvalid == self.backgroundTaskIdentifier) {
        return;
    }
    
    UIApplication* app = [UIApplication sharedApplication];
    if ([app respondsToSelector:@selector(beginBackgroundTaskWithExpirationHandler:)]) {
    		[app endBackgroundTask:_backgroundTaskIdentifier];
    		_backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }
    #endif
}

- (void)dealloc {    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
  	self.delegate = nil;
  	[_connection cancel];
  	[_connection release];
  	_connection = nil;
  	[_userData release];
  	_userData = nil;
  	[_URL release];
  	_URL = nil;
  	[_URLRequest release];
  	_URLRequest = nil;
  	[_params release];
  	_params = nil;    
  	[_additionalHTTPHeaders release];
  	_additionalHTTPHeaders = nil;
  	[_username release];
  	_username = nil;
  	[_password release];
  	_password = nil;
    [_cache release];
    _cache = nil;
    
    // Cleanup a background task if there is any
    [self cleanupBackgroundTask];
     
    [super dealloc];
}

- (void)setRequestBody {
	if (_params && (_method != RKRequestMethodGET && _method != RKRequestMethodHEAD)) {
		// Prefer the use of a stream over a raw body
		if ([_params respondsToSelector:@selector(HTTPBodyStream)]) {
            // NOTE: This causes the stream to be retained. For RKParams, this will
            // cause a leak unless the stream is released. See [RKParams close]
			[_URLRequest setHTTPBodyStream:[_params HTTPBodyStream]];
		} else {
			[_URLRequest setHTTPBody:[_params HTTPBody]];
		}
	}
}

- (NSData*)HTTPBody {
    return self.URLRequest.HTTPBody;
}

- (void)setHTTPBody:(NSData *)HTTPBody {
    [self.URLRequest setHTTPBody:HTTPBody];
}

- (NSString*)HTTPBodyString {
    return [[[NSString alloc] initWithData:self.URLRequest.HTTPBody encoding:NSASCIIStringEncoding] autorelease];
}

- (void)setHTTPBodyString:(NSString *)HTTPBodyString {
    [self.URLRequest setHTTPBody:[HTTPBodyString dataUsingEncoding:NSASCIIStringEncoding]];
}

- (void)addHeadersToRequest {
	NSString* header;
	for (header in _additionalHTTPHeaders) {
		[_URLRequest setValue:[_additionalHTTPHeaders valueForKey:header] forHTTPHeaderField:header];
	}

	if (_params != nil) {
		// Temporarily support older RKRequestSerializable implementations
		if ([_params respondsToSelector:@selector(HTTPHeaderValueForContentType)]) {
			[_URLRequest setValue:[_params HTTPHeaderValueForContentType] forHTTPHeaderField:@"Content-Type"];
		} else if ([_params respondsToSelector:@selector(ContentTypeHTTPHeader)]) {
			[_URLRequest setValue:[_params performSelector:@selector(ContentTypeHTTPHeader)] forHTTPHeaderField:@"Content-Type"];
		}
		if ([_params respondsToSelector:@selector(HTTPHeaderValueForContentLength)]) {
			[_URLRequest setValue:[NSString stringWithFormat:@"%d", [_params HTTPHeaderValueForContentLength]] forHTTPHeaderField:@"Content-Length"];
		}
	} else {
        [_URLRequest setValue:@"0" forHTTPHeaderField:@"Content-Length"];
    }
    
    // Add authentication headers so we don't have to deal with an extra cycle for each message requiring basic auth.
    if (self.forceBasicAuthentication) {        
        CFHTTPMessageRef dummyRequest = CFHTTPMessageCreateRequest(kCFAllocatorDefault, (CFStringRef)[self HTTPMethod], (CFURLRef)[self URL], kCFHTTPVersion1_1);
        
        CFHTTPMessageAddAuthentication(dummyRequest, nil, (CFStringRef)_username, (CFStringRef)_password,kCFHTTPAuthenticationSchemeBasic, FALSE);
        CFStringRef authorizationString = CFHTTPMessageCopyHeaderFieldValue(dummyRequest, CFSTR("Authorization"));
        [_URLRequest setValue:(NSString *)authorizationString forHTTPHeaderField:@"Authorization"];
        CFRelease(dummyRequest);
        CFRelease(authorizationString);
    }
    
    if (self.cachePolicy & RKRequestCachePolicyEtag) {
        NSString* etag = [self.cache etagForRequest:self];
        if (etag) {
            [_URLRequest setValue:etag forHTTPHeaderField:@"If-None-Match"];
        }
    }
}

// Setup the NSURLRequest. The request must be prepared right before dispatching
- (BOOL)prepareURLRequest {
	[_URLRequest setHTTPMethod:[self HTTPMethod]];
	[self setRequestBody];
	[self addHeadersToRequest];
    
    NSString* body = [[NSString alloc] initWithData:[_URLRequest HTTPBody] encoding:NSUTF8StringEncoding];
    RKLogTrace(@"Prepared %@ URLRequest '%@'. HTTP Headers: %@. HTTP Body: %@.", [self HTTPMethod], _URLRequest, [_URLRequest allHTTPHeaderFields], body);
    [body release];
    
    return YES;
}

- (void)cancelAndInformDelegate:(BOOL)informDelegate {
	[_connection cancel];
	[_connection release];
	_connection = nil;
	_isLoading = NO;
    
    if (informDelegate && [_delegate respondsToSelector:@selector(requestDidCancelLoad:)]) {
        [_delegate requestDidCancelLoad:self];
    }
}

- (NSString*)HTTPMethod {
	switch (_method) {
		case RKRequestMethodGET:
			return @"GET";
			break;
		case RKRequestMethodPOST:
			return @"POST";
			break;
		case RKRequestMethodPUT:
			return @"PUT";
			break;
		case RKRequestMethodDELETE:
			return @"DELETE";
			break;
        case RKRequestMethodHEAD:
			return @"HEAD";
			break;
		default:
			return nil;
			break;
	}
}

- (void)send {
    NSAssert(NO == _isLoading || NO == _isLoaded, @"Cannot send a request that is loading or loaded without resetting it first.");
	[[RKRequestQueue sharedQueue] addRequest:self];
}

- (void)fireAsynchronousRequest {
    RKLogDebug(@"Sending asynchronous %@ request to URL %@.", [self HTTPMethod], [[self URL] absoluteString]);
    if (![self prepareURLRequest]) {
        // TODO: Logging
        return;
    }
    
    _isLoading = YES;    
    
    if ([self.delegate respondsToSelector:@selector(requestDidStartLoad:)]) {
        [self.delegate requestDidStartLoad:self];
    }
    
    RKResponse* response = [[[RKResponse alloc] initWithRequest:self] autorelease];
    _connection = [[NSURLConnection connectionWithRequest:_URLRequest delegate:response] retain];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:RKRequestSentNotification object:self userInfo:nil];
}

- (BOOL)shouldLoadFromCache {
    // if RKRequestCachePolicyEnabled or if RKRequestCachePolicyTimeout and we are in the timeout
    if ([self.cache hasResponseForRequest:self]) {
        if (self.cachePolicy & RKRequestCachePolicyEnabled) {
            return YES;
        } else if (self.cachePolicy & RKRequestCachePolicyTimeout) {
            NSDate* date = [self.cache cacheDateForRequest:self];
            NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:date];
            return interval <= self.cacheTimeoutInterval;
        }
    }
    return NO;
}

- (RKResponse*)loadResponseFromCache {
    RKLogDebug(@"Found cached content, loading...");
    return [self.cache responseForRequest:self];
}

- (BOOL)shouldDispatchRequest {
    return [RKClient sharedClient] == nil || [[RKClient sharedClient] isNetworkAvailable];
}

- (void)sendAsynchronously {
    NSAssert(NO == _isLoading || NO == _isLoaded, @"Cannot send a request that is loading or loaded without resetting it first.");
    _sentSynchronously = NO;    
    if ([self shouldLoadFromCache]) {
        RKResponse* response = [self loadResponseFromCache];
        _isLoading = YES;
        [self didFinishLoad:response];
    } else if ([self shouldDispatchRequest]) {
#if TARGET_OS_IPHONE
        // Background Request Policy support
        UIApplication* app = [UIApplication sharedApplication];
        if (self.backgroundPolicy == RKRequestBackgroundPolicyNone || 
            NO == [app respondsToSelector:@selector(beginBackgroundTaskWithExpirationHandler:)]) {
            // No support for background (iOS 3.x) or the policy is none -- just fire the request
            [self fireAsynchronousRequest];
        } else if (self.backgroundPolicy == RKRequestBackgroundPolicyCancel || self.backgroundPolicy == RKRequestBackgroundPolicyRequeue) {
            // For cancel or requeue behaviors, we watch for background transition notifications
            [[NSNotificationCenter defaultCenter] addObserver:self 
                                                     selector:@selector(appDidEnterBackgroundNotification:) 
                                                         name:UIApplicationDidEnterBackgroundNotification 
                                                       object:nil];
            [self fireAsynchronousRequest];
        } else if (self.backgroundPolicy == RKRequestBackgroundPolicyContinue) {
            RKLogInfo(@"Beginning background task to perform processing...");
            
            // Fork a background task for continueing a long-running request
            _backgroundTaskIdentifier = [app beginBackgroundTaskWithExpirationHandler:^{
                RKLogInfo(@"Background request time expired, canceling request.");
                
                [self cancelAndInformDelegate:NO];
                [self cleanupBackgroundTask];
                
                if ([_delegate respondsToSelector:@selector(requestDidTimeout:)]) {
                    [_delegate requestDidTimeout:self];
                }
            }];
            
            // Start the potentially long-running request
            [self fireAsynchronousRequest];
        }
#else
        [self fireAsynchronousRequest];
#endif
	} else {
        RKLogTrace(@"Declined to dispatch request %@: shared client reported the network is not available.", self);
        
	    if (_cachePolicy & RKRequestCachePolicyLoadIfOffline &&
			[self.cache hasResponseForRequest:self]) {

			_isLoading = YES;
			[self didFinishLoad:[self loadResponseFromCache]];

		} else {
            RKLogCritical(@"SharedClient = %@ and network availability = %d", [RKClient sharedClient], [[RKClient sharedClient] isNetworkAvailable]);
            NSString* errorMessage = [NSString stringWithFormat:@"The client is unable to contact the resource at %@", [[self URL] absoluteString]];
    		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
    								  errorMessage, NSLocalizedDescriptionKey,
    								  nil];
    		NSError* error = [NSError errorWithDomain:RKRestKitErrorDomain code:RKRequestBaseURLOfflineError userInfo:userInfo];
    		[self didFailLoadWithError:error];
        }
	}
}

- (RKResponse*)sendSynchronously {
    NSAssert(NO == _isLoading || NO == _isLoaded, @"Cannot send a request that is loading or loaded without resetting it first.");
	NSHTTPURLResponse* URLResponse = nil;
	NSError* error;
	NSData* payload = nil;
	RKResponse* response = nil;
    _sentSynchronously = YES;

	if ([self shouldLoadFromCache]) {
        response = [self loadResponseFromCache];
        _isLoading = YES;
        [self didFinishLoad:response];
    } else if ([self shouldDispatchRequest]) {
      RKLogDebug(@"Sending synchronous %@ request to URL %@.", [self HTTPMethod], [[self URL] absoluteString]);
		  if (![self prepareURLRequest]) {
      // TODO: Logging
        return nil;
      }

		[[NSNotificationCenter defaultCenter] postNotificationName:RKRequestSentNotification object:self userInfo:nil];

		_isLoading = YES;
        if ([self.delegate respondsToSelector:@selector(requestDidStartLoad:)]) {
            [self.delegate requestDidStartLoad:self];
        }
        
		payload = [NSURLConnection sendSynchronousRequest:_URLRequest returningResponse:&URLResponse error:&error];
		if (payload != nil) error = nil;
		
		response = [[[RKResponse alloc] initWithSynchronousRequest:self URLResponse:URLResponse body:payload error:error] autorelease];
		
		if (payload == nil) {
			[self didFailLoadWithError:error];
		} else {
			[self didFinishLoad:response];
		}
        
	} else {
		if (_cachePolicy & RKRequestCachePolicyLoadIfOffline &&
			[self.cache hasResponseForRequest:self]) {

			response = [self loadResponseFromCache];

		} else {
			NSString* errorMessage = [NSString stringWithFormat:@"The client is unable to contact the resource at %@", [[self URL] absoluteString]];
			NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									  errorMessage, NSLocalizedDescriptionKey,
									  nil];
			error = [NSError errorWithDomain:RKRestKitErrorDomain code:RKRequestBaseURLOfflineError userInfo:userInfo];
			[self didFailLoadWithError:error];
			response = [[[RKResponse alloc] initWithSynchronousRequest:self URLResponse:URLResponse body:payload error:error] autorelease];
		}
	}

	return response;
}

- (void)cancel {
    [self cancelAndInformDelegate:YES];
}

- (void)didFailLoadWithError:(NSError*)error {
	if (_cachePolicy & RKRequestCachePolicyLoadOnError &&
		[self.cache hasResponseForRequest:self]) {

		[self didFinishLoad:[self loadResponseFromCache]];
	} else {
		_isLoading = NO;

		if ([_delegate respondsToSelector:@selector(request:didFailLoadWithError:)]) {
			[_delegate request:self didFailLoadWithError:error];
		}
        
        NSDictionary* userInfo = [NSDictionary dictionaryWithObject:error forKey:RKRequestDidFailWithErrorNotificationUserInfoErrorKey];
		[[NSNotificationCenter defaultCenter] postNotificationName:RKRequestDidFailWithErrorNotification 
                                                            object:self 
                                                          userInfo:userInfo];
	}
}

- (void)updateInternalCacheDate {
    NSDate* date = [NSDate date];
    RKLogInfo(@"Updating cache date for request %@ to %@", self, date);
    [self.cache setCacheDate:date forRequest:self];
}

- (void)didFinishLoad:(RKResponse*)response {
  	_isLoading = NO;
  	_isLoaded = YES;
    
    RKLogInfo(@"Status Code: %d", [response statusCode]);
    RKLogInfo(@"Body: %@", [response bodyAsString]);

	RKResponse* finalResponse = response;

	if ((_cachePolicy & RKRequestCachePolicyEtag) && [response isNotModified]) {
		finalResponse = [self loadResponseFromCache];
        [self updateInternalCacheDate];
	}

	if (![response wasLoadedFromCache] && [response isSuccessful] && (_cachePolicy != RKRequestCachePolicyNone)) {
		[self.cache storeResponse:response forRequest:self];
	}

	if ([_delegate respondsToSelector:@selector(request:didLoadResponse:)]) {
		[_delegate request:self didLoadResponse:finalResponse];
	}
    
    if ([response isServiceUnavailable]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:RKServiceDidBecomeUnavailableNotification object:self];
    }
    
    // NOTE: This notification must be posted last as the request queue releases the request when it
    // receives the notification
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:finalResponse 
                                                         forKey:RKRequestDidLoadResponseNotificationUserInfoResponseKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:RKRequestDidLoadResponseNotification 
                                                        object:self 
                                                      userInfo:userInfo];
}

- (BOOL)isGET {
	return _method == RKRequestMethodGET;
}

- (BOOL)isPOST {
	return _method == RKRequestMethodPOST;
}

- (BOOL)isPUT {
	return _method == RKRequestMethodPUT;
}

- (BOOL)isDELETE {
	return _method == RKRequestMethodDELETE;
}

- (BOOL)isHEAD {
	return _method == RKRequestMethodHEAD;
}

- (BOOL)isLoading {
	return _isLoading;
}

- (BOOL)isLoaded {
	return _isLoaded;
}

- (BOOL)isUnsent {
    return _isLoading == NO && _isLoaded == NO;
}

- (NSString*)resourcePath {
	NSString* resourcePath = nil;
	if ([self.URL isKindOfClass:[RKURL class]]) {
		RKURL* url = (RKURL*)self.URL;
		resourcePath = url.resourcePath;
	}
	return resourcePath;
}

- (void)setURL:(NSURL *)URL {
    [URL retain];
    [_URL release];
    _URL = URL;
    _URLRequest.URL = URL;
}

- (void)setResourcePath:(NSString *)resourcePath {
    if ([self.URL isKindOfClass:[RKURL class]]) {
        self.URL = [RKURL URLWithBaseURLString:[(RKURL*)self.URL baseURLString] resourcePath:resourcePath];
	} else {
        [NSException raise:NSInvalidArgumentException format:@"Resource path can only be mutated when self.URL is an RKURL instance"];
    }
}

- (BOOL)wasSentToResourcePath:(NSString*)resourcePath {
	return [[self resourcePath] isEqualToString:resourcePath];
}

- (void)appDidEnterBackgroundNotification:(NSNotification*)notification {
#if TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    if (self.backgroundPolicy == RKRequestBackgroundPolicyCancel) {
        [self cancel];
    } else if (self.backgroundPolicy == RKRequestBackgroundPolicyRequeue) {
        // Cancel the existing request
        [self cancelAndInformDelegate:NO];
        [self send];
    }
#endif
}

- (NSString*)cacheKey {
    if (_method == RKRequestMethodDELETE) {
        return nil;
    }
    // Use [_params HTTPBody] because the URLRequest body may not have been set up yet.
    NSString* compositCacheKey = nil;
    if (_params) {
        if ([_params respondsToSelector:@selector(HTTPBody)]) {
            compositCacheKey = [NSString stringWithFormat:@"%@-%d-%@", self.URL, _method, [_params HTTPBody]];
        }
    } else {
        compositCacheKey = [NSString stringWithFormat:@"%@-%d", self.URL, _method];
    }
    return [compositCacheKey MD5];
}

@end
