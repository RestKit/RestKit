//
//  RKForm.m
//  RestKit
//
//  Created by Blake Watters on 8/22/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "RKForm.h"
#import "RKFormSection.h"
#import "RKTableViewCellMapping.h"
#import "RKTableController.h"
#import "RKObjectMappingOperation.h"
#import "RKLog.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitUI

@interface RKForm (Private)
- (void)removeObserverForAttributes;
@end

@implementation RKForm

@synthesize tableController = _tableController;
@synthesize object = _object;
@synthesize onSubmit = _onSubmit;

+ (id)formForObject:(id)object
{
    return [[[self alloc] initWithObject:object] autorelease];
}

+ (id)formForObject:(id)object usingBlock:(void (^)(RKForm *))block
{
    id form = [self formForObject:object];
    if (block) block(form);
    return form;
}

- (id)initWithObject:(id)object
{
    if (! object) {
        [NSException raise:NSInvalidArgumentException format:@"%@ - cannot initialize a form with a nil object",
         NSStringFromSelector(_cmd)];
    }

    self = [self init];
    if (self) {
        _object = [object retain];

        if ([_object isKindOfClass:[NSManagedObject class]]) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(reloadObjectOnContextDidSaveNotification:)
                                                         name:NSManagedObjectContextDidSaveNotification
                                                       object:[(NSManagedObject *)_object managedObjectContext]];
        }
    }

    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        _sections = [NSMutableArray new];
        _observedAttributes = [NSMutableArray new];
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeObserverForAttributes];
    _tableController = nil;
    [_object release];
    [_sections release];
    [_observedAttributes release];
    Block_release(_onSubmit);

    [super dealloc];
}

- (void)addSection:(RKFormSection *)section
{
    [_sections addObject:section];
}

- (void)addSectionUsingBlock:(void (^)(RKFormSection *section))block
{
    RKFormSection *section = [RKFormSection sectionInForm:self];
    block(section);
    [self addSection:section];
}

#pragma mark - Table Item Management

- (NSArray *)sections
{
    return [NSArray arrayWithArray:_sections];
}

- (RKFormSection *)returnOrInstantiateFirstSection
{
    if ([_sections count] > 0) {
        return [_sections objectAtIndex:0];
    }

    RKFormSection *section = [RKFormSection sectionInForm:self];
    [self addSection:section];

    return section;
}

- (NSArray *)tableItems
{
    NSMutableArray *tableItems = [NSMutableArray array];
    for (RKFormSection *section in _sections) {
        [tableItems addObjectsFromArray:section.objects];
    }

    return [NSArray arrayWithArray:tableItems];
}

#pragma mark - Proxies for Section 0

- (void)addTableItem:(RKTableItem *)tableItem
{
    [[self returnOrInstantiateFirstSection] addTableItem:tableItem];
}

- (void)addRowForAttribute:(NSString *)attributeKeyPath withControlType:(RKFormControlType)controlType usingBlock:(void (^)(RKControlTableItem *tableItem))block
{
    [[self returnOrInstantiateFirstSection] addRowForAttribute:attributeKeyPath withControlType:controlType usingBlock:block];
}

- (void)addRowForAttribute:(NSString *)attributeKeyPath withControlType:(RKFormControlType)controlType
{
    [self addRowForAttribute:attributeKeyPath withControlType:controlType usingBlock:nil];
}

- (void)addRowMappingAttribute:(NSString *)attributeKeyPath toKeyPath:(NSString *)controlKeyPath onControl:(UIControl *)control usingBlock:(void (^)(RKControlTableItem *tableItem))block
{
    [[self returnOrInstantiateFirstSection] addRowMappingAttribute:attributeKeyPath toKeyPath:controlKeyPath onControl:control usingBlock:block];
}

- (void)addRowMappingAttribute:(NSString *)attributeKeyPath toKeyPath:(NSString *)controlKeyPath onControl:(UIControl *)control
{
    [self addRowMappingAttribute:attributeKeyPath toKeyPath:controlKeyPath onControl:control usingBlock:nil];
}

