//
//  RKObjectElementMapping.m
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
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

#import "RKObjectAttributeMapping.h"
#import "RKObjectTransformer.h"

@implementation RKObjectAttributeMapping

@synthesize sourceKeyPath = _sourceKeyPath;
@synthesize destinationKeyPath = _destinationKeyPath;
@synthesize transformer = _transformer;

/**
 @private
 */
- (id)initWithSourceKeyPath:(NSString*)sourceKeyPath andDestinationKeyPath:(NSString*)destinationKeyPath transformer:(id<RKObjectTransformer>)transformer {
    NSAssert(sourceKeyPath != nil, @"Cannot define an element mapping an element name to map from");
    NSAssert(destinationKeyPath != nil, @"Cannot define an element mapping without a property to apply the value to");
    self = [super init];
    if (self) {
        _sourceKeyPath = [sourceKeyPath retain];
        _destinationKeyPath = [destinationKeyPath retain];
        _transformer = [transformer retain];
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    RKObjectAttributeMapping* copy = [[[self class] allocWithZone:zone] initWithSourceKeyPath:self.sourceKeyPath andDestinationKeyPath:self.destinationKeyPath transformer:self.transformer];
    return copy;
}

- (void)dealloc {
    [_sourceKeyPath release];
    [_destinationKeyPath release];
    [_transformer release];
    
    [super dealloc];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"RKObjectKeyPathMapping: %@ => %@%@", self.sourceKeyPath,
            (_transformer ? [NSString stringWithFormat:@"%s => ",
                             object_getClassName(_transformer)] : @""),
            self.destinationKeyPath];
}

+ (RKObjectAttributeMapping*)mappingFromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath {
    RKObjectAttributeMapping* mapping = [[self alloc] initWithSourceKeyPath:sourceKeyPath andDestinationKeyPath:destinationKeyPath transformer:nil];
    return [mapping autorelease];
}

+ (RKObjectAttributeMapping*)mappingFromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath transformer:(id<RKObjectTransformer>)transformer {
    RKObjectAttributeMapping* mapping = [[self alloc] initWithSourceKeyPath:sourceKeyPath andDestinationKeyPath:destinationKeyPath transformer:transformer];
    return [mapping autorelease];
}

+ (RKObjectAttributeMapping*)inverseMappingForMapping:(RKObjectAttributeMapping*)forwardMapping
{
    return [self mappingFromKeyPath:forwardMapping.destinationKeyPath toKeyPath:forwardMapping.sourceKeyPath transformer:[forwardMapping.transformer inverseTransformer]];
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
