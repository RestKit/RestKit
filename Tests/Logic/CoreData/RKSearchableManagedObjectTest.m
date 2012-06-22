//
//  RKSearchableManagedObjectTest.m
//  RestKit
//
//  Created by Blake Watters on 7/26/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "NSManagedObject+ActiveRecord.h"
#import "RKSearchable.h"

@interface RKSearchableManagedObjectTest : RKTestCase

@end

@implementation RKSearchableManagedObjectTest

- (void)testGenerateSearchWordsForSearchableObjects
{
    [RKTestFactory managedObjectStore];
    RKSearchable *searchable = [RKSearchable createEntity];
    searchable.title = @"This is the title of my new object";
    searchable.body = @"This is the point at which I begin pontificating at length about various and sundry things for no real reason at all. Furthermore, ...";
    assertThat(searchable.searchWords, is(empty()));
    [searchable refreshSearchWords];
    assertThat(searchable.searchWords, isNot(empty()));
    NSArray *words = [[[searchable.searchWords valueForKey:@"word"] allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    assertThat([words componentsJoinedByString:@", "], is(equalTo(@"about, all, and, at, begin, for, furthermore, i, is, length, my, new, no, object, of, point, pontificating, real, reason, sundry, the, things, this, title, various, which")));
}

@end
