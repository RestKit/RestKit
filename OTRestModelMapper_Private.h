/*
 *  OTRestModelMapper_Private.h
 *  OTRestFramework
 *
 *  Created by Jeremy Ellison on 8/18/09.
 *  Copyright 2009 Two Toasters. All rights reserved.
 *
 */

@interface OTRestModelMapper (Private)

- (id)buildModelFromJSON:(NSString*)JSON;
- (id)buildModelFromJSONDictionary:(NSDictionary*)dict;
- (void)setPropertiesOfModel:(id)model fromJSONDictionary:(NSDictionary*)dict;
- (void)setRelationshipsOfModel:(id)model fromJSONDictionary:(NSDictionary*)dict;
- (id)createOrUpdateInstanceOf:(Class)class fromJSONDictionary:(NSDictionary*)dict;
- (void)setAttributes:(id)object fromJSONDictionary:(NSDictionary*)dict;
- (id)buildModelFromXML:(Element*)XML;
- (id)createOrUpdateInstanceOf:(Class)class fromXML:(Element*)XML;
- (void)setAttributes:(id)object fromXML:(Element*)XML;
- (void)setPropertiesOfModel:(id)model fromXML:(Element*)XML;
- (void)setRelationshipsOfModel:(id)model fromXML:(Element*)XML;
- (NSString*)nameForProperty:(NSString*)property ofClass:(Class)class;
- (BOOL)isParentSelector:(NSString*)key;
- (NSString*)containingElementNameForSelector:(NSString*)selector;
- (NSString*)childElementNameForSelelctor:(NSString*)selector;

@end