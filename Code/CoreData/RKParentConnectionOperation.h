//
//  RKParentConnectionOperation.h
//  Pods
//
//  Created by Andrew Morrow on 7/2/13.
//
//

#import <Foundation/Foundation.h>

@interface RKParentConnectionOperation : NSOperation

- (id)initWithManagedObject:(NSManagedObject*)managedObject
               parentObject:(NSManagedObject*)parentObject
               relationship:(NSString*)relationshipName;

@property (nonatomic, strong, readonly) NSManagedObject *managedObject;
@property (nonatomic, strong, readonly) NSManagedObject *parentObject;
@property (nonatomic, strong, readonly) NSString *relationshipName;

@end
