//
//  OTRestRequest.h
//  OTRestFramework
//
//  Created by Jeremy Ellison on 7/27/09.
//  Copyright 2009 Objective3. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DocumentRoot.h"
#import "OTRestRequestSerializable.h"

@interface OTRestRequest : NSObject {
	NSURL* _URL;
	NSMutableURLRequest* _URLRequest;
	NSDictionary* _additionalHTTPHeaders;
	NSObject<OTRestRequestSerializable>* _params;
	id _delegate;
	SEL _callback;
}

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
 * A Dictionary of additional HTTP Headers to send with the request
 */
@property(nonatomic, retain) NSDictionary* additionalHTTPHeaders;

/**
 * A serializable collection of parameters sent as the HTTP Body of the request
 */
@property(nonatomic, readonly) NSObject<OTRestRequestSerializable>* params;


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

/**
 * Return a REST request that is ready for dispatching
 */
+ (OTRestRequest*)requestWithURL:(NSURL*)URL delegate:(id)delegate callback:(SEL)callback;

/**
 * Initialize a REST request and prepare it for dispatching
 */
- (id)initWithURL:(NSURL*)URL delegate:(id)delegate callback:(SEL)callback;

/**
 * GET the resource and invoke the callback with the response payload
 */
- (void)get;

/**
 * POST a collection of params to the resource and invoke the callback with the response payload
 */
- (void)postParams:(NSObject<OTRestRequestSerializable>*)params;

/**
 * PUT a collection of params to the resource and invoke the callback with the response payload
 */
- (void)putParams:(NSObject<OTRestRequestSerializable>*)params;

/**
 * DELETE the resource and invoke the callback with the response payload
 */
- (void)delete;

@end
