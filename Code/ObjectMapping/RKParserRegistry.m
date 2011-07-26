//
//  RKParserRegistry.m
//  RestKit
//
//  Created by Blake Watters on 5/18/11.
//  Copyright 2011 Two Toasters. All rights reserved.
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
    }
}

@end
