//
//  RKResponseDescriptorTest.m
//  RestKit
//
//  Created by Kurry Tran on 12/27/13.
//  Copyright (c) 2013 RestKit. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "RKTestEnvironment.h"
#import "RKTestUser.h"
#import "RKParameterConstraint.h"

@interface RKResponseDescriptor ()
NSURL *RKURLByDeletingQuery(NSURL *URL);
@end

@interface RKResponseDescriptorTest : SenTestCase
{
    RKResponseDescriptor *firstDescriptor;
    RKResponseDescriptor *secondDescriptor;
    RKMapping *defaultMapping;
    NSString *defaultPathTemplateString;
    NSString *defaultKeyPath;
    NSIndexSet *defaultStatusCodes;
}
@end

@implementation RKResponseDescriptorTest

- (void)setUp
{
    [super setUp];
    defaultMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    defaultKeyPath = @"";
    defaultPathTemplateString = @"/issues";
    defaultStatusCodes = [NSIndexSet indexSetWithIndex:200];
    firstDescriptor = [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny
                                                       pathTemplateString:defaultPathTemplateString
                                                     parameterConstraints:nil
                                                                  keyPath:defaultKeyPath
                                                              statusCodes:defaultStatusCodes
                                                                  mapping:defaultMapping];
}

#pragma mark = Utilities

- (void)testURLByDeletingQuery
{
    NSURL *URL = [NSURL URLWithString:@"http://localhost:5000/?field1=value1&field2=value2&field3=value3"];
    expect([RKURLByDeletingQuery(URL) absoluteString]).to.equal(@"http://localhost:5000/");
    URL = [NSURL URLWithString:@"http://localhost:5000/path?field1=value1&field2=value2&field3=value3"];
    expect([RKURLByDeletingQuery(URL) absoluteString]).to.equal(@"http://localhost:5000/path");
    URL = [NSURL URLWithString:@"http://localhost/path?field1=value1&field2=value2&field3=value3"];
    expect([RKURLByDeletingQuery(URL) absoluteString]).to.equal(@"http://localhost/path");
    URL = [NSURL URLWithString:@"http://www.localhost.com?field1=value1&field2=value2&field3=value3"];
    expect([RKURLByDeletingQuery(URL) absoluteString]).to.equal(@"http://www.localhost.com");
    URL = [NSURL URLWithString:@"http://localhost:5000/path"];
    expect([RKURLByDeletingQuery(URL) absoluteString]).to.equal(@"http://localhost:5000/path");
}

#pragma mark - URL Matching

- (void)testBaseURLAndPathTemplateIsNilDescriptorMatchesAll
{
    NSURL *baseURL = nil;
    NSURL *URL = [NSURL URLWithString:@"http://restkit.org/monkeys/1234.json"];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny pathTemplateString:nil parameterConstraints:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful) mapping:mapping];
    expect([responseDescriptor matchesURL:URL relativeToBaseURL:baseURL parameters:nil]).to.equal(YES);
}

- (void)testBaseURLIsNilAndPathTemplateAndURLMatch
{
    NSURL *baseURL = nil;
    NSURL *URL = [NSURL URLWithString:@"http://restkit.org/monkeys/1234.json"];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny pathTemplateString:@"/monkeys/{monkeyID}.json" parameterConstraints:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful) mapping:mapping];
    expect([responseDescriptor matchesURL:URL relativeToBaseURL:baseURL parameters:nil]).to.equal(YES);
}

- (void)testBaseURLIsNilAndPathTemplateAndURLMatchReturnsNonEmptyParameters
{
    NSURL *baseURL = nil;
    NSDictionary *parameters;
    NSURL *URL = [NSURL URLWithString:@"http://restkit.org/monkeys/1234.json"];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny pathTemplateString:@"/monkeys/{monkeyID}.json" parameterConstraints:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful) mapping:mapping];
    BOOL matches = [responseDescriptor matchesURL:URL relativeToBaseURL:baseURL parameters:&parameters];
    expect(matches).to.equal(YES);
    expect(parameters).to.equal(@{ @"monkeyID" : @"1234" });
}

