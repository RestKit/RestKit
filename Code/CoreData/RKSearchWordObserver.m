//
//  RKSearchWordObserver.m
//  RestKit
//
//  Created by Blake Watters on 7/25/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "RKSearchWordObserver.h"
#import "RKSearchableManagedObject.h"
#import "RKLog.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitCoreDataSearchEngine

static RKSearchWordObserver *sharedSearchWordObserver = nil;

@implementation RKSearchWordObserver

+ (RKSearchWordObserver *)sharedObserver
{
    if (! sharedSearchWordObserver) {
        sharedSearchWordObserver = [[RKSearchWordObserver alloc] init];
    }

    return sharedSearchWordObserver;
}

- (id)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(managedObjectContextWillSaveNotification:)
                                                     name:NSManagedObjectContextWillSaveNotification
                                                   object:nil];
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)managedObjectContextWillSaveNotification:(NSNotification *)notification
{
    NSManagedObjectContext *context = [notification object];
    NSSet *candidateObjects = [[NSSet setWithSet:context.insertedObjects] setByAddingObjectsFromSet:context.updatedObjects];

    RKLogDebug(@"Managed object context will save notification received. Checking changed and inserted objects for searchable entities...");

    for (NSManagedObject *object in candidateObjects) {
        if (! [object isKindOfClass:[RKSearchableManagedObject class]]) {
            RKLogTrace(@"Skipping search words refresh for entity of type '%@': not searchable.", NSStringFromClass([object class]));
            continue;
        }

        NSArray *searchableAttributes = [[object class] searchableAttributes];
        for (NSString *attribute in searchableAttributes) {
            if ([[object changedValues] objectForKey:attribute]) {
                RKLogDebug(@"Detected change to searchable attribute '%@' for %@ entity: refreshing search words.", attribute, NSStringFromClass([object class]));
                [(RKSearchableManagedObject *)object refreshSearchWords];
                break;
            }
        }
    }
}

@end
