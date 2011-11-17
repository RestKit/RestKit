//
//  RKTableViewCellMappingsSpec.m
//  RestKit
//
//  Created by Blake Watters on 8/9/11.
//  Copyright (c) 2011 RestKit. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKTableViewCellMappings.h"
#import "RKSpecUser.h"
#import "RKSpecAddress.h"

@interface RKSpecSubclassedUser : RKSpecUser
@end
@implementation RKSpecSubclassedUser
@end

@interface RKTableViewCellMappingsSpec : RKSpec <RKSpecUI>

@end

@implementation RKTableViewCellMappingsSpec

- (void)itShouldRaiseAnExceptionWhenAnAttemptIsMadeToRegisterAnExistingMappableClass {
    RKTableViewCellMappings* cellMappings = [RKTableViewCellMappings cellMappings];
    RKTableViewCellMapping* firstMapping = [RKTableViewCellMapping cellMapping];
    RKTableViewCellMapping* secondMapping = [RKTableViewCellMapping cellMapping];
    [cellMappings setCellMapping:firstMapping forClass:[RKSpecUser class]];
    NSException* exception = nil;
    @try {
        [cellMappings setCellMapping:secondMapping forClass:[RKSpecUser class]];
    }
    @catch (NSException *e) {
        exception = e;
    }
    @finally {
        assertThat(exception, is(notNilValue()));
    }
}

- (void)itShouldFindCellMappingsWithAnExactClassMatch {
    RKTableViewCellMappings* cellMappings = [RKTableViewCellMappings cellMappings];
    RKTableViewCellMapping* firstMapping = [RKTableViewCellMapping cellMapping];
    RKTableViewCellMapping* secondMapping = [RKTableViewCellMapping cellMapping];
    [cellMappings setCellMapping:firstMapping forClass:[RKSpecSubclassedUser class]];
    [cellMappings setCellMapping:secondMapping forClass:[RKSpecUser class]];
    assertThat([cellMappings cellMappingForObject:[RKSpecUser new]], is(equalTo(secondMapping)));
}

- (void)itShouldFindCellMappingsWithASubclassMatch {
    RKTableViewCellMappings* cellMappings = [RKTableViewCellMappings cellMappings];
    RKTableViewCellMapping* firstMapping = [RKTableViewCellMapping cellMapping];
    RKTableViewCellMapping* secondMapping = [RKTableViewCellMapping cellMapping];
    [cellMappings setCellMapping:firstMapping forClass:[RKSpecUser class]];
    [cellMappings setCellMapping:secondMapping forClass:[RKSpecSubclassedUser class]];    
    assertThat([cellMappings cellMappingForObject:[RKSpecSubclassedUser new]], is(equalTo(secondMapping)));
}

- (void)itShouldReturnTheCellMappingForAnObjectInstance {
    RKTableViewCellMappings* cellMappings = [RKTableViewCellMappings cellMappings];
    RKTableViewCellMapping* mapping = [RKTableViewCellMapping cellMapping];
    [cellMappings setCellMapping:mapping forClass:[RKSpecUser class]];
    assertThat([cellMappings cellMappingForObject:[RKSpecUser new]], is(equalTo(mapping)));
}

@end
