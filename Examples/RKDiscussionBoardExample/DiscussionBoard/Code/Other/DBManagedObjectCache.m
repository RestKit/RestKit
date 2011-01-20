//
//  DBManagedObjectCache.m
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/10/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "DBManagedObjectCache.h"
#import "DBTopic.h"
#import "DBPost.h"

@implementation DBManagedObjectCache

- (NSArray*)fetchRequestsForResourcePath:(NSString*)resourcePath {
	if ([resourcePath isEqualToString:@"/topics"]) {
		NSFetchRequest* request = [DBTopic fetchRequest];
		NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES];
		[request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
		return [NSArray arrayWithObject:request];
	}
	
	// match on /topics/:id/posts
	NSArray* components = [resourcePath componentsSeparatedByString:@"/"];
	if ([components count] == 4 &&
		[[components objectAtIndex:1] isEqualToString:@"topics"] &&
		[[components objectAtIndex:3] isEqualToString:@"posts"]) {
		NSString* topicIDString = [components objectAtIndex:2];
		NSNumber* topicID = [NSNumber numberWithInt:[topicIDString intValue]];
		NSFetchRequest* request = [DBPost fetchRequest];
		NSPredicate* predicate = [NSPredicate predicateWithFormat:@"topicID = %@", topicID, nil];
		[request setPredicate:predicate];
		NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES];
		[request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
		return [NSArray arrayWithObject:request];
	}

	return nil;
}

@end
