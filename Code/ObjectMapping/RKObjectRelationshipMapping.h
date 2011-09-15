//
//  RKObjectRelationshipMapping.h
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

#import <Foundation/Foundation.h>
#import "RKObjectAttributeMapping.h"
#import "RKObjectMappingDefinition.h"

@class RKObjectmapping;

@interface RKObjectRelationshipMapping : RKObjectAttributeMapping {
    id<RKObjectMappingDefinition> _mapping;
    BOOL _reversible;
}

@property (nonatomic, retain) id<RKObjectMappingDefinition> mapping;
@property (nonatomic, assign) BOOL reversible;

+ (RKObjectRelationshipMapping*)mappingFromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath withMapping:(id<RKObjectMappingDefinition>)objectOrDynamicMapping;

+ (RKObjectRelationshipMapping*)mappingFromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath withMapping:(id<RKObjectMappingDefinition>)objectOrDynamicMapping reversible:(BOOL)reversible;

@end
