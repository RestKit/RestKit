//
//  RKParserRegistry.h
//  RestKit
//
//  Created by Blake Watters on 5/18/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
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
 RKParserRegistry provides for the registration of RKParser classes
 that handle parsing/serializing for content by MIME Type. Registration
 is configured via exact string matches (i.e. application/json) or via regular
 expression.
*/
@interface RKParserRegistry : NSObject {
    NSMutableDictionary *_MIMETypeToParserClasses;
    NSMutableArray *_MIMETypeToParserClassesRegularExpressions;
}

/**
 Return the global shared singleton registry for MIME Type to Parsers

 @return The global shared RKParserRegistry instance.
 */
+ (RKParserRegistry *)sharedRegistry;

/**
 Sets the global shared registry singleton to a new instance of RKParserRegistry

 @param registry A new parser registry object to configure as the shared instance.
 */
+ (void)setSharedRegistry:(RKParserRegistry *)registry;

/**
 Returns an instance of the RKParser conformant class registered to handle content
 with the given MIME Type.

 MIME Types are searched in the order in which they are registered and exact
 string matches are favored over regular expressions.

 @param MIMEType The MIME Type of the content to be parsed/serialized.
 @return An instance of the RKParser conformant class registered to handle the given MIME Type.
 */
- (id<RKParser>)parserForMIMEType:(NSString *)MIMEType;

/**
 Returns an instance of the RKParser conformant class registered to handle content
 with the given MIME Type.

 MIME Types are searched in the order in which they are registered and exact
 string matches are favored over regular expressions.

 @param MIMEType The MIME Type of the content to be parsed/serialized.
 @return The RKParser conformant class registered to handle the given MIME Type.
 */
- (Class<RKParser>)parserClassForMIMEType:(NSString *)MIMEType;

/**
 Registers an RKParser conformant class as the handler for MIME Types exactly matching the
 specified MIME Type string.

 @param parserClass The RKParser conformant class to instantiate when parsing/serializing MIME Types matching MIMETypeExpression.
 @param MIMEType A MIME Type string for which instances of parserClass should be used for parsing/serialization.
 */
- (void)setParserClass:(Class<RKParser>)parserClass forMIMEType:(NSString *)MIMEType;

#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 1070 || __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000

/**
 Registers an RKParser conformant class as the handler for MIME Types matching the
 specified regular expression.

 @param parserClass The RKParser conformant class to instantiate when parsing/serializing MIME Types matching MIMETypeExpression.
 @param MIMETypeRegex A regular expression that matches MIME Types that should be handled by instances of parserClass.
 */
- (void)setParserClass:(Class<RKParser>)parserClass forMIMETypeRegularExpression:(NSRegularExpression *)MIMETypeRegex;

#endif

/**
 Automatically configure the registry via run-time reflection of the RKParser classes
 available that ship with RestKit. This happens automatically when the shared registry
 singleton is initialized and makes configuration transparent to users.
 */
- (void)autoconfigure;

@end
