//
//  RKResponseDescriptorTest.m
//  RestKit
//
//  Created by Blake Watters on 10/2/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKTestUser.h"
#import "Kiwi.h"

SPEC_BEGIN(RKResponseDescriptorSpec)

describe(@"init", ^{
    context(@"when given a relative path pattern", ^{
        it(@"raises an exception", ^{
            [[theBlock(^{
                RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
                [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:@"monkeys" keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
            }) should] raiseWithName:NSInternalInconsistencyException reason:@"The given path pattern must be absolute as it will be evaluated against a complete path segment."];
        });
    });
});

describe(@"matchesURL:", ^{
    __block NSURL *baseURL;
    __block RKResponseDescriptor *responseDescriptor;
    
    context(@"when baseURL is nil", ^{
        beforeEach(^{
            baseURL = nil;
        });
        
        context(@"and the path pattern is nil", ^{
            beforeEach(^{
                RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
                responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
                responseDescriptor.baseURL = baseURL;
            });
            
            it(@"returns YES", ^{                
                NSURL *URL = [NSURL URLWithString:@"http://restkit.org/monkeys/1234.json"];
                [[@([responseDescriptor matchesURL:URL]) should] beYes];
            });
        });
        
        context(@"and the path pattern is '/monkeys/:monkeyID\\.json'", ^{
            beforeEach(^{
                RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
                responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:@"/monkeys/:monkeyID\\.json" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
                responseDescriptor.baseURL = baseURL;
            });
            
            context(@"and given a URL in which the path and query string match the path pattern", ^{
                it(@"returns YES", ^{
                    NSURL *URL = [NSURL URLWithString:@"http://restkit.org/monkeys/1234.json"];
                    [[@([responseDescriptor matchesURL:URL]) should] beYes];
                });
            });
            
            context(@"and given a URL in which the path and query string do match the path pattern", ^{
                it(@"returns NO", ^{
                    NSURL *URL = [NSURL URLWithString:@"http://restkit.org/mismatch"];
                    [[@([responseDescriptor matchesURL:URL]) should] beNo];
                });
            });
        });
    });
    
    context(@"when the baseURL is 'http://restkit.org'", ^{
        beforeEach(^{
            baseURL = [NSURL URLWithString:@"http://restkit.org"];
        });
        
        context(@"and the path pattern is nil", ^{
            beforeEach(^{
                RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
                responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
                responseDescriptor.baseURL = baseURL;
            });
            
            context(@"and given the URL 'http://google.com/monkeys/1234.json'", ^{
                it(@"returns NO", ^{
                    NSURL *URL = [NSURL URLWithString:@"http://google.com/monkeys/1234.json"];
                    [[@([responseDescriptor matchesURL:URL]) should] beNo];
                });
            });
            
            context(@"and given the URL 'http://restkit.org/whatever", ^{
                it(@"returns YES", ^{
                    NSURL *URL = [NSURL URLWithString:@"http://restkit.org/whatever"];
                    [[@([responseDescriptor matchesURL:URL]) should] beYes];
                });
            });
        });
        
        context(@"and the path pattern is '/monkeys/:monkeyID\\.json'", ^{
            beforeEach(^{                
                RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
                responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:@"/monkeys/:monkeyID\\.json" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
                responseDescriptor.baseURL = baseURL;
            });
            
            context(@"and given a URL with a different baseURL", ^{
                it(@"returns NO", ^{
                    NSURL *otherBaseURL = [NSURL URLWithString:@"http://google.com"];
                    NSURL *URL = [NSURL URLWithString:@"/monkeys/1234.json" relativeToURL:otherBaseURL];
                    [[@([responseDescriptor matchesURL:URL]) should] beNo];
                });
            });
            
            context(@"and given a URL with a matching baseURL", ^{
                context(@"in which the path and query string match the path pattern", ^{
                    it(@"returns YES", ^{
                        NSURL *URL = [NSURL URLWithString:@"/monkeys/1234.json" relativeToURL:baseURL];
                        [[@([responseDescriptor matchesURL:URL]) should] beYes];
                    });
                });
                
                context(@"in which the path and query string do match the path pattern", ^{
                    it(@"returns NO", ^{
                        NSURL *URL = [NSURL URLWithString:@"/mismatch" relativeToURL:baseURL];
                        [[@([responseDescriptor matchesURL:URL]) should] beNo];
                    });
                });
                
                context(@"and the URL includes a query string", ^{
                    it(@"returns NO", ^{
                        NSURL *URL = [NSURL URLWithString:@"/monkeys/1234.json?param1=val1&param2=val2" relativeToURL:baseURL];
                        [[@([responseDescriptor matchesURL:URL]) should] beYes];
                    });
                });
            });
        });
    });
    
    context(@"when the baseURL is 'http://0.0.0.0:5000", ^{
        beforeEach(^{
            baseURL = [NSURL URLWithString:@"http://0.0.0.0:5000"];
        });
        
        context(@"and the path pattern is '/api/v1/organizations'", ^{
            beforeEach(^{
                RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
                responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:@"/api/v1/organizations" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
                responseDescriptor.baseURL = baseURL;
            });
            
            context(@"and given the URL 'http://0.0.0.0:5000/api/v1/organizations/?client_search=t'", ^{
                it(@"returns YES", ^{
                    NSURL *URL = [NSURL URLWithString:@"http://0.0.0.0:5000/api/v1/organizations/?client_search=t"];
                    [[@([responseDescriptor matchesURL:URL]) should] beYes];
                });
            });
        });
    });

    context(@"when the baseURL is 'http://restkit.org/api/v1/'", ^{
        beforeEach(^{
            baseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/"];            
        });
        
        context(@"and the path pattern is nil", ^{
            beforeEach(^{
                RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
                responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
                responseDescriptor.baseURL = baseURL;
            });
            
            context(@"and given the URL 'http://google.com/monkeys/api/v1/1234.json'", ^{
                it(@"returns NO", ^{
                    NSURL *URL = [NSURL URLWithString:@"http://restkit.org/monkeys/1234.json"];
                    [[@([responseDescriptor matchesURL:URL]) should] beNo];
                });
            });
            
            context(@"and given the URL 'http://restkit.org/api/v1/whatever", ^{
                it(@"returns YES", ^{
                    NSURL *URL = [NSURL URLWithString:@"http://restkit.org/api/v1/whatever"];
                    [[@([responseDescriptor matchesURL:URL]) should] beYes];
                });
            });
        });
        
        context(@"and the path pattern is not nil", ^{
            context(@"and given a URL with a different baseURL", ^{
                it(@"returns NO", ^{
                    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
                    responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:@"/whatever" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
                    responseDescriptor.baseURL = baseURL;
                    
                    NSURL *otherBaseURL = [NSURL URLWithString:@"http://google.com"];
                    NSURL *URL = [NSURL URLWithString:@"monkeys/1234.json" relativeToURL:otherBaseURL];
                    [[@([responseDescriptor matchesURL:URL]) should] beNo];
                });
            });
            
            context(@"and given a URL relative to the base URL", ^{
                context(@"and the path pattern is '/monkeys/:monkeyID\\.json'", ^{
                    beforeEach(^{
                        RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
                        responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:@"/monkeys/:monkeyID\\.json" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
                        responseDescriptor.baseURL = baseURL;
                    });
                    
                    context(@"and given a relative URL object", ^{
                        context(@"in which the path and query string match the path pattern", ^{
                            it(@"returns YES", ^{
                                NSURL *URL = [NSURL URLWithString:@"monkeys/1234.json" relativeToURL:baseURL];
                                [[@([responseDescriptor matchesURL:URL]) should] beYes];
                            });
                        });
                        
                        context(@"in which the path and query string do match the path pattern", ^{
                            it(@"returns NO", ^{
                                NSURL *URL = [NSURL URLWithString:@"mismatch" relativeToURL:baseURL];
                                [[@([responseDescriptor matchesURL:URL]) should] beNo];
                            });
                        });
                    });
                    
                    context(@"and given a URL with a baseURL that is a substring of the response descriptor's baseURL", ^{
                        context(@"in which the path and query string match the path pattern", ^{
                            it(@"returns YES", ^{
                                NSURL *URL = [NSURL URLWithString:@"http://restkit.org/api/v1/monkeys/1234.json"];
                                [[@([responseDescriptor matchesURL:URL]) should] beYes];
                            });
                        });
                        
                        context(@"in which the path and query string do match the path pattern", ^{
                            it(@"returns NO", ^{
                                NSURL *URL = [NSURL URLWithString:@"http://restkit.org/api/v1/mismatch"];
                                [[@([responseDescriptor matchesURL:URL]) should] beNo];
                            });
                        });
                    });
                });
            });
        });
    });
});

describe(@"matchesResponse:", ^{
    __block RKResponseDescriptor *responseDescriptor;
    
    context(@"when the baseURL is 'http://0.0.0.0:5000", ^{
        context(@"and the path pattern is '/api/v1/organizations'", ^{
            context(@"and given the URL 'http://0.0.0.0:5000/api/v1/organizations/?client_search=t'", ^{
                beforeEach(^{
                    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
                    responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:@"/api/v1/organizations" keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
                    responseDescriptor.baseURL = [NSURL URLWithString:@"http://0.0.0.0:5000"];
                });
                
                it(@"returns YES", ^{
                    NSURL *URL = [NSURL URLWithString:@"http://0.0.0.0:5000/api/v1/organizations/?client_search=t"];
                    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:200 HTTPVersion:@"1.1" headerFields:nil];
                    [[@([responseDescriptor matchesResponse:response]) should] beYes];
                });
            });
        });
    });
});

SPEC_END
