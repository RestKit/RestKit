//
//  RKForm.h
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

#import <UIKit/UIKit.h>
#import "RKControlTableItem.h"

typedef enum {
//    RKFormControlTypeAutodetect, // TODO: Might be nice to support auto-selection of control type
    RKFormControlTypeTextField,
    RKFormControlTypeTextFieldSecure,
    RKFormControlTypeSwitch,
    RKFormControlTypeSlider,
    RKFormControlTypeLabel,
    RKFormControlTypeUnknown    = 1000
} RKFormControlType;

typedef void(^RKFormBlock)();
@class RKTableController;
@class RKFormSection;

@interface RKForm : NSObject {
@private
    NSMutableArray *_sections;
    NSMutableArray *_observedAttributes;
}

/**
 The object we are constructing a form for
 */
@property (nonatomic, readonly) id object;
// The table view we are bound to. not retained.
@property (nonatomic, readonly) RKTableController *tableController;
//@property (nonatomic, assign) id delegate;
@property (nonatomic, copy) RKFormBlock onSubmit;

// delegates...
// formDidSumbit, formWillSubmit, formWillValidate, formDidValidateSuccessfully, formDidFailValidation:withErrors:

+ (id)formForObject:(id)object;
+ (id)formForObject:(id)object usingBlock:(void (^)(RKForm *form))block;
- (id)initWithObject:(id)object;

/** @name Table Item Management */

@property (nonatomic, readonly) NSArray *sections;
@property (nonatomic, readonly) NSArray *tableItems;

- (void)addSection:(RKFormSection *)section;
- (void)addSectionUsingBlock:(void (^)(RKFormSection *section))block;

/** @name Single Section Forms */

/**
 Adds a specific table item to the form
 */
- (void)addTableItem:(RKTableItem *)tableItem; // TODO: maybe addRowWithTableItem???

/** @name Key Path to Control Mapping */

// TODO: All of these method signatures should be carefully evaluated...
// TODO: Consider renaming to addControlForAttribute: | addControlTableItemForAttribute:
- (void)addRowForAttribute:(NSString *)attributeKeyPath withControlType:(RKFormControlType)controlType;
- (void)addRowForAttribute:(NSString *)attributeKeyPath withControlType:(RKFormControlType)controlType usingBlock:(void (^)(RKControlTableItem *tableItem))block;

- (void)addRowMappingAttribute:(NSString *)attributeKeyPath toKeyPath:(NSString *)controlKeyPath onControl:(UIControl *)control;
- (void)addRowMappingAttribute:(NSString *)attributeKeyPath toKeyPath:(NSString *)controlKeyPath onControl:(UIControl *)control usingBlock:(void (^)(RKControlTableItem *tableItem))block;

// TODO: Should there be a flavor that accepts UIView *and yields an RKTableItem? This would avoid needing to cast to (UIControl *)

- (void)addRowMappingAttribute:(NSString *)attributeKeyPath toKeyPath:(NSString *)cellKeyPath onCellWithClass:(Class)cellClass;
- (void)addRowMappingAttribute:(NSString *)attributeKeyPath toKeyPath:(NSString *)cellKeyPath onCellWithClass:(Class)cellClass usingBlock:(void (^)(RKTableItem *tableItem))block;

- (RKTableItem *)tableItemForAttribute:(NSString *)attributeKeyPath;
- (RKControlTableItem *)controlTableItemForAttribute:(NSString *)attributeKeyPath;
- (UIControl *)controlForAttribute:(NSString *)attributeKeyPath;

/** @name Actions */

// serializes the values back out of the form and into the object...
- (BOOL)commitValuesToObject; // TODO: Better method signature??? mapFormToObject..

/**
 Submits the form b
 */
- (void)submit;

/**
 Validates the object state as represented in the form. Returns
 YES if the object is state if valid.
 */
// TODO: Implement me...
//- (BOOL)validate:(NSArray**)errors;

- (void)willLoadInTableController:(RKTableController *)tableController;
- (void)didLoadInTableController:(RKTableController *)tableController;

// Sent from the form section
- (void)formSection:(RKFormSection *)formSection didAddTableItem:(RKTableItem *)tableItem forAttributeAtKeyPath:(NSString *)attributeKeyPath;

@end
