//
//  RKFormSection.m
//  RestKit
//
//  Created by Blake Watters on 8/23/11.
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

#import "RKFormSection.h"

@implementation RKFormSection

@synthesize form = _form;

+ (id)sectionInForm:(RKForm *)form
{
    return [[[self alloc] initWithForm:form] autorelease];
}

- (id)initWithForm:(RKForm *)form
{
    self = [super init];
    if (self) {
        self.form = form;
    }

    return self;
}

- (id)object
{
    return self.form.object;
}

- (void)addTableItem:(RKTableItem *)tableItem
{
    // We assume if you haven't configured any mappings by
    // the time the item is added to the section, you probably want the defaults
    if ([tableItem.cellMapping.attributeMappings count] == 0) {
        [tableItem.cellMapping addDefaultMappings];
    }
    // TODO: WTF? _objects is declared @protected but using _objects here fails to build...
    [(NSMutableArray *)self.objects addObject:tableItem];
}

- (UIControl *)controlWithType:(RKFormControlType)controlType
{
    UIControl *control = nil;
    switch (controlType) {
        case RKFormControlTypeTextField:
        case RKFormControlTypeTextFieldSecure:;
            UITextField *textField = [[[UITextField alloc] init] autorelease];
            textField.secureTextEntry = (controlType == RKFormControlTypeTextFieldSecure);
            control = (UIControl *)textField;
            break;

        case RKFormControlTypeSwitch:;
            control = [(UIControl *)[UISwitch new] autorelease];
            break;

        case RKFormControlTypeSlider:;
            control = [(UIControl *)[UISlider new] autorelease];
            break;

        case RKFormControlTypeLabel:;
            control = [(UIControl *)[UILabel new] autorelease];
            break;

        case RKFormControlTypeUnknown:
        default:
            break;
    }

    control.backgroundColor = [UIColor clearColor];
    return control;
}

- (NSString *)keyPathForControl:(UIControl *)control
{
    if ([control isKindOfClass:[UITextField class]] ||
        [control isKindOfClass:[UILabel class]]) {
        return @"text";
    } else if ([control isKindOfClass:[UISwitch class]]) {
        return @"on";
    } else if ([control isKindOfClass:[UISlider class]]) {
        return @"value";
    } else {
        [NSException raise:NSInvalidArgumentException format:@"*** -[%@ %@]: unable to define mapping for control type %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromClass([control class])];
    }

    return nil;
}

- (void)addAttributeMapping:(RKObjectAttributeMapping *)attributeMapping forKeyPath:(NSString *)attributeKeyPath toTableItem:(RKTableItem *)tableItem
{
    [tableItem.cellMapping addAttributeMapping:attributeMapping];

    // Use KVC storage to associate the table item with object being mapped
    // TODO: Move these to constants...
    [tableItem.userData setValue:self.object forKey:@"__RestKit__object"];
    [tableItem.userData setValue:attributeKeyPath forKey:@"__RestKit__attributeKeyPath"];
    [tableItem.userData setValue:attributeMapping forKey:@"__RestKit__attributeToControlMapping"];

    [self.form formSection:self didAddTableItem:tableItem forAttributeAtKeyPath:attributeKeyPath];
    [self addTableItem:tableItem];
}

- (void)addRowMappingAttribute:(NSString *)attributeKeyPath toKeyPath:(NSString *)controlKeyPath onControl:(UIControl *)control usingBlock:(void (^)(RKControlTableItem *tableItem))block
{
    RKControlTableItem *tableItem = [RKControlTableItem tableItemWithControl:control];
    RKObjectAttributeMapping *attributeMapping = [[RKObjectAttributeMapping new] autorelease];
    attributeMapping.sourceKeyPath = [NSString stringWithFormat:@"userData.__RestKit__object.%@", attributeKeyPath];
    attributeMapping.destinationKeyPath = [NSString stringWithFormat:@"control.%@", controlKeyPath];

    [self addAttributeMapping:attributeMapping forKeyPath:attributeKeyPath toTableItem:tableItem];
    if (block) block(tableItem);
}

- (void)addRowMappingAttribute:(NSString *)attributeKeyPath toKeyPath:(NSString *)controlKeyPath onControl:(UIControl *)control
{
    [self addRowMappingAttribute:attributeKeyPath toKeyPath:controlKeyPath onControl:control usingBlock:nil];
}

- (void)addRowForAttribute:(NSString *)attributeKeyPath withControlType:(RKFormControlType)controlType usingBlock:(void (^)(RKControlTableItem *tableItem))block
{
    id control = [self controlWithType:controlType];
    NSString *controlKeyPath = [self keyPathForControl:control];
    [self addRowMappingAttribute:attributeKeyPath toKeyPath:controlKeyPath onControl:control usingBlock:block];
}

- (void)addRowForAttribute:(NSString *)attributeKeyPath withControlType:(RKFormControlType)controlType
{
    [self addRowForAttribute:attributeKeyPath withControlType:controlType usingBlock:nil];
}

- (void)addRowMappingAttribute:(NSString *)attributeKeyPath toKeyPath:(NSString *)cellKeyPath onCellWithClass:(Class)cellClass usingBlock:(void (^)(RKTableItem *tableItem))block
{
    RKTableItem *tableItem = [RKTableItem tableItem];
    tableItem.cellMapping.cellClass = cellClass;
    RKObjectAttributeMapping *attributeMapping = [[RKObjectAttributeMapping new] autorelease];
    attributeMapping.sourceKeyPath = [NSString stringWithFormat:@"userData.__RestKit__object.%@", attributeKeyPath];
    attributeMapping.destinationKeyPath = cellKeyPath;

    [self addAttributeMapping:attributeMapping forKeyPath:attributeKeyPath toTableItem:tableItem];
    if (block) block(tableItem);
}

- (void)addRowMappingAttribute:(NSString *)attributeKeyPath toKeyPath:(NSString *)cellKeyPath onCellWithClass:(Class)cellClass
{
    [self addRowMappingAttribute:attributeKeyPath toKeyPath:cellKeyPath onCellWithClass:cellClass usingBlock:nil];
}

@end
