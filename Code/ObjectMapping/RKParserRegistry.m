//
//  RKParserRegistry.m
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

#import "RKParserRegistry.h"

RKParserRegistry *gSharedRegistry;

@implementation RKParserRegistry

+ (RKParserRegistry *)sharedRegistry
{
    if (gSharedRegistry == nil) {
        gSharedRegistry = [RKParserRegistry new];
        [gSharedRegistry autoconfigure];
    }

    return gSharedRegistry;
}

+ (void)setSharedRegistry:(RKParserRegistry *)registry
{
    [registry retain];
    [gSharedRegistry release];
    gSharedRegistry = registry;
}

- (id)init
{
    self = [super init];
    if (self) {
        _MIMETypeToParserClasses = [[NSMutableDictionary alloc] init];
        _MIMETypeToParserClassesRegularExpressions = [[NSMutableArray alloc] init];
    }

    return self;
}

- (void)dealloc
{
    [_MIMETypeToParserClasses release];
    [_MIMETypeToParserClassesRegularExpressions release];
    [super dealloc];
}

- (Class<RKParser>)parserClassForMIMEType:(NSString *)MIMEType
{
    id parserClass = [_MIMETypeToParserClasses objectForKey:MIMEType];
#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 1070 || __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
    if (!parserClass)
    {
        for (NSArray *regexAndClass in _MIMETypeToParserClassesRegularExpressions) {
            NSRegularExpression *regex = [regexAndClass objectAtIndex:0];
            NSUInteger numberOfMatches = [regex numberOfMatchesInString:MIMEType options:0 range:NSMakeRange(0, [MIMEType length])];
            if (numberOfMatches) {
                parserClass = [regexAndClass objectAtIndex:1];
                break;
            }
        }
    }
#endif
    return parserClass;
}

- (void)setParserClass:(Class<RKParser>)parserClass forMIMEType:(NSString *)MIMEType
{
    [_MIMETypeToParserClasses setObject:parserClass forKey:MIMEType];
}

#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 1070 || __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000

- (void)setParserClass:(Class<RKParser>)parserClass forMIMETypeRegularExpression:(NSRegularExpression *)MIMETypeRegex
{
    NSArray *expressionAndClass = [NSArray arrayWithObjects:MIMETypeRegex, parserClass, nil];
    [_MIMETypeToParserClassesRegularExpressions addObject:expressionAndClass];
}

#endif

- (id<RKParser>)parserForMIMEType:(NSString *)MIMEType
{
    Class parserClass = [self parserClassForMIMEType:MIMEType];
    if (parserClass) {
        return [[[parserClass alloc] init] autorelease];
    }

    return nil;
}

- (void)autoconfigure
{
    Class parserClass = nil;

    // JSON
    NSSet *JSONParserClassNames = [NSSet setWithObjects:@"RKJSONParserJSONKit", @"RKJSONParserYAJL", @"RKJSONParserSBJSON", @"RKJSONParserNXJSON", nil];
    for (NSString *parserClassName in JSONParserClassNames) {
        parserClass = NSClassFromString(parserClassName);
        if (parserClass) {
            [self setParserClass:parserClass forMIMEType:RKMIMETypeJSON];
            break;
        }
    }

    // XML
    parserClass = NSClassFromString(@"RKXMLParserXMLReader");
    if (parserClass) {
        [self setParserClass:parserClass forMIMEType:RKMIMETypeXML];
        [self setParserClass:parserClass forMIMEType:RKMIMETypeTextXML];
    }
}

@end
