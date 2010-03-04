//
//  RKModelSeeder.h
//  RestKit
//
//  Created by Blake Watters on 3/4/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKModelManager.h"

@interface RKModelSeeder : NSObject {
	RKModelManager* _manager;
}

/**
 * Initialize a new model seeder
 */
- (id)initWithModelManager:(RKModelManager*)manager;

/**
 * Read a file from the main bundle and seed the database with its contents.
 * Returns the array of model objects built from the file.
 */
- (NSArray*)seedDatabaseWithBundledFile:(NSString*)fileName ofType:(NSString*)type;

- (void)seedDatabaseWithBundledFiles:(NSArray*)fileNames ofType:(NSString*)type;

@end