- (void)addRowMappingAttribute:(NSString *)attributeKeyPath toKeyPath:(NSString *)cellKeyPath onCellWithClass:(Class)cellClass usingBlock:(void (^)(RKTableItem *tableItem))block
{
    [[self returnOrInstantiateFirstSection] addRowMappingAttribute:attributeKeyPath toKeyPath:cellKeyPath onCellWithClass:cellClass usingBlock:block];
}

- (void)addRowMappingAttribute:(NSString *)attributeKeyPath toKeyPath:(NSString *)cellKeyPath onCellWithClass:(Class)cellClass
{
    [self addRowMappingAttribute:attributeKeyPath toKeyPath:cellKeyPath onCellWithClass:cellClass usingBlock:nil];
}

- (RKTableItem *)tableItemForAttribute:(NSString *)attributeKeyPath
{
    for (RKTableItem *tableItem in self.tableItems) {
        if ([[tableItem.userData valueForKey:@"__RestKit__attributeKeyPath"] isEqualToString:attributeKeyPath]) {
            return tableItem;
        }
    }

    return nil;
}

- (RKControlTableItem *)controlTableItemForAttribute:(NSString *)attributeKeyPath
{
    RKTableItem *tableItem = [self tableItemForAttribute:attributeKeyPath];
    return [tableItem isKindOfClass:[RKControlTableItem class]] ? (RKControlTableItem *)tableItem : nil;
}

- (UIControl *)controlForAttribute:(NSString *)attributeKeyPath
{
    RKControlTableItem *tableItem = [self controlTableItemForAttribute:attributeKeyPath];
    return tableItem.control;
}

#pragma mark - Actions

// TODO: This needs thorough unit testing...
/**
 TODO: There is an alternate approach for the implementation here. What we may want to do instead of tracking
 the mapping like this is use KVO on the control and/or table cells that are tracking attributes and maintain an internal
 dictionary of the attribute names -> values currently set on the controls. We would then just fire up the mapping operation
 instead of doing this. It may be cleaner...
 */
- (BOOL)commitValuesToObject
{
    // Serialize the data out of the form
    RKObjectMapping *objectMapping = [RKObjectMapping mappingForClass:[self.object class]];
    NSMutableDictionary *controlValues = [NSMutableDictionary dictionaryWithCapacity:[self.tableItems count]];
    for (RKTableItem *tableItem in self.tableItems) {
        RKObjectAttributeMapping *controlMapping = [tableItem.userData objectForKey:@"__RestKit__attributeToControlMapping"];
        if (controlMapping) {
            id controlValue = nil;
            NSString *attributeKeyPath = attributeKeyPath = [controlMapping.sourceKeyPath stringByReplacingOccurrencesOfString:@"userData.__RestKit__object." withString:@""];
            NSString *controlValueKeyPath = controlMapping.destinationKeyPath;

            // TODO: Another informal protocol. Document me...
            if ([tableItem isKindOfClass:[RKControlTableItem class]]) {
                // Get the value out of the control and store it on the dictionary
                controlValue = [tableItem performSelector:@selector(controlValue)];
                if (! controlValue) {
                    RKLogTrace(@"Unable to directly fetch controlValue from table item. Asking tableItem for valueForKeyPath: %@", controlValueKeyPath);
                    controlValue = [tableItem valueForKeyPath:controlValueKeyPath];
                }
            } else {
                // We are not a control cell, so we need to get the value directly from the table cell
                UITableViewCell *cell = [self.tableController cellForObject:tableItem];
                NSAssert(cell, @"Attempted to serialize value out of nil table cell");
                NSAssert([cell isKindOfClass:[UITableViewCell class]], @"Expected cellForObject to return a UITableViewCell, but got a %@", NSStringFromClass([cell class]));
                RKLogTrace(@"Asking cell %@ for valueForKeyPath:%@", cell, controlValueKeyPath);
                controlValue = [cell valueForKeyPath:controlValueKeyPath];
            }

            RKLogTrace(@"Extracted form value for attribute '%@': %@", attributeKeyPath, controlValue);
            if (controlValue) {
                [controlValues setValue:controlValue forKey:attributeKeyPath];
            }
            [objectMapping mapAttributes:attributeKeyPath, nil];
        } else {
            // TODO: Logging!!
        }
    }

    RKLogTrace(@"Object mapping form state into target object '%@' with values: %@", self.object, controlValues);
    objectMapping.performKeyValueValidation = NO; // TODO: Temporary...
    RKObjectMappingOperation *operation = [RKObjectMappingOperation mappingOperationFromObject:controlValues toObject:self.object withMapping:objectMapping];
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    if (!success) {
        RKLogWarning(@"Serialization to the target object failed with error: %@", error);
    }

    return success;
}

