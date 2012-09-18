//
//  RKDictionaryUtilitiesTest.m
//  RestKit
//
//  Created by Jawwad Ahmad on 9/18/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
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


#import "RKTestEnvironment.h"
#import "RKDictionaryUtilities.h"


@interface RKDictionaryUtilitiesTest : RKTestCase

@end

@implementation RKDictionaryUtilitiesTest

- (void)testMergedDictGetsNewKeyFromSubdict
{
    NSDictionary *dict1 = @{
        @"name" : @{
            @"firstName" : @"Blake"
        }
    };

    NSDictionary *dict2 = @{
        @"name" : @{
            @"lastName" : @"Watters"
        }
    };

    NSDictionary *expectedMergedDict = @{
        @"name" : @{
            @"firstName" : @"Blake",
            @"lastName" : @"Watters"
        }
    };

    NSDictionary *actualMergedDict = RKDictionaryByMergingDictionaryWithDictionary(dict1, dict2);
    assertThat(actualMergedDict, equalTo(expectedMergedDict));
}

- (void)testMergedDictOverwritesOldKeyInSubdict
{
    NSDictionary *dict1 = @{
        @"name" : @{
            @"firstName" : @"Blake",
            @"lastName" : @"Unknown"
        }
    };

    NSDictionary *dict2 = @{
        @"name" : @{
            @"lastName" : @"Watters"
        }
    };

    NSDictionary *expectedMergedDict = @{
        @"name" : @{
            @"firstName" : @"Blake",
            @"lastName" : @"Watters"
        }
    };

    NSDictionary *actualMergedDict = RKDictionaryByMergingDictionaryWithDictionary(dict1, dict2);
    assertThat(actualMergedDict, equalTo(expectedMergedDict));
}

- (void)testMergedDictAddsNewDict
{
    NSDictionary *dict1 = @{
        @"name" : @{
            @"firstName" : @"Blake",
        }
    };

    NSDictionary *dict2 = @{
        @"name" : @{
            @"lastName" : @"Watters"
        },
        @"email" : @"blake@restkit.org"
    };

    NSDictionary *expectedMergedDict = @{
        @"name" : @{
            @"firstName" : @"Blake",
            @"lastName" : @"Watters"
        },
        @"email" : @"blake@restkit.org"
    };

    NSDictionary *actualMergedDict = RKDictionaryByMergingDictionaryWithDictionary(dict1, dict2);
    assertThat(actualMergedDict, equalTo(expectedMergedDict));
}

- (void)testMergedDictAddsOverwritesOldNonDictValueWithNewSubDictValue
{
    NSDictionary *dict1 = @{
        @"name" : @{
            @"firstName" : @"Blake",
        },
        @"email" : @"blake@restkit.org"
    };

    NSDictionary *dict2 = @{
        @"name" : @{
            @"lastName" : @"Watters"
        },
        @"email" : @{
            @"RestKit" : @"blake@restkit.org",
            @"Other"   : @"blake@example.com"
        }
    };

    NSDictionary *expectedMergedDict = @{
        @"name" : @{
            @"firstName" : @"Blake",
            @"lastName" : @"Watters"
        },
        @"email" : @{
            @"RestKit" : @"blake@restkit.org",
            @"Other"   : @"blake@example.com"
        }
    };

    NSDictionary *actualMergedDict = RKDictionaryByMergingDictionaryWithDictionary(dict1, dict2);
    assertThat(actualMergedDict, equalTo(expectedMergedDict));
}

- (void)testMergedDictAddsOverwritesOldSubdictValueWithNonDictValue
{
    NSDictionary *dict1 = @{
        @"name" : @{
            @"lastName" : @"Watters"
        },
        @"email" : @{
            @"RestKit" : @"blake@restkit.org",
            @"Other"   : @"blake@example.com"
        }
    };

    NSDictionary *dict2 = @{
        @"name" : @{
            @"firstName" : @"Blake",
        },
        @"email" : @"blake@restkit.org"
    };

    NSDictionary *expectedMergedDict = @{
        @"name" : @{
            @"firstName" : @"Blake",
            @"lastName" : @"Watters"
        },
        @"email" : @"blake@restkit.org",
    };

    NSDictionary *actualMergedDict = RKDictionaryByMergingDictionaryWithDictionary(dict1, dict2);
    assertThat(actualMergedDict, equalTo(expectedMergedDict));
}


@end
