//
//  RKParserRegistry.h
//  RestKit
//
//  Created by Blake Watters on 5/18/11.
//  Copyright 2011 Two Toasters
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "RKMIMETypes.h"
#import "RKParser.h"

/**
 The Parser Registry provides for the registration of RKParser classes
 for a particular MIME Type. This enables
 */
@interface RKParserRegistry : NSObject {
    NSMutableDictionary *_MIMETypeToParserClasses;
}

/**
 Return the global shared singleton registry for MIME Type to Parsers
 */
+ (RKParserRegistry *)sharedRegistry;

/**
 Sets the global shared registry singleton to a new instance of RKParserRegistry
 */
+ (void)setSharedRegistry:(RKParserRegistry *)registry;

/**
 Instantiate and return a Parser for the given MIME Type
 */
- (id<RKParser>)parserForMIMEType:(NSString *)MIMEType;

/**
 Return the class registered for handling parser/encoder operations
 for a given MIME Type
 */
- (Class<RKParser>)parserClassForMIMEType:(NSString *)MIMEType;

/**
 Registers an RKParser conformant class as the handler for the specified MIME Type
 */
- (void)setParserClass:(Class<RKParser>)parserClass forMIMEType:(NSString *)MIMEType;

/**
 Automatically configure the registry via run-time reflection of the RKParser classes
 available that ship with RestKit. This happens automatically when the shared registry
 singleton is initialized and makes configuration transparent to users.
 */
- (void)autoconfigure;

@end
