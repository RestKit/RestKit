//
//  RKParserRegistry.m
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

#import "RKParserRegistry.h"

RKParserRegistry* gSharedRegistry;

@implementation RKParserRegistry

+ (RKParserRegistry*)sharedRegistry {
    if (gSharedRegistry == nil) {
        gSharedRegistry = [RKParserRegistry new];
        [gSharedRegistry autoconfigure];
    }
    
    return gSharedRegistry;
}

+ (void)setSharedRegistry:(RKParserRegistry*)registry {
    [registry retain];
    [gSharedRegistry release];
    gSharedRegistry = registry;
}

- (id)init {
    self = [super init];
    if (self) {
        _MIMETypeToParserClasses = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)dealloc {
    [_MIMETypeToParserClasses release];
    [super dealloc];
}

- (Class<RKParser>)parserClassForMIMEType:(NSString*)MIMEType {
    return [_MIMETypeToParserClasses objectForKey:MIMEType];
}

- (void)setParserClass:(Class<RKParser>)parserClass forMIMEType:(NSString*)MIMEType {
    [_MIMETypeToParserClasses setObject:parserClass forKey:MIMEType];
}

- (id<RKParser>)parserForMIMEType:(NSString*)MIMEType {
    Class parserClass = [self parserClassForMIMEType:MIMEType];
    if (parserClass) {
        return [[[parserClass alloc] init] autorelease];
    }
    
    return nil;
}

- (void)autoconfigure {
    Class parserClass = nil;
    
    // JSON
    NSSet* JSONParserClassNames = [NSSet setWithObjects:@"RKJSONParserJSONKit", @"RKJSONParserYAJL", @"RKJSONParserSBJSON", @"RKJSONParserNXJSON", nil];    
    for (NSString* parserClassName in JSONParserClassNames) {
        parserClass = NSClassFromString(parserClassName);
        if (parserClass) {
            [self setParserClass:parserClass forMIMEType:RKMIMETypeJSON];
            break;
        }
    }
    
    // XML
    parserClass = NSClassFromString(@"RKXMLParserLibXML");
    if (parserClass) {
        [self setParserClass:parserClass forMIMEType:RKMIMETypeXML];
        [self setParserClass:parserClass forMIMEType:RKMIMETypeTextXML];
    }
}

@end