- (void)submit
{
    if ([self commitValuesToObject]) {
        // TODO: Add validations?
        if (self.onSubmit) self.onSubmit();
    } else {
        // TODO: What to do...
    }
}

- (void)validate
{
    // TODO: Implement me at some point...
}

#pragma mark - Subclass Hooks

- (void)willLoadInTableController:(RKTableController *)tableController
{
}

- (void)didLoadInTableController:(RKTableController *)tableController
{
    _tableController = tableController;
}

#pragma mark - Key Value Observing

- (void)addObserverForAttribute:(NSString *)attributeKeyPath
{
    if (! [_observedAttributes containsObject:attributeKeyPath]) {
        [self.object addObserver:self forKeyPath:attributeKeyPath options:NSKeyValueObservingOptionNew context:nil];
        [_observedAttributes addObject:attributeKeyPath];
    }
}

- (void)removeObserverForAttribute:(NSString *)attributeKeyPath
{
    if ([_observedAttributes containsObject:attributeKeyPath]) {
        [self.object removeObserver:self forKeyPath:attributeKeyPath];
        [_observedAttributes removeObject:attributeKeyPath];
    }
}

- (void)removeObserverForAttributes
{
    for (NSString *keyPath in _observedAttributes) { [self.object removeObserver:self forKeyPath:keyPath]; };
    [_observedAttributes removeAllObjects];
}

- (void)formSection:(RKFormSection *)formSection didAddTableItem:(RKTableItem *)tableItem forAttributeAtKeyPath:(NSString *)attributeKeyPath
{
    [self addObserverForAttribute:attributeKeyPath];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSAssert(object == self.object, @"Received unexpected KVO message for object that form is not bound to: %@", object);
    RKLogTrace(@"Received KVO message for keyPath (%@) for object (%@)", keyPath, object);

    // TODO: We should use a notification to tell the table view about the attribute change.
    // I don't like that the form knows about the tableController...
    // TODO: Need to let you configure the row animations...
    RKTableItem *tableItem = [self tableItemForAttribute:keyPath];
    [self.tableController reloadRowForObject:tableItem withRowAnimation:UITableViewRowAnimationFade];
}

- (void)reloadObjectOnContextDidSaveNotification:(NSNotification *)notification
{
    NSManagedObjectContext *context = (NSManagedObjectContext *)notification.object;
    NSSet *deletedObjects = [notification.userInfo objectForKey:NSDeletedObjectsKey];
    NSSet *updatedObjects = [notification.userInfo objectForKey:NSUpdatedObjectsKey];

    if ([deletedObjects containsObject:self.object]) {
        RKLogWarning(@"Object was deleted while being display in a RKForm. Interface may no longer function as expected.");
        [self removeObserverForAttributes];
        [_object release];
        _object = nil;
    } else if ([updatedObjects containsObject:self.object]) {
        RKLogDebug(@"Object was updated while being displayed in a RKForm. Refreshing...");
        [context refreshObject:_object mergeChanges:YES];
    }
}

@end
