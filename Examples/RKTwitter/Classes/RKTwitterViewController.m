//
//  RKTwitterViewController.m
//  RKTwitter
//
//  Created by Blake Watters on 9/5/10.
//  Copyright Two Toasters 2010. All rights reserved.
//

#import "RKTwitterViewController.h"
#import "RKTStatus.h"

@implementation RKTwitterViewController

@synthesize statuses = _statuses;

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = @"Two Toasters Tweets";
	
	// Load the object model via RestKit
	RKObjectManager* objectManager = [RKObjectManager globalManager];
	[objectManager loadObjectsAtResourcePath:@"/status/user_timeline/twotoasters.json" objectClass:[RKTStatus class] delegate:self];
}


- (void)dealloc {
	[_statuses release];
    [super dealloc];
}

#pragma mark RKObjectLoaderDelegate methods

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray*)objects {
	// TODO: Update the table appropriately...
	NSLog(@"Loaded statuses: %@", objects);
	self.statuses = objects;
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
	// TODO: Show an error alert
	NSLog(@"Hit error: %@", [error localizedDescription]);
}

#pragma mark UITableViewDelegate methods

#pragma mark UITableViewDataSource methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	return nil;
}

@end
