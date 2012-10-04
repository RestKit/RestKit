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
        
        context(@"and the path pattern is '/monkeys/:monkeyID\\.json'", ^{
            beforeEach(^{
                RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
                responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:@"/monkeys/:monkeyID\\.json" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
                responseDescriptor.baseURL = baseURL;
            });
            
            context(@"and given a URL with a different baseURL", ^{
                it(@"returns NO", ^{
                    NSURL *otherBaseURL = [NSURL URLWithString:@"http://google.com"];
                    NSURL *URL = [NSURL URLWithString:@"monkeys/1234.json" relativeToURL:otherBaseURL];
                    [[@([responseDescriptor matchesURL:URL]) should] beNo];
                });
            });
            
            context(@"and given a URL with a matching baseURL", ^{
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

SPEC_END
