//
//  NSStringRestKitSpec.m
//  RestKit
//
//  Created by Greg Combs on 9/2/11.
//  Copyright (c) 2011 RestKit. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "NSString+RestKit.h"
#import "RKObjectMapperSpecModel.h"

@interface NSStringRestKitSpec : RKSpec

@end

@implementation NSStringRestKitSpec

- (void)itShouldAppendQueryParameters {
    NSString *resourcePath = @"/controller/objects/";
    NSDictionary *queryParams = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"ascend", @"sortOrder",
                                 @"name", @"groupBy",nil];
    NSString *resultingPath = [resourcePath appendQueryParams:queryParams];
    assertThat(resultingPath, isNot(equalTo(nil)));
    NSString *expectedPath1 = @"/controller/objects/?sortOrder=ascend&groupBy=name";
    NSString *expectedPath2 = @"/controller/objects/?groupBy=name&sortOrder=ascend";
    BOOL isValidPath = ( [resultingPath isEqualToString:expectedPath1] || 
                         [resultingPath isEqualToString:expectedPath2] );
    assertThatBool(isValidPath, is(equalToBool(YES)));
}

- (void)itShouldInterpolateObjects {
    RKObjectMapperSpecModel *person = [[[RKObjectMapperSpecModel alloc] init] autorelease];
    person.name = @"CuddleGuts";
    person.age  = [NSNumber numberWithInt:6];
    NSString *interpolatedPath = [@"/people/:name/:age" interpolateWithObject:person];
    assertThat(interpolatedPath, isNot(equalTo(nil)));
    NSString *expectedPath = @"/people/CuddleGuts/6";
    assertThat(interpolatedPath, is(equalTo(expectedPath)));
}

- (void)itShouldInterpolateObjectsWithDeprecatedParentheses {
    RKObjectMapperSpecModel *person = [[[RKObjectMapperSpecModel alloc] init] autorelease];
    person.name = @"CuddleGuts";
    person.age  = [NSNumber numberWithInt:6];
    NSString *interpolatedPath = [@"/people/(name)/(age)" interpolateWithObject:person];
    assertThat(interpolatedPath, isNot(equalTo(nil)));
    NSString *expectedPath = @"/people/CuddleGuts/6";
    assertThat(interpolatedPath, is(equalTo(expectedPath)));
}

- (void)itShouldParseQueryParameters {
    NSString *resourcePath = @"/controller/objects/?sortOrder=ascend&groupBy=name";
    NSDictionary *queryParams = [resourcePath queryParametersUsingEncoding:NSASCIIStringEncoding];
    NSArray *expectedKeysAndValues = [NSArray arrayWithObjects:@"sortOrder", @"ascend", @"groupBy", @"name", nil];
    assertThat(queryParams, isNot(equalTo(nil)));
    assertThat(queryParams, hasEntries(expectedKeysAndValues, nil));
}

@end
