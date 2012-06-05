//
//  RKKeyValueMappingExample.m
//  RKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <RestKit/RestKit.h>
#import "RKKeyValueMappingExample.h"

/**
 This code is excerpted from the Advanced Tutorial. See Docs/ for explanation
 */
@interface SimpleAccount : NSObject {
    NSNumber *_accountID;
    NSString *_name;
    NSNumber *_balance;
    NSNumber *_transactionsCount;
    NSNumber *_averageTransactionAmount;
    NSArray *_distinctPayees;
}

@property (nonatomic, retain) NSNumber *accountID;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSNumber *balance;
@property (nonatomic, retain) NSNumber *transactionsCount;
@property (nonatomic, retain) NSNumber *averageTransactionAmount;
@property (nonatomic, retain) NSArray *distinctPayees;

@end

@implementation SimpleAccount

@synthesize accountID = _accountID;
@synthesize name = _name;
@synthesize balance = _balance;
@synthesize transactionsCount = _transactionsCount;
@synthesize averageTransactionAmount = _averageTransactionAmount;
@synthesize distinctPayees = _distinctPayees;

@end

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation RKKeyValueMappingExample

@synthesize infoLabel = _infoLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [RKObjectManager managerWithBaseURL:gRKCatalogBaseURL];
    }

    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[SimpleAccount class]];
    [mapping mapKeyPathsToAttributes:
     @"id", @"accountID",
     @"name", @"name",
     @"balance", @"balance",
     @"transactions.@count", @"transactionsCount",
     @"transactions.@avg.amount", @"averageTransactionAmount",
     @"transactions.@distinctUnionOfObjects.payee", @"distinctPayees",
     nil];

    [[RKObjectManager sharedManager].mappingProvider setObjectMapping:mapping forResourcePathPattern:@"/RKKeyValueMappingExample"];
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:@"/RKKeyValueMappingExample" delegate:self];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects
{
    SimpleAccount *account = [objects objectAtIndex:0];

    NSString *info = [NSString stringWithFormat:
                      @"The count is %@\n"
                      @"The average transaction amount is %@\n"
                      @"The distinct list of payees is: %@",
                      [account transactionsCount],
                      [account averageTransactionAmount],
                      [[account distinctPayees] componentsJoinedByString:@", "]];
    _infoLabel.text = info;
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error
{
    _infoLabel.text = [NSString stringWithFormat:@"Error: %@", [error localizedDescription]];
    _infoLabel.textColor = [UIColor redColor];
}

@end
