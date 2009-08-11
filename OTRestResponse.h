//
//  OTRestResponse.h
//  gateguru
//
//  Created by Blake Watters on 7/28/09.
//  Copyright 2009 Objective 3. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTRestRequest.h"
#import "DocumentRoot.h"

@interface OTRestResponse : NSObject {
	OTRestRequest* _request;
	NSHTTPURLResponse* _httpURLResponse;
	NSMutableData* _payload;
	NSError* _error;
}

/**
 * The request that generated this response
 */
@property(nonatomic, readonly) OTRestRequest* request;

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
 * The error returned if the url connection fails
 */
@property(nonatomic, readonly) NSError* error;


/**
 * Initialize a new response object for a REST request
 */
- (id)initWithRestRequest:(OTRestRequest*)request;

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
 * Will determine if there is an error object and use it's localized message
 * or
 * take the first <error> element out of the returned document.
 */
- (NSString*)errorDescription;

@end
