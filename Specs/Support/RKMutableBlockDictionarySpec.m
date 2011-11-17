//
//  RKMutableBlockDictionarySpec.m
//  RestKit
//
//  Created by Blake Watters on 8/22/11.
//  Copyright (c) 2011 RestKit. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKMutableBlockDictionary.h"

@interface RKMutableBlockDictionarySpec : RKSpec

@end

@implementation RKMutableBlockDictionarySpec

- (void)itShouldLetYouAssignABlockToTheDictionary {    
    RKMutableBlockDictionary* blockDictionary = [[RKMutableBlockDictionary new] autorelease];
    [blockDictionary setValueWithBlock:^id{ return @"Value from the block!"; } forKey:@"theKey"];
    assertThat([blockDictionary valueForKey:@"theKey"], is(equalTo(@"Value from the block!")));
}

- (void)itShouldLetYouUseKVC {
    RKMutableBlockDictionary* blockDictionary = [[RKMutableBlockDictionary new] autorelease];
    [blockDictionary setValue:@"a value" forKey:@"a key"];
    assertThat([blockDictionary valueForKey:@"a key"], is(equalTo(@"a value")));
}

- (void)itShouldLetYouAccessABlockValueUsingAKeyPath {
    RKMutableBlockDictionary* blockDictionary = [[RKMutableBlockDictionary new] autorelease];
    [blockDictionary setValueWithBlock:^id{ return @"Value from the block!"; } forKey:@"theKey"];
    NSDictionary* otherDictionary = [NSDictionary dictionaryWithObject:blockDictionary forKey:@"dictionary"];
    assertThat([otherDictionary valueForKeyPath:@"dictionary.theKey"], is(equalTo(@"Value from the block!")));
}

@end
