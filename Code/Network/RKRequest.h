//
//  RKRequest.h
//  RestKit
//
//  Created by Jeremy Ellison on 7/27/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "RKRequestSerializable.h"
#import "RKJSONSerialization.h"

/**
 * HTTP methods for requests
 */
typedef enum RKRequestMethod {
	RKRequestMethodGET = 0,
	RKRequestMethodPOST,
	RKRequestMethodPUT,
	RKRequestMethodDELETE
} RKRequestMethod;

/**
 * Background Request Policy
 *
 * On iOS 4.x and higher, UIKit provides
 * support for continueing activities for a limited amount
 * of time in the background. RestKit provides simple
 * support for continuing a request when in the background.
 */
typedef enum RKRequestBackgroundPolicy {
    RKRequestBackgroundPolicyNone = 0,      // Take no action with regards to backgrounding
    RKRequestBackgroundPolicyCancel,        // Cancel the request on transition to the background
    RKRequestBackgroundPolicyContinue,      // Continue the request in the background until time expires
    RKRequestBackgroundPolicyRequeue        // Stop the request and place it back on the queue. It will fire when the app reopens
} RKRequestBackgroundPolicy;

@class RKResponse;
@protocol RKRequestDelegate;

@interface RKRequest : NSObject {
	NSURL* _URL;
	NSMutableURLRequest* _URLRequest;
	NSURLConnection* _connection;
	NSDictionary* _additionalHTTPHeaders;
	NSObject<RKRequestSerializable>* _params;
	NSObject<RKRequestDelegate>* _delegate;
	id _userData;
	NSString* _username;
	NSString* _password;
	RKRequestMethod _method;
	BOOL _isLoading;
	BOOL _isLoaded;
    RKRequestBackgroundPolicy _backgroundPolicy;
    
    #if TARGET_OS_IPHONE
    UIBackgroundTaskIdentifier _backgroundTaskIdentifier;
    #endif
}

/**
 * The URL this request is loading
 */
@property(nonatomic, readonly) NSURL* URL;

/**
 * The resourcePath portion of this loader's URL
 */
@property (nonatomic, readonly) NSString* resourcePath;

/**
 * The HTTP verb the request is sent via
 *
 * @default RKRequestMethodGET
 */
@property(nonatomic, assign) RKRequestMethod method;

/**
 * A serializable collection of parameters sent as the HTTP Body of the request
 */
@property(nonatomic, retain) NSObject<RKRequestSerializable>* params;

/**
 * The delegate to inform when the request is completed
 *
 * If the object implements the RKRequestDelegate protocol,
 * it will receive request lifecycle event messages.
 */
@property(nonatomic, assign) NSObject<RKRequestDelegate>* delegate;

/**
 * A Dictionary of additional HTTP Headers to send with the request
 */
@property(nonatomic, retain) NSDictionary* additionalHTTPHeaders;

/**
 * An opaque pointer to associate user defined data with the request.
 */
@property(nonatomic, retain) id userData;

/**
 * The policy to take on transition to the background (iOS 4.x and higher only)
 *
 * Default: RKRequestBackgroundPolicyCancel
 */
#if TARGET_OS_IPHONE
@property(nonatomic, assign) RKRequestBackgroundPolicy backgroundPolicy;
@property(nonatomic, readonly) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
#endif

/**
 * Credentials for HTTP AUTH Challenge
 */

// The authentication scheme to use. When set to kCFHTTPAuthenticationSchemeBasic, authentication will
// be setup before a challenge occurs
@property(nonatomic, retain) NSString* username;
@property(nonatomic, retain) NSString* password;

/**
 * The underlying NSMutableURLRequest sent for this request
 */
@property(nonatomic, readonly) NSMutableURLRequest* URLRequest;

/**
 * The HTTP method as a string used for this request
 */
@property(nonatomic, readonly) NSString* HTTPMethod;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

/**
 * Return a REST request that is ready for dispatching
 */
+ (RKRequest*)requestWithURL:(NSURL*)URL delegate:(id)delegate;

/**
 * Initialize a synchronous request
 */
- (id)initWithURL:(NSURL*)URL;

/**
 * Initialize a REST request and prepare it for dispatching
 */
- (id)initWithURL:(NSURL*)URL delegate:(id)delegate;


/**
 * Setup the NSURLRequest. The request must be prepared right before dispatching
 */
- (void)prepareURLRequest;

/**
 * Send the request asynchronously. It will be added to the queue and
 * dispatched as soon as possible.
 */
- (void)send;

/**
 * Immediately dispatch a request asynchronously, skipping the request queue
 */
- (void)sendAsynchronously;

/**
 * Send the request synchronously and return a hydrated response object
 */
- (RKResponse*)sendSynchronously;

/**
 * Callback performed to notify the request that the underlying NSURLConnection
 * has failed with an error.
 */
- (void)didFailLoadWithError:(NSError*)error;

/**
 * Callback performed to notify the request that the underlying NSURLConnection
 * has completed with a response.
 */
- (void)didFinishLoad:(RKResponse*)response;

/**
 * Cancels the underlying URL connection.
 * This will send the requestDidCancel: delegate method
 * if your delegate responds to it. It then nils out the delegate
 * to ensure no more messages are sent to it.
 */
- (void)cancel;

/**
 * Returns YES when this is a GET request
 */
- (BOOL)isGET;

/**
 * Returns YES when this is a POST request
 */
- (BOOL)isPOST;

/**
 * Returns YES when this is a PUT request
 */
- (BOOL)isPUT;

/**
 * Returns YES when this is a DELETE request
 */
- (BOOL)isDELETE;

/**
 * Returns YES when this request is in-progress
 */
- (BOOL)isLoading;

/**
 * Returns YES when this request has been completed
 */
- (BOOL)isLoaded;

/**
 * Returns YES when the request was sent to the specified resource path
 */
- (BOOL)wasSentToResourcePath:(NSString*)resourcePath;

@end

/**
 * Lifecycle events for RKRequests
 */
@protocol RKRequestDelegate
@optional

/**
 * Sent when a request has finished loading
 */
- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response;

/**
 * Sent when a request has failed due to an error
 */
- (void)request:(RKRequest*)request didFailLoadWithError:(NSError*)error;

/**
 * Sent when a request has started loading
 */
- (void)requestDidStartLoad:(RKRequest*)request;

/**
 * Sent when a request has uploaded data to the remote site
 */
- (void)request:(RKRequest*)request didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;

/**
 * Sent to the delegate when a request was cancelled
 */
- (void)requestDidCancelLoad:(RKRequest*)request;

/**
 * Sent to the delegate when a request has timed out. This is sent when a
 * backgrounded request expired before completion.
 */
- (void)requestDidTimeout:(RKRequest*)request;

@end
