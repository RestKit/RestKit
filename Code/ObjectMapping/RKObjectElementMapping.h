//
//  RKObjectElementMapping.h
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>

//typedef enum {
//    RKObjectElementMappingTypeProperty,
//    RKObjectElementMappingTypeRelationship
//} RKObjectElementMappingType;

// Defines the rules for mapping a particular element
// TODO: This is probably a private class that is created via calls to the object mapping?
@interface RKObjectElementMapping : NSObject {
    NSString* _element;
    NSString* _property;
}

@property (nonatomic, retain) NSString* element;
@property (nonatomic, retain) NSString* property;

/*!
 Defines a mapping from an element to a particular property within an object mapping
 */
// TODO: could be toKeyPath:
+ (RKObjectElementMapping*)mappingFromElement:(NSString*)element toProperty:(NSString*)property;

@end
