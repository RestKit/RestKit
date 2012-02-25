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

/*
 RegexForMIMEType:  MIMETypes should be specifiable as regular expressions.

		_MIMETypeToParserClasses			will remain as a dictionary of MIMETypes; existing could will remain unaffected and this retains the definitive nature of looking up the MIMEtype in a dictionary.
 (new)	_MIMETypeToParserClassesRegularExpressions
											add NSArray of regular expressions.
 
 Design notes:
		1.	Separate literals from regular expressions; this will preserve current runtime characteristics (lookup time) and provide greater compatibility with existing client code.
		2.	Keep RegularExpressions in an array; since multiple regular expressions may match a single MIMEType, it is important that there be a definite order of evaluation.
		3.	Order of Evaluation (parserForMIMEType:MIMEType: and parserClassForMIMEType:MIMEType:)
			a.	Lookup MIMEType in _MIMETypeToParserClasses
			b.	Lookup MIMEType in _MIMETypeToParserClassesRegularExpressions, starting with _MIMETypeToParserClassesRegularExpressions[0]
 
		setParserClass:forMIMEType:			should add a literal _MIMETypeToParserClasses
 (new)	setParserClass:forMIMETypeRegex:	should add a regular expression to _MIMETypeToParserClassesRegularExpressions

		parserForMIMEType:MIMEType:			and
		parserClassForMIMEType:MIMEType:	should return the parser class following the specified order of evaluation
 
*/
@interface RKParserRegistry : NSObject {
    NSMutableDictionary *_MIMETypeToParserClasses;
	NSMutableArray *_MIMETypeToParserClassesRegularExpressions;
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
 Registers an RKParser conformant class as the handler for the specified MIME Type
 */
- (void)setParserClass:(Class<RKParser>)parserClass forMIMETypeRegex:(NSRegularExpression *)MIMETypeExpression;

/**
 Automatically configure the registry via run-time reflection of the RKParser classes
 available that ship with RestKit. This happens automatically when the shared registry
 singleton is initialized and makes configuration transparent to users.
 */
- (void)autoconfigure;

@end
