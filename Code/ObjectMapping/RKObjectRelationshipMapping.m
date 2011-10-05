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
#import "RKObjectMapping.h"
#import "../Support/Support.h"

@implementation RKObjectRelationshipMapping

@synthesize mapping = _mapping;
@synthesize reversible = _reversible;

+ (RKObjectRelationshipMapping*)mappingFromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath withMapping:(id<RKObjectMappingDefinition>)objectOrDynamicMapping reversible:(BOOL)reversible transformer:(id<RKObjectTransformer>)transformer {
    RKObjectRelationshipMapping* relationshipMapping = (RKObjectRelationshipMapping*) [self mappingFromKeyPath:sourceKeyPath toKeyPath:destinationKeyPath transformer:transformer];    
    relationshipMapping.reversible = reversible;
    relationshipMapping.mapping = objectOrDynamicMapping;
    return relationshipMapping;
}

+ (RKObjectRelationshipMapping*)mappingFromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath withMapping:(id<RKObjectMappingDefinition>)objectOrDynamicMapping reversible:(BOOL)reversible {
    return [self mappingFromKeyPath:sourceKeyPath toKeyPath:destinationKeyPath withMapping:objectOrDynamicMapping reversible:reversible transformer:nil];
}


+ (RKObjectRelationshipMapping*)mappingFromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath withMapping:(id<RKObjectMappingDefinition>)objectOrDynamicMapping {
    return [self mappingFromKeyPath:sourceKeyPath toKeyPath:destinationKeyPath withMapping:objectOrDynamicMapping reversible:YES transformer:nil];
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


+ (RKObjectRelationshipMapping*)inverseMappingForMapping:(RKObjectRelationshipMapping*)forwardMapping depth:(int)depth
{
    if (!forwardMapping.reversible)
    {
        return nil;
    }
    RKObjectMapping* mapping = (RKObjectMapping*)[forwardMapping mapping];
    if (! [mapping isKindOfClass:[RKObjectMapping class]]) {
        RKLogWarning(@"Unable to generate inverse mapping for relationship '%@': %@ relationships cannot be inversed.", forwardMapping.sourceKeyPath, NSStringFromClass([mapping class]));
        return nil;
    }
    
    RKObjectMapping *inverseMapping = [mapping inverseMappingAtDepth:depth];
    id<RKObjectTransformer> inverseTransformer = [forwardMapping.transformer inverseTransformer];
    
    return [self mappingFromKeyPath:forwardMapping.destinationKeyPath toKeyPath:forwardMapping.sourceKeyPath withMapping:inverseMapping reversible:YES transformer:inverseTransformer];
}

-(id)valueFromSourceObject:(id)aSourceObject destinationType:(Class)aType defaultTransformer:(id<RKObjectTransformer>)defaultTransform error:(NSError**)error
{
    
    id value = nil;
    if ([self.sourceKeyPath isEqualToString:@""]) {
        value = aSourceObject;
    } else {
        value = [aSourceObject valueForKeyPath:self.sourceKeyPath];
    }
    
   
    
    if (value)
    {   
        // Handle case where incoming content is collection represented by a dictionary 
        if (self.mapping.forceCollectionMapping) {
            // If we have forced mapping of a dictionary, map each subdictionary
            if ([value isKindOfClass:[NSDictionary class]]) {
                RKLogDebug(@"Collection mapping forced for NSDictionary, mapping each key/value independently...");
                NSArray* objectsToMap = [NSMutableArray arrayWithCapacity:[value count]];
                for (id key in value) {
                    NSDictionary* dictionaryToMap = [NSDictionary dictionaryWithObject:[value valueForKey:key] forKey:key];
                    [(NSMutableArray*)objectsToMap addObject:dictionaryToMap];
                }
                value = objectsToMap;
            } else {
                RKLogWarning(@"Collection mapping forced but mappable objects is of type '%@' rather than NSDictionary", NSStringFromClass([value class]));
            }
        }
        
        // Handle case where incoming content is a single object, but we want a collection
        BOOL mappingToCollection = (aType && 
                                    ([aType isSubclassOfClass:[NSSet class]] || [aType isSubclassOfClass:[NSArray class]]));
        if (mappingToCollection && ![value isCollection]) {
            RKLogDebug(@"Asked to map a single object into a collection relationship. Transforming to an instance of: %@", NSStringFromClass(aType));
            if ([aType isSubclassOfClass:[NSArray class]]) {
                value = [aType arrayWithObject:value];
            } else if ([aType isSubclassOfClass:[NSSet class]]) {
                value = [aType setWithObject:value];
            } else {
                RKLogWarning(@"Failed to transform single object");
            }
        }
        
        if (self.transformer)
        {
            value = [_transformer transformedValue:value ofClass:aType error:error];
        }
        else if (aType && ![[value class] isSubclassOfClass:aType] && defaultTransform )
        {
            value = [defaultTransform transformedValue:value ofClass:aType error:error];
        }
    }
    
    return value;
}

@end
