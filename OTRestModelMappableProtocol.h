/*
 *  OTRestModelMappableProtocol.h
 *  OTRestFramework
 *
 *  Created by Blake Watters on 8/14/09.
 *  Copyright 2009 Two Toasters. All rights reserved.
 *
 */

@class Element;

/**
 * Must be implemented by all classes utilizing the OTRestModelMapper to map REST
 * responses to domain model classes
 */
@protocol OTRestModelMappable

/**
 * Must return a dictionary containing mapping from XML element names to property accessors
 */
+ (NSDictionary*)elementToPropertyMappings;

/**
 * Must return a dictionary mapping XML element names to related object accessors. Must
 * return an empty dictionary if there are no related objects.
 *
 * To differentiate between single associated objects and collections, use descendent
 * selectors. For example, given a Project model associated with a user and a collection
 * of tasks:
 *
 * [NSDictionary dictionaryWithObject:@"user" forKey:@"user"];
 * Will map from an XML element named user to the user property on the model instance.
 *
 * [NSDictionary dictionaryWithObject:@"tasks" forKey:@"tasks > task"];
 * Will map from the collection of XML elements named task nested under the tasks element
 * to the tasks property on the model instance. The assigned collection is assumed to be an NSSet.
 */
+ (NSDictionary*)elementToRelationshipMappings;

@optional

/**
 * Must return the path to the resource on the server
 * used for get/put/post/delete
 * required if you intend to do get/put/post/delete requests
 */
- (NSString*)resourcePath;

/**
 * The path to the RESTful resource collection this object belongs to. i.e. /books
 */
- (NSString*)collectionPath;

/**
 * The path to the RESTful resource this object represents. i.e. /books/1
 */
- (NSString*)memberPath;

/**
 * Must return the put/post params for the instance
 */
- (NSDictionary*)resourceParams;

/**
 * Must return a new instance of the model class ready for mapping. Used to initialize the model
 * via any method other than alloc & init.
 */
+ (id)newObject;

/**
 * Must return the selector for the XML element corresponding to the primary key for this model instance.
 */
+ (NSString*)primaryKey;

/**
 * Must return the model instance corresponding to the given primary key value.
 * Expected to return nil if the model instance does not exist and hence we should
 * instantiate a new instance.
 */
+ (id)findByPrimaryKey:(id)value;

/**
 * If implemented, the model mapper will hand the xml to the object instead of mapping it using
 * elementToRelationshipMappings and elementToPropertyMappings
 */
- (void)digestXML:(Element*)e;

- (void)digestJSONDictionary:(NSDictionary*)dict;

@end
