//
//  RKParentConnectionOperation.m
//  Pods
//
//  Created by Andrew Morrow on 7/2/13.
//
//

#import "RKParentConnectionOperation.h"
#import "RKLog.h"

@interface RKParentConnectionOperation ()
@property (nonatomic, strong, readwrite) NSManagedObject *managedObject;
@property (nonatomic, strong, readwrite) NSManagedObject *parentObject;
@property (nonatomic, strong, readwrite) NSString *relationshipName;
@end

@implementation RKParentConnectionOperation

- (id)initWithManagedObject:(NSManagedObject *)managedObject parentObject:(NSManagedObject *)parentObject relationship:(NSString *)relationshipName
{
    self = [super init];
    if (self) {
        self.managedObject = managedObject;
        self.parentObject = parentObject;
        self.relationshipName = relationshipName;
    }
    return self;
}

- (void)main
{
    if (self.isCancelled || self.managedObject.isDeleted || self.parentObject.isDeleted) return;
    NSEntityDescription *parentDescription = self.parentObject.entity;
    NSRelationshipDescription *relationshipDescription = [[parentDescription relationshipsByName] objectForKey:self.relationshipName];
    [self.managedObject.managedObjectContext performBlockAndWait:^{
        if (self.isCancelled || self.managedObject.isDeleted || self.parentObject.isDeleted) return;
        @try {
            if (relationshipDescription.isToMany) {
                NSString *firstLetter = [self.relationshipName substringWithRange:NSMakeRange(0, 1)];
                firstLetter = [firstLetter uppercaseString];
                NSString *restOfName = [self.relationshipName substringWithRange:NSMakeRange(1, self.relationshipName.length-1)];
                NSString *selectorName = [NSString stringWithFormat:@"add%@%@Object:", firstLetter, restOfName];
                SEL addSelector = NSSelectorFromString(selectorName);
                if (![self.parentObject respondsToSelector:addSelector]) {
                    RKLogDebug(@"Parent object %@ does not respond to expected selector %@ when attemping to connection child object %@ for relationship named %@.", self.parentObject, selectorName, self.managedObject, self.relationshipName);
                    return;
                }
                // We are not worried about memory management in this call.
                // The addXObject: methods which CoreData generates return nothing.
                // This means there is nothing to leak.
                // Thus we can safely disable that warning for this call only.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [self.parentObject performSelector:addSelector withObject:self.managedObject];
#pragma clang diagnostic pop
            } else {
                [self.parentObject setValue:self.managedObject forKey:self.relationshipName];
            }
        }
        @catch (NSException *exception) {
            if ([[exception name] isEqualToString:NSObjectInaccessibleException]) {
                RKLogDebug(@"Rescued an `NSObjectInaccessibleException` exception while attempting to establish a relationship.");
            } else {
                [exception raise];
            }
        }
    }];
}

@end