- (void)testBaseURLIsNilAndPathTemplateAndURLAreNotMatch
{
    NSURL *baseURL = nil;
    NSURL *URL = [NSURL URLWithString:@"http://restkit.org/mismatch"];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny pathTemplateString:@"/monkeys/{monkeyID}.json" parameterConstraints:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful) mapping:mapping];
    expect([responseDescriptor matchesURL:URL relativeToBaseURL:baseURL parameters:nil]).to.equal(NO);
}

- (void)testBaseURLNotNilAndPathTemplateNilAndGivenURLHostnameDoesNotMatch
{
    NSURL *baseURL = [NSURL URLWithString:@"http://restkit.org"];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny pathTemplateString:nil parameterConstraints:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful) mapping:mapping];
    NSURL *URL = [NSURL URLWithString:@"http://google.com/monkeys/1234.json"];
    expect([responseDescriptor matchesURL:URL relativeToBaseURL:baseURL parameters:nil]).to.equal(NO);
}

- (void)testBaseURLNotNilAndPathTemplateNilAndGivenURLHostnameMatch
{
    NSURL *baseURL = [NSURL URLWithString:@"http://restkit.org"];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny pathTemplateString:nil parameterConstraints:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful) mapping:mapping];
    NSURL *URL = [NSURL URLWithString:@"http://restkit.org/whatever"];
    expect([responseDescriptor matchesURL:URL relativeToBaseURL:baseURL parameters:nil]).to.equal(YES);
}

- (void)testIdenticalPathTemplatesWithDifferentBaseURL
{
    NSURL *baseURL = [NSURL URLWithString:@"http://restkit.org"];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny pathTemplateString:@"/monkeys/{monkeyID}.json" parameterConstraints:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful) mapping:mapping];
    NSURL *otherBaseURL = [NSURL URLWithString:@"http://google.com"];
    NSURL *URL = [NSURL URLWithString:@"/monkeys/1234.json" relativeToURL:otherBaseURL];
    expect([responseDescriptor matchesURL:URL relativeToBaseURL:baseURL parameters:nil]).to.equal(NO);
}

- (void)testIdenticalPathTemplatesWithMatchingBaseURLAndPathAndQueryStringMatchPathTemplate
{
    NSURL *baseURL = [NSURL URLWithString:@"http://restkit.org"];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny pathTemplateString:@"/monkeys/{monkeyID}.json" parameterConstraints:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful) mapping:mapping];
    NSURL *URL = [NSURL URLWithString:@"/monkeys/1234.json" relativeToURL:baseURL];
    expect([responseDescriptor matchesURL:URL relativeToBaseURL:baseURL parameters:nil]).to.equal(YES);
}

- (void)testIdenticalPathTemplatesWithMatchingBaseURLAndPathAndQueryStringDoNotMatchPathTemplate
{
    NSURL *baseURL = [NSURL URLWithString:@"http://restkit.org"];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny pathTemplateString:@"/monkeys/{monkeyID}.json" parameterConstraints:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful) mapping:mapping];
    NSURL *URL = [NSURL URLWithString:@"/mismatch" relativeToURL:baseURL];
    expect([responseDescriptor matchesURL:URL relativeToBaseURL:baseURL parameters:nil]).to.equal(NO);
}

- (void)testIdenticalPathTemplatesWithMatchingBaseURLAndPathIncludesQueryString
{
    NSURL *baseURL = [NSURL URLWithString:@"http://restkit.org"];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny pathTemplateString:@"/monkeys/{monkeyID}.json" parameterConstraints:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful) mapping:mapping];
    NSURL *URL = [NSURL URLWithString:@"/monkeys/1234.json?param1=val1&param2=val2" relativeToURL:baseURL];
    expect([responseDescriptor matchesURL:URL relativeToBaseURL:baseURL parameters:nil]).to.equal(YES);
}

#pragma mark - Response Matching

