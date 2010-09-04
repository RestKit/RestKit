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
	NSFetchRequest* _fetchRequest;
}

/**
 * used for http auth chalange
 */
@property(nonatomic, retain) NSString* username;
@property(nonatomic, retain) NSString* password;

@property(nonatomic, readonly) NSURL* URL;

/**
 * The NSMutableURLRequest being sent for the Restful request
 */
@property(nonatomic, readonly) NSMutableURLRequest* URLRequest;

/**
 * The HTTP Method used for this request
 */
@property(nonatomic, readonly) NSString* HTTPMethod;

/**
 * The delegate to inform when the request is completed
 */
@property(nonatomic, retain) id delegate;

/**
 * The selector to invoke when the request is completed
 */
@property(nonatomic, assign) SEL callback;

/**
 * An opaque pointer to associate user defined data with the request.
 */
@property(nonatomic, retain) id userData;

/**
 * A Dictionary of additional HTTP Headers to send with the request
 */
@property(nonatomic, retain) NSDictionary* additionalHTTPHeaders;

/**
 * A serializable collection of parameters sent as the HTTP Body of the request
 */
// TODO: Should I be copy?
@property(nonatomic, retain) NSObject<RKRequestSerializable>* params;

/**
 * The HTTP verb the request is sent via
 */
@property(nonatomic, assign) RKRequestMethod method;

/**
 * NSFetchRequest used to obtain locally cached objects
 */
@property(nonatomic, retain) NSFetchRequest* fetchRequest;


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
 * Send the request asynchronously
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
@protocol RKRequestDelegate 
@optional
- (void)requestDidStartLoad:(RKRequest*)request;
- (void)requestDidFinishLoad:(RKRequest*)request;
- (void)request:(RKRequest*)request didFailLoadWithError:(NSError*)error;
- (void)requestDidCancelLoad:(RKRequest*)request;
@end
