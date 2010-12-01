//
//  RKRequest.h
//  RestKit
//
//  Created by Jeremy Ellison on 7/27/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

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

@class RKResponse;

@interface RKRequest : NSObject {
	NSURL* _URL;
	NSMutableURLRequest* _URLRequest;
	NSURLConnection* _connection;
	NSDictionary* _additionalHTTPHeaders;
	NSObject<RKRequestSerializable>* _params;
	id _delegate;
	SEL _callback;
	id _userData;
	NSString* _username;
	NSString* _password;
	RKRequestMethod _method;
}

/**
 * The URL this request is loading
 */
@property(nonatomic, readonly) NSURL* URL;

/**
 * The HTTP verb the request is sent via
 *
 * @default RKRequestMethodGET
 */
@property(nonatomic, assign) RKRequestMethod method;

/**
 * A serializable collection of parameters sent as the HTTP Body of the request
 */
// TODO: Should I be copy?
@property(nonatomic, retain) NSObject<RKRequestSerializable>* params;

/**
 * The delegate to inform when the request is completed
 *
 * If the object implements the RKRequestDelegate protocol,
 * it will receive request lifecycle event messages.
 */
// TODO: Should be RKRequestDelegate instead of id
@property(nonatomic, assign) id delegate;

/**
 * The selector to invoke when the request is completed
 */
// TODO: Eliminate callback in favor of a delegate method (requestDidLoadResponse:) for simplicity
@property(nonatomic, assign) SEL callback;

/**
 * A Dictionary of additional HTTP Headers to send with the request
 */
@property(nonatomic, retain) NSDictionary* additionalHTTPHeaders;

/**
 * An opaque pointer to associate user defined data with the request.
 */
@property(nonatomic, retain) id userData;

/**
 * Credentials for HTTP AUTH Challenge
 */
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
+ (RKRequest*)requestWithURL:(NSURL*)URL delegate:(id)delegate callback:(SEL)callback;

/**
 * Initialize a synchronous request
 */
- (id)initWithURL:(NSURL*)URL;

/**
 * Initialize a REST request and prepare it for dispatching
 */
- (id)initWithURL:(NSURL*)URL delegate:(id)delegate callback:(SEL)callback;

/**
 * Send the request asynchronously. It will be added to the queue and
 * dispatched as soon as possible.
 */
- (void)send;

/**
 * Send the request synchronously and return a hydrated response object
 */
- (RKResponse*)sendSynchronously;

/**
 * Cancels the underlying URL connection
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

@end

/**
 * Lifecycle events for RKRequests
 *
 * Modeled off of TTURLRequest
 */
// TODO: Add a didLoadResponse: delegate method in place off callback
@protocol RKRequestDelegate 
@optional

/**
 * Sent when a request has started loading
 */
- (void)requestDidStartLoad:(RKRequest*)request;

/**
 * Sent when a request has finished loading
 */
- (void)requestDidFinishLoad:(RKRequest*)request;

/**
 * Sent when a request has failed due to an error
 */
- (void)request:(RKRequest*)request didFailLoadWithError:(NSError*)error;

/**
 * Sent when a request has been canceled
 */
- (void)requestDidCancelLoad:(RKRequest*)request;

/**
 * Sent when a request has uploaded data to the remote site
 */
- (void)request:(RKRequest*)request didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;

@end
