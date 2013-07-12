//
//  RKResponseDescriptorTest.m
//  RestKit
//
//  Created by Blake Watters on 10/2/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKTestUser.h"
#import "Specta.h"

SpecBegin(RKResponseDescriptorSpec)

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
                responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
                responseDescriptor.baseURL = baseURL;
            });
            
            it(@"returns YES", ^{
                NSURL *URL = [NSURL URLWithString:@"http://restkit.org/monkeys/1234.json"];
                expect([responseDescriptor matchesURL:URL]).to.equal(YES);
            });
        });
        
        context(@"and the path pattern is '/monkeys/:monkeyID\\.json'", ^{
            beforeEach(^{
                RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
                responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:@"/monkeys/:monkeyID\\.json" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
                responseDescriptor.baseURL = baseURL;
            });
            
            context(@"and given a URL in which the path and query string match the path pattern", ^{
                it(@"returns YES", ^{
                    NSURL *URL = [NSURL URLWithString:@"http://restkit.org/monkeys/1234.json"];
                    expect([responseDescriptor matchesURL:URL]).to.equal(YES);
                });
            });
            
            context(@"and given a URL in which the path and query string do match the path pattern", ^{
                it(@"returns NO", ^{
                    NSURL *URL = [NSURL URLWithString:@"http://restkit.org/mismatch"];
                    expect([responseDescriptor matchesURL:URL]).to.equal(NO);
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
                responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
                responseDescriptor.baseURL = baseURL;
            });
            
            context(@"and given the URL 'http://google.com/monkeys/1234.json'", ^{
                it(@"returns NO", ^{
                    NSURL *URL = [NSURL URLWithString:@"http://google.com/monkeys/1234.json"];
                    expect([responseDescriptor matchesURL:URL]).to.equal(NO);
                });
            });
            
            context(@"and given the URL 'http://restkit.org/whatever", ^{
                it(@"returns YES", ^{
                    NSURL *URL = [NSURL URLWithString:@"http://restkit.org/whatever"];
                    expect([responseDescriptor matchesURL:URL]).to.equal(YES);
                });
            });
        });
        
        context(@"and the path pattern is '/monkeys/:monkeyID\\.json'", ^{
            beforeEach(^{
                RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
                responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:@"/monkeys/:monkeyID\\.json" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
                responseDescriptor.baseURL = baseURL;
            });
            
            context(@"and given a URL with a different baseURL", ^{
                it(@"returns NO", ^{
                    NSURL *otherBaseURL = [NSURL URLWithString:@"http://google.com"];
                    NSURL *URL = [NSURL URLWithString:@"/monkeys/1234.json" relativeToURL:otherBaseURL];
                    expect([responseDescriptor matchesURL:URL]).to.equal(NO);
                });
            });
            
            context(@"and given a URL with a matching baseURL", ^{
                context(@"in which the path and query string match the path pattern", ^{
                    it(@"returns YES", ^{
                        NSURL *URL = [NSURL URLWithString:@"/monkeys/1234.json" relativeToURL:baseURL];
                        expect([responseDescriptor matchesURL:URL]).to.equal(YES);
                    });
                });
                
                context(@"in which the path and query string do match the path pattern", ^{
                    it(@"returns NO", ^{
                        NSURL *URL = [NSURL URLWithString:@"/mismatch" relativeToURL:baseURL];
                        expect([responseDescriptor matchesURL:URL]).to.equal(NO);
                    });
                });
                
                context(@"and the URL includes a query string", ^{
                    it(@"returns NO", ^{
                        NSURL *URL = [NSURL URLWithString:@"/monkeys/1234.json?param1=val1&param2=val2" relativeToURL:baseURL];
                        expect([responseDescriptor matchesURL:URL]).to.equal(YES);
                    });
                });
            });
        });
    });
    
    context(@"when the baseURL is 'http://0.0.0.0:5000", ^{
        beforeEach(^{
            baseURL = [NSURL URLWithString:@"http://0.0.0.0:5000"];
        });
        
        context(@"and the path pattern is '/api/v1/organizations/'", ^{
            beforeEach(^{
                RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
                responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:@"/api/v1/organizations/" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
                responseDescriptor.baseURL = baseURL;
            });
            
            context(@"and given the URL 'http://0.0.0.0:5000/api/v1/organizations/?client_search=t'", ^{
                it(@"returns YES", ^{
                    NSURL *URL = [NSURL URLWithString:@"http://0.0.0.0:5000/api/v1/organizations/?client_search=t"];
                    expect([responseDescriptor matchesURL:URL]).to.equal(YES);
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
                responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
                responseDescriptor.baseURL = baseURL;
            });
            
            context(@"and given the URL 'http://google.com/monkeys/api/v1/1234.json'", ^{
                it(@"returns NO", ^{
                    NSURL *URL = [NSURL URLWithString:@"http://restkit.org/monkeys/1234.json"];
                    expect([responseDescriptor matchesURL:URL]).to.equal(NO);
                });
            });
            
            context(@"and given the URL 'http://restkit.org/api/v1/whatever", ^{
                it(@"returns YES", ^{
                    NSURL *URL = [NSURL URLWithString:@"http://restkit.org/api/v1/whatever"];
                    expect([responseDescriptor matchesURL:URL]).to.equal(YES);
                });
            });
        });
        
        context(@"and the path pattern is not nil", ^{
            context(@"and given a URL with a different baseURL", ^{
                it(@"returns NO", ^{
                    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
                    responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:@"/whatever" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
                    responseDescriptor.baseURL = baseURL;
                    
                    NSURL *otherBaseURL = [NSURL URLWithString:@"http://google.com"];
                    NSURL *URL = [NSURL URLWithString:@"monkeys/1234.json" relativeToURL:otherBaseURL];
                    expect([responseDescriptor matchesURL:URL]).to.equal(NO);
                });
            });
            
            context(@"and given a URL relative to the base URL", ^{
                context(@"and the path pattern is '/monkeys/:monkeyID\\.json'", ^{
                    beforeEach(^{
                        RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
                        responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:@"monkeys/:monkeyID\\.json" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
                        responseDescriptor.baseURL = baseURL;
                    });
                    
                    context(@"and given a relative URL object", ^{
                        context(@"in which the path and query string match the path pattern", ^{
                            it(@"returns YES", ^{
                                NSURL *URL = [NSURL URLWithString:@"monkeys/1234.json" relativeToURL:baseURL];
                                expect([responseDescriptor matchesURL:URL]).to.equal(YES);
                            });
                        });
                        
                        context(@"in which the path and query string do match the path pattern", ^{
                            it(@"returns NO", ^{
                                NSURL *URL = [NSURL URLWithString:@"mismatch" relativeToURL:baseURL];
                                expect([responseDescriptor matchesURL:URL]).to.equal(NO);
                            });
                        });
                    });
                    
                    context(@"and given a URL with a baseURL that is a substring of the response descriptor's baseURL", ^{
                        context(@"in which the path and query string match the path pattern", ^{
                            it(@"returns YES", ^{
                                NSURL *URL = [NSURL URLWithString:@"http://restkit.org/api/v1/monkeys/1234.json"];
                                expect([responseDescriptor matchesURL:URL]).to.equal(YES);
                            });
                        });
                        
                        context(@"in which the path and query string do match the path pattern", ^{
                            it(@"returns NO", ^{
                                NSURL *URL = [NSURL URLWithString:@"http://restkit.org/api/v1/mismatch"];
                                expect([responseDescriptor matchesURL:URL]).to.equal(NO);
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
        context(@"and the path pattern is '/api/v1/organizations/'", ^{
            context(@"and given the URL 'http://0.0.0.0:5000/api/v1/organizations/?client_search=t'", ^{
                beforeEach(^{
                    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
                    responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:@"/api/v1/organizations/" keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
                    responseDescriptor.baseURL = [NSURL URLWithString:@"http://0.0.0.0:5000"];
                });
                
                it(@"returns YES", ^{
                    NSURL *URL = [NSURL URLWithString:@"http://0.0.0.0:5000/api/v1/organizations/?client_search=t"];
                    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:200 HTTPVersion:@"1.1" headerFields:nil];
                    expect([responseDescriptor matchesResponse:response]).to.equal(YES);
                });
            });
        });
    });
    
    context(@"when the baseURL is 'http://domain.com/domain/api/v1/'", ^{
        context(@"and the path pattern is '/recommendation/'", ^{
            context(@"then given the URL 'http://domain.com/domain/api/v1/recommendation'", ^{
                beforeEach(^{
                    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
                    responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:@"/recommendation/" keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
                    responseDescriptor.baseURL = [NSURL URLWithString:@"http://domain.com/domain/api/v1/"];
                });
                
                it(@"returns NO", ^{
                    NSURL *URL = [NSURL URLWithString:@"http://domain.com/domain/api/v1/recommendation/"];
                    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:200 HTTPVersion:@"1.1" headerFields:nil];
                    expect([responseDescriptor matchesResponse:response]).to.equal(NO);
                });
            });
            
            context(@"then given the URL 'http://domain.com/domain/api/v1/recommendation?action=search&type=whatever'", ^{
                beforeEach(^{
                    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
                    responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:@"/recommendation/" keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
                    responseDescriptor.baseURL = [NSURL URLWithString:@"http://domain.com/domain/api/v1/"];
                });
                
                it(@"returns NO", ^{
                    NSURL *URL = [NSURL URLWithString:@"http://domain.com/domain/api/v1/recommendation?action=search&type=whatever"];
                    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:200 HTTPVersion:@"1.1" headerFields:nil];
                    expect([responseDescriptor matchesResponse:response]).to.equal(NO);
                });
            });
        });
    });
});

describe(@"isEqualToResponseDescriptor:", ^{
    __block RKResponseDescriptor *firstDescriptor;
    __block RKResponseDescriptor *secondDescriptor;
    
    __block RKMapping *defaultMapping;
    __block NSString *defaultPathPattern;
    __block NSString *defaultKeyPath;
    __block NSIndexSet *defaultStatusCodes;
    
    beforeEach(^{
        defaultMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
        defaultKeyPath = @"";
        defaultPathPattern = @"/issues";
        defaultStatusCodes = [NSIndexSet indexSetWithIndex:200];
        firstDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:defaultMapping
                                                                       method:RKRequestMethodAny
                                                                  pathPattern:defaultPathPattern
                                                                      keyPath:defaultKeyPath
                                                                  statusCodes:defaultStatusCodes];
    });
    
    context(@"descriptors are equal", ^{
        it(@"with the same attributes", ^{
            secondDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:defaultMapping
                                                                            method:RKRequestMethodAny
                                                                       pathPattern:defaultPathPattern
                                                                           keyPath:defaultKeyPath
                                                                       statusCodes:defaultStatusCodes];
            expect(firstDescriptor).to.equal(secondDescriptor);
        });
    });
    
    context(@"descriptors are not equal", ^{
        it(@"with different mappings", ^{
            RKMapping *mapping = [RKObjectMapping mappingForClass:[NSObject class]];
            secondDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping
                                                                            method:RKRequestMethodAny
                                                                       pathPattern:defaultPathPattern
                                                                           keyPath:defaultKeyPath
                                                                       statusCodes:defaultStatusCodes];
            expect(firstDescriptor).toNot.equal(secondDescriptor);
        });
        it(@"with different path patterns", ^{
            secondDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:defaultMapping
                                                                            method:RKRequestMethodAny
                                                                       pathPattern:@"/pull_requests"
                                                                           keyPath:defaultKeyPath
                                                                       statusCodes:defaultStatusCodes];
            expect(firstDescriptor).toNot.equal(secondDescriptor);
        });
        it(@"with different key paths", ^{
            secondDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:defaultMapping
                                                                            method:RKRequestMethodAny
                                                                       pathPattern:defaultPathPattern
                                                                           keyPath:@"/pull_request"
                                                                       statusCodes:defaultStatusCodes];
            expect(firstDescriptor).toNot.equal(secondDescriptor);
        });
        it(@"with different status codes", ^{
            secondDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:defaultMapping
                                                                            method:RKRequestMethodAny
                                                                       pathPattern:defaultPathPattern
                                                                           keyPath:defaultKeyPath
                                                                       statusCodes:[NSIndexSet indexSetWithIndex:404]];
            expect(firstDescriptor).toNot.equal(secondDescriptor);
        });
    });
    
});

SpecEnd
