//
//  RKTableControllerTestDelegate.h
//  RestKit
//
//  Created by Blake Watters on 5/23/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#if TARGET_OS_IPHONE
#import "RKTableController.h"
#import "RKFetchedResultsTableController.h"

@interface RKAbstractTableControllerTestDelegate : NSObject <RKAbstractTableControllerDelegate>

@property (nonatomic, readonly, getter = isCancelled) BOOL cancelled;
@property (nonatomic, assign) NSTimeInterval timeout;
@property (nonatomic, assign) BOOL awaitingResponse;

+ (id)tableControllerDelegate;
- (void)waitForLoad;

@end

@interface RKTableControllerTestDelegate : RKAbstractTableControllerTestDelegate <RKTableControllerDelegate>
@end

@interface RKFetchedResultsTableControllerTestDelegate : RKAbstractTableControllerTestDelegate <RKFetchedResultsTableControllerDelegate>

@end

#endif