- (void)testResponseMatchesBaseURLAndPathTemplateAndStatusCode
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny pathTemplateString:@"/api/v1/organizations/" parameterConstraints:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200] mapping:mapping];
    NSURL *URL = [NSURL URLWithString:@"http://0.0.0.0:5000/api/v1/organizations/?client_search=t"];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:200 HTTPVersion:@"1.1" headerFields:nil];
    expect([responseDescriptor matchesResponse:response request:nil relativeToBaseURL:[NSURL URLWithString:@"http://0.0.0.0:5000"] parameters:nil]).to.equal(YES);
}

- (void)testResponseMatchesBaseURLAndPathTemplateAndNonMatchingStatusCode
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny pathTemplateString:@"/api/v1/organizations/" parameterConstraints:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200] mapping:mapping];
    NSURL *URL = [NSURL URLWithString:@"http://0.0.0.0:5000/api/v1/organizations/?client_search=t"];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:500 HTTPVersion:@"1.1" headerFields:nil];
    expect([responseDescriptor matchesResponse:response request:nil relativeToBaseURL:[NSURL URLWithString:@"http://0.0.0.0:5000"] parameters:nil]).to.equal(NO);
}

- (void)testResponseMatchesBaseURLButDoesNotMatchURLPathTemplateAndMatchingStatusCodes
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny pathTemplateString:@"/recommendation/" parameterConstraints:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200] mapping:mapping];
    NSURL *URL = [NSURL URLWithString:@"http://domain.com/domain/api/v1/recommendation/"];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:200 HTTPVersion:@"1.1" headerFields:nil];
    expect([responseDescriptor matchesResponse:response request:nil relativeToBaseURL:[NSURL URLWithString:@"http://domain.com/domain/api/v1/"] parameters:nil]).to.equal(NO);
}

- (void)testResponseMatchesBaseURLButDoesNotMatchURLPathTemplateAndNonMatchingStatusCodes
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny pathTemplateString:@"/recommendation/" parameterConstraints:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200] mapping:mapping];
    NSURL *URL = [NSURL URLWithString:@"http://domain.com/domain/api/v1/recommendation/"];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:500 HTTPVersion:@"1.1" headerFields:nil];
    expect([responseDescriptor matchesResponse:response request:nil relativeToBaseURL:[NSURL URLWithString:@"http://domain.com/domain/api/v1/"] parameters:nil]).to.equal(NO);
}

#pragma mark - isEqual

- (void)testDescriptorsWithSameAttributesAreEqual
{
    secondDescriptor = [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny
                                                        pathTemplateString:defaultPathTemplateString
                                                      parameterConstraints:nil
                                                                   keyPath:defaultKeyPath
                                                               statusCodes:defaultStatusCodes
                                                                   mapping:defaultMapping];
    expect([firstDescriptor isEqual:secondDescriptor]).to.beFalsy();
}

- (void)testDescriptorsWithDifferentMappingsAreNotEqual
{
    RKMapping *mapping = [RKObjectMapping mappingForClass:[NSObject class]];
    secondDescriptor = [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny
                                                        pathTemplateString:defaultPathTemplateString
                                                      parameterConstraints:nil
                                                                   keyPath:defaultKeyPath
                                                               statusCodes:defaultStatusCodes
                                                                   mapping:mapping];
    expect([firstDescriptor isEqual:secondDescriptor]).to.beFalsy();
}

- (void)testDescriptorsWithDifferentPathTemplatesAreNotEqual
{
    secondDescriptor = [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny
                                                        pathTemplateString:@"/pull_requests"
                                                      parameterConstraints:nil
                                                                   keyPath:defaultKeyPath
                                                               statusCodes:defaultStatusCodes
                                                                   mapping:defaultMapping];
    expect([firstDescriptor isEqual:secondDescriptor]).to.beFalsy();
}

- (void)testDescriptorsWithDifferentKeyPathsAreNotEqual
{
    secondDescriptor = [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny
                                                        pathTemplateString:defaultPathTemplateString
                                                      parameterConstraints:nil
                                                                   keyPath:@"pull_request"
                                                               statusCodes:defaultStatusCodes
                                                                   mapping:defaultMapping];
    expect([firstDescriptor isEqual:secondDescriptor]).to.beFalsy();
}

