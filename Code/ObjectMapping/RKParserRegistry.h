//
//  RKParserRegistry.h
//  RestKit
//
//  Created by Blake Watters on 5/18/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "../Support/RKMIMETypes.h"
#import "../Support/RKParser.h"

/**
 The Parser Registry provides for the registration of RKParser classes
 for a particular MIME Type. This enables
 */
@interface RKParserRegistry : NSObject {
    NSMutableDictionary* _MIMETypeToParserClasses;
}

/**
 Return the global shared singleton registry for MIME Type to Parsers
 */
+ (RKParserRegistry*)sharedRegistry;

/**
 Instantiate and return a Parser for the given MIME Type
 */
- (id<RKParser>)parserForMIMEType:(NSString*)MIMEType;

/**
 Return the class registered for handling parser/encoder operations
 for a given MIME Type
 */
- (Class<RKParser>)parserClassForMIMEType:(NSString*)MIMEType;

/**
 Registers an RKParser conformant class as the handler for the specified MIME Type
 */
- (void)setParserClass:(Class<RKParser>)parserClass forMIMEType:(NSString*)MIMEType;

/**
 Automatically configure the registry via run-time reflection of the RKParser classes
 available that ship with RestKit. This happens automatically when the shared registry
 singleton is initialized and makes configuration transparent to users.
 */
- (void)autoconfigure;

@end
