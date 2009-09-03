//
//  OTRestModelManager.h
//  OTRestFramework
//
//  Created by Jeremy Ellison on 8/14/09.
//  Copyright 2009 Objective3. All rights reserved.
//

#import "OTRestModelMapper.h"
#import "OTRestClient.h"

@interface OTRestModelManager : NSObject {
	OTRestClient* _client;
	OTRestModelMapper* _mapper;
}

+ (OTRestModelManager*)manager;
+ (void)setManager:(OTRestModelManager*)manager;
+ (OTRestModelManager*)managerWithBaseURL:(NSString*)baseURL;
- (id)initWithBaseURL:(NSString*)baseURL;

/**
 * The rest client for this manager
 */
@property (nonatomic, readonly) OTRestClient* client;

/**
 * Register a model mapping from a domain model class to an XML element name
 */
- (void)registerModel:(Class<OTRestModelMappable>)class forElementNamed:(NSString*)elementName;

/**
 * The model mapper for this manager
 */
@property(nonatomic, readonly) OTRestModelMapper* mapper;

/**
 * Fetch a resource via an HTTP GET and invoke a callback with the model for the resulting payload
 */
- (OTRestRequest*)loadModel:(NSString*)resourcePath delegate:(id)delegate callback:(SEL)callback;

/**
 * Fetch a resource via an HTTP GET and invoke a callback with the model for the resulting payload
 */
- (OTRestRequest*)loadModels:(NSString*)resourcePath delegate:(id)delegate callback:(SEL)callback;

- (OTRestRequest*)getModel:(id<OTRestModelMappable>)model delegate:(id)delegate callback:(SEL)callback;
- (OTRestRequest*)postModel:(id<OTRestModelMappable>)model delegate:(id)delegate callback:(SEL)callback;
- (OTRestRequest*)putModel:(id<OTRestModelMappable>)model delegate:(id)delegate callback:(SEL)callback;
- (OTRestRequest*)deleteModel:(id<OTRestModelMappable>)model delegate:(id)delegate callback:(SEL)callback;


@end
