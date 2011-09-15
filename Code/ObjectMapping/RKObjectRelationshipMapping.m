//
//  RKObjectRelationshipMapping.m
//  RestKit
//
//  Created by Blake Watters on 5/4/11.
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

#import "RKObjectRelationshipMapping.h"

@implementation RKObjectRelationshipMapping

@synthesize mapping = _mapping;
@synthesize reversible = _reversible;

+ (RKObjectRelationshipMapping*)mappingFromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath withMapping:(id<RKObjectMappingDefinition>)objectOrDynamicMapping reversible:(BOOL)reversible {
    RKObjectRelationshipMapping* relationshipMapping = (RKObjectRelationshipMapping*) [self mappingFromKeyPath:sourceKeyPath toKeyPath:destinationKeyPath];    
    relationshipMapping.reversible = reversible;
    relationshipMapping.mapping = objectOrDynamicMapping;
    return relationshipMapping;
}

+ (RKObjectRelationshipMapping*)mappingFromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath withMapping:(id<RKObjectMappingDefinition>)objectOrDynamicMapping {
    return [self mappingFromKeyPath:sourceKeyPath toKeyPath:destinationKeyPath withMapping:objectOrDynamicMapping reversible:YES];
}

- (id)copyWithZone:(NSZone *)zone {
    RKObjectRelationshipMapping* copy = [super copyWithZone:zone];
    copy.mapping = self.mapping;
    copy.reversible = self.reversible;
    return copy;
}

- (void)dealloc {
    [_mapping release];
    [super dealloc];
}

@end