- (void)testDescriptorsWithDifferentStatusCodesAreNotEqual
{
    secondDescriptor = [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny
                                                        pathTemplateString:defaultPathTemplateString
                                                      parameterConstraints:nil
                                                                   keyPath:defaultKeyPath
                                                               statusCodes:[NSIndexSet indexSetWithIndex:404]
                                                                   mapping:defaultMapping];
    expect([firstDescriptor isEqual:secondDescriptor]).to.beFalsy();
}

- (void)testDescriptorsWithDifferentConstraintsAreNotEqual
{
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny
                                                                                  pathTemplateString:defaultPathTemplateString
                                                                              parameterConstraints:[RKParameterConstraint constraintsWithDictionary:@{ @"animals" : @[ @"cats", @"dogs" ] }]
                                                                                             keyPath:defaultKeyPath
                                                                                         statusCodes:[NSIndexSet indexSetWithIndex:404]
                                                                                             mapping:defaultMapping];
    
    secondDescriptor = [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny
                                                        pathTemplateString:defaultPathTemplateString
                                                      parameterConstraints:[RKParameterConstraint constraintsWithDictionary:@{ @"animals" : @[ @"cats" ] }]
                                                                   keyPath:defaultKeyPath
                                                               statusCodes:[NSIndexSet indexSetWithIndex:404]
                                                                   mapping:defaultMapping];
    expect([responseDescriptor isEqual:secondDescriptor]).to.beFalsy();
}

#pragma mark - Parameter Constraint Tests

- (void)testDescriptorWithMatchingExactConstraints
{
    NSArray *constraints = @[ [RKParameterConstraint constraintWithParameter:@"monkeyID" value:@"1234"] ];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny pathTemplateString:@"/monkeys/{monkeyID}.json" parameterConstraints:constraints keyPath:nil statusCodes:nil mapping:nil];
    NSURL *URL = [NSURL URLWithString:@"/monkeys/1234.json" relativeToURL:nil];
    expect([responseDescriptor matchesURL:URL relativeToBaseURL:nil parameters:nil]).to.equal(YES);
}

- (void)testDescriptorWithNonMatchingExactConstraints
{
    NSArray *constraints = @[ [RKParameterConstraint constraintWithParameter:@"monkeyID" value:@"5678"] ];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny pathTemplateString:@"/monkeys/{monkeyID}.json" parameterConstraints:constraints keyPath:nil statusCodes:nil mapping:nil];
    NSURL *URL = [NSURL URLWithString:@"/monkeys/1234.json" relativeToURL:nil];
    expect([responseDescriptor matchesURL:URL relativeToBaseURL:nil parameters:nil]).to.equal(NO);
}

- (void)testDescriptorWithMatchingOptionalConstraints
{
    NSArray *constraints = [RKParameterConstraint constraintsWithDictionary:@{ @"animal_name" : @[ @"dog" ], RKOptionalParametersKey : @[ @"animal_name" ] }];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny pathTemplateString:@"/animals/{animal_name}.json" parameterConstraints:constraints keyPath:nil statusCodes:nil mapping:nil];
    NSURL *URL = [NSURL URLWithString:@"/animals/dog.json" relativeToURL:nil];
    expect([responseDescriptor matchesURL:URL relativeToBaseURL:nil parameters:nil]).to.equal(YES);
}

- (void)testDescriptorWithNonMatchingOptionalConstraints
{
    NSArray *constraints = [RKParameterConstraint constraintsWithDictionary:@{ @"animal_name" : @[ @"dog" ], RKOptionalParametersKey : @[ @"animal_name" ] }];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny pathTemplateString:@"/animals/{animal_name}.json" parameterConstraints:constraints keyPath:nil statusCodes:nil mapping:nil];
    NSURL *URL = [NSURL URLWithString:@"/animals/cat.json" relativeToURL:nil];
    expect([responseDescriptor matchesURL:URL relativeToBaseURL:nil parameters:nil]).to.equal(NO);
}

