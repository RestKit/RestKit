//
//  RKResponse.h
//  RestKit
//
//  Created by Blake Watters on 7/28/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKRequest.h"
#import "DocumentRoot.h"

@interface RKResponse : NSObject {
	RKRequest* _request;
	NSHTTPURLResponse* _httpURLResponse;
	NSMutableData* _payload;
	NSError* _failureError;
	BOOL _loading;
}

/**
 * The request that generated this response
 */
@property(nonatomic, readonly) RKRequest* request;

/**
 * The URL the response was loaded from
 */
@property(nonatomic, readonly) NSURL* URL;

/**
 * The MIME Type of the response payload
 */
@property(nonatomic, readonly) NSString* MIMEType;

/**
 * The status code of the HTTP response
 */
@property(nonatomic, readonly) NSInteger statusCode;

/**
 * Return a dictionary of headers sent with the HTTP response
 */
@property(nonatomic, readonly) NSDictionary* allHeaderFields;

/**
 * The data returned as the response payload
 */
@property(nonatomic, readonly) NSData* payload;

/**
 * The error returned if the URL connection fails
 */
@property(nonatomic, readonly) NSError* failureError;


/**
 * Initialize a new response object for a REST request
 */
- (id)initWithRestRequest:(RKRequest*)request;

/**
 * Return the localized human readable representation of the HTTP Status Code returned
 */
- (NSString*)localizedStatusCodeString;

/**
 * Return the response payload as an NSString
 */
- (NSString*)payloadString;

/**
 * Parse the response payload into an XML Document via ElementParser
 */
- (DocumentRoot*)payloadXMLDocument;

/**
 * Parse the response into a dictionary from JSON
 */
- (NSDictionary*)payloadJSONDictionary;

/**
 * Will determine if there is an error object and use it's localized message
 */
- (NSString*)failureErrorDescription;

/**
 * Indicates that the connection failed to reach the remote server. The details of the failure
 * are available on the failureError reader.
 */
- (BOOL)isFailure;

/**
 * Indicates an invalid HTTP response code less than 100 or greater than 600
 */
- (BOOL)isInvalid;

/**
 * Indicates an HTTP response code between 100 and 199
 */
- (BOOL)isInformational;

/**
 * Indicates an HTTP response code between 200 and 299
 */
- (BOOL)isSuccessful;

/**
 * Indicates an HTTP response code between 300 and 399
 */
- (BOOL)isRedirection;

/**
 * Indicates an HTTP response code between 400 and 499
 */
- (BOOL)isClientError;

/**
 * Indicates an HTTP response code between 500 and 599
 */
- (BOOL)isServerError;

/**
 * Indicates that the response is either a server or a client error
 */
- (BOOL)isError;

/**
 * Indicates an HTTP response code of 200
 */
- (BOOL)isOK;

/**
 * Indicates an HTTP response code of 201
 */
- (BOOL)isCreated;

/**
 * Indicates an HTTP response code of 403
 */
- (BOOL)isForbidden;

/**
 * Indicates an HTTP response code of 404
 */
- (BOOL)isNotFound;

/**
 * Indicates an HTTP response code of 301, 302, 303 or 307
 */
- (BOOL)isRedirect;

/**
 * Indicates an empty HTTP response code of 201, 204, or 304
 */
- (BOOL)isEmpty;

/**
 * Returns the value of 'Content-Type' HTTP header
 */
- (NSString*)contentType;

/**
 * Returns the value of the 'Content-Length' HTTP header
 */
- (NSString*)contentLength;

/**
 * Returns the value of the 'Location' HTTP Header
 */
- (NSString*)location;

/**
 * True when the server turned an XML response (MIME type is application/xml)
 */
- (BOOL)isXML;

/**
 * True when the server turned an XML response (MIME type is application/json)
 */
- (BOOL)isJSON;

@end
