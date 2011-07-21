//
//  RKManagedObjectMappingSpec.m
//  RestKit
//
//  Created by Blake Watters on 5/31/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKManagedObjectMapping.h"

@interface RKManagedObjectMappingSpec : RKSpec {
    
}

@end


@implementation RKManagedObjectMappingSpec

- (void)itShouldReturnTheDefaultValueForACoreDataAttribute {
    // Load Core Data
    RKSpecNewManagedObjectStore();
    
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForEntityWithName:@"RKCat"];
    id value = [mapping defaultValueForMissingAttribute:@"name"];
    assertThat(value, is(equalTo(@"Kitty Cat!")));
}

@end