- (void)testDescriptorWithMissingOptionalConstraints
{
    NSArray *constraints = [RKParameterConstraint constraintsWithDictionary:@{ @"postID" : @[ @"1", @"2" ], RKOptionalParametersKey : @[ @"postID" ] }];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny pathTemplateString:@"/posts/{postID}" parameterConstraints:constraints keyPath:nil statusCodes:nil mapping:nil];
    NSURL *URL = [NSURL URLWithString:@"/posts" relativeToURL:nil];
    expect([responseDescriptor matchesURL:URL relativeToBaseURL:nil parameters:nil]).to.equal(YES);
}

- (void)testDescriptorWithMatchingRequiredConstraints
{
    NSArray *constraints = [RKParameterConstraint constraintsWithDictionary:@{ @"postID" : @[ @"1", @"2" ], RKRequiredParametersKey : @[ @"postID" ] }];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny pathTemplateString:@"/posts/{postID}.json" parameterConstraints:constraints keyPath:nil statusCodes:nil mapping:nil];
    NSURL *URL = [NSURL URLWithString:@"/posts/1.json" relativeToURL:nil];
    expect([responseDescriptor matchesURL:URL relativeToBaseURL:nil parameters:nil]).to.equal(YES);
}

- (void)testDescriptorWithNonMatchingRequiredConstraints
{
    NSArray *constraints = [RKParameterConstraint constraintsWithDictionary:@{ @"postID" : @[ @"1", @"2" ], RKRequiredParametersKey : @[ @"postID" ] }];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny pathTemplateString:@"/posts/{postID}.json" parameterConstraints:constraints keyPath:nil statusCodes:nil mapping:nil];
    NSURL *URL = [NSURL URLWithString:@"/posts/9999.json" relativeToURL:nil];
    expect([responseDescriptor matchesURL:URL relativeToBaseURL:nil parameters:nil]).to.equal(NO);
}

- (void)testDescriptorWithMissingRequiredConstraints
{
    NSArray *constraints = [RKParameterConstraint constraintsWithDictionary:@{ @"postID" : @[ @"1", @"2" ], RKRequiredParametersKey : @[ @"postID" ] }];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny pathTemplateString:@"/posts/{postID}.json" parameterConstraints:constraints keyPath:nil statusCodes:nil mapping:nil];
    NSURL *URL = [NSURL URLWithString:@"/posts" relativeToURL:nil];
    expect([responseDescriptor matchesURL:URL relativeToBaseURL:nil parameters:nil]).to.equal(NO);
}

- (void)testDescriptorWithMatchingRegularExpressionConstraints
{
    NSArray *constraints =  @[ [RKParameterConstraint constraintWithParameter:@"monkeyID" value:[NSRegularExpression regularExpressionWithPattern:@"^[0-9]*$" options:0 error:nil]] ];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny pathTemplateString:@"/monkeys/{monkeyID}.json" parameterConstraints:constraints keyPath:nil statusCodes:nil mapping:nil];
    NSURL *URL = [NSURL URLWithString:@"/monkeys/1234.json" relativeToURL:nil];
    expect([responseDescriptor matchesURL:URL relativeToBaseURL:nil parameters:nil]).to.equal(YES);
}

- (void)testDescriptorWithNonMatchingRegularExpressionConstraints
{
    NSArray *constraints = @[ [RKParameterConstraint constraintWithParameter:@"monkeyID" value:[NSRegularExpression regularExpressionWithPattern:@"^[0-9]*$" options:0 error:nil]] ];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny pathTemplateString:@"/monkeys/{monkeyID}.json" parameterConstraints:constraints keyPath:nil statusCodes:nil mapping:nil];
    NSURL *URL = [NSURL URLWithString:@"/monkeys/a1b2c3d4de.json" relativeToURL:nil];
    expect([responseDescriptor matchesURL:URL relativeToBaseURL:nil parameters:nil]).to.equal(NO);
}

@end
