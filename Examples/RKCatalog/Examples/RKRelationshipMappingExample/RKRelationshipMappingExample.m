//
//  RKRelationshipMappingExample.m
//  RKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>
#import "RKRelationshipMappingExample.h"
#import "User.h"
#import "Project.h"
#import "Task.h"

@implementation RKRelationshipMappingExample

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:gRKCatalogBaseURL];
        RKManagedObjectStore *objectStore = [RKManagedObjectStore objectStoreWithStoreFilename:@"RKRelationshipMappingExample.sqlite"];
        objectManager.objectStore = objectStore;

        RKManagedObjectMapping *taskMapping = [RKManagedObjectMapping mappingForClass:[Task class] inManagedObjectStore:objectStore];
        taskMapping.primaryKeyAttribute = @"taskID";
        [taskMapping mapKeyPath:@"id" toAttribute:@"taskID"];
        [taskMapping mapKeyPath:@"name" toAttribute:@"name"];
        [taskMapping mapKeyPath:@"assigned_user_id" toAttribute:@"assignedUserID"];
        [objectManager.mappingProvider setMapping:taskMapping forKeyPath:@"task"];

        RKManagedObjectMapping *userMapping = [RKManagedObjectMapping mappingForClass:[User class] inManagedObjectStore:objectStore];
        userMapping.primaryKeyAttribute = @"userID";
        [userMapping mapAttributes:@"name", @"email", nil];
        [userMapping mapKeyPath:@"id" toAttribute:@"userID"];
        [userMapping mapRelationship:@"tasks" withMapping:taskMapping];
        [objectManager.mappingProvider setMapping:userMapping forKeyPath:@"user"];

        // Hydrate the assignedUser association via primary key
        [taskMapping hasOne:@"assignedUser" withMapping:userMapping];
        [taskMapping connectRelationship:@"assignedUser" withObjectForPrimaryKeyAttribute:@"assignedUserID"];

        // NOTE - Project is not backed by Core Data
        RKObjectMapping *projectMapping = [RKObjectMapping mappingForClass:[Project class]];
        [projectMapping mapKeyPath:@"id" toAttribute:@"projectID"];
        [projectMapping mapAttributes:@"name", @"description", nil];
        [projectMapping mapRelationship:@"user" withMapping:userMapping];
        [projectMapping mapRelationship:@"tasks" withMapping:taskMapping];
        [objectManager.mappingProvider setMapping:projectMapping forKeyPath:@"project"];
    }

    return self;
}

- (void)dealloc
{
    [_objects release];
    [super dealloc];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    self.title = @"Task List";

    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:@"/RKRelationshipMappingExample" delegate:self];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects
{
    _objects = [objects retain];
    [self.tableView reloadData];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"Rats!" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        // Return number of projects
        return [_objects count];
    } else {
        // Return number of tasks in the selected project...
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        if (indexPath) {
            return [[[_objects objectAtIndex:indexPath.row] tasks] count];
        }
    }

    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 150, 100)];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont boldSystemFontOfSize:18];

    if (section == 0) {
        label.text = @"Projects";
    } else if (section == 1) {
        label.text = @"Tasks";
    }

    return [label autorelease];
}

#pragma mark - Table View Selection

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Don't allow selections in the bottom section
    if (indexPath.section == 1) {
        return nil;
    }

    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [_selectedProject release];
    _selectedProject = [[_objects objectAtIndex:indexPath.row] retain];

    [self.tableView reloadData];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }

    if (indexPath.section == 0) {
        Project *project = (Project *)[_objects objectAtIndex:indexPath.row];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.text = project.name;
    } else if (indexPath.section == 1) {
        // NOTE: We refetch the object here because Project is not Core Data backed
        NSManagedObject *objectReference = [_selectedProject.tasks objectAtIndex:indexPath.row];
        Task *task = (Task *)[[RKObjectManager sharedManager].objectStore objectWithID:[objectReference objectID]];
        cell.textLabel.text = [NSString stringWithFormat:@"%@", task.name];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Assigned to: %@", task.assignedUser.name];
    }

    return cell;
}

@end
