//
//  RKFormTest.m
//  RestKit
//
//  Created by Blake Watters on 8/29/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKForm.h"
#import "RKMappableObject.h"
#import "RKTableController.h"

@interface UISwitch (ControlValue)
@property (nonatomic, assign) NSNumber *controlValue;
@end

@implementation UISwitch (ControlValue)

- (NSNumber *)controlValue
{
    return [NSNumber numberWithBool:self.isOn];
}

- (void)setControlValue:(NSNumber *)controlValue
{
    self.on = [controlValue boolValue];
}

@end

@interface RKTestTextField : UIControl
@property (nonatomic, retain) NSString *text;
@end

@implementation RKTestTextField

@synthesize text;

@end

///////////////////////////////////////////////////////////////

@interface RKFormSpecTableViewCell : UITableViewCell {
}

@property (nonatomic, retain) NSString *someTextProperty;

@end

@implementation RKFormSpecTableViewCell

@synthesize someTextProperty;

@end

///////////////////////////////////////////////////////////////

@interface RKFormTest : RKTestCase

@end

@implementation RKFormTest

- (void)testCommitValuesBackToTheFormObjectWithBuiltInTypes
{
    RKMappableObject *mappableObject = [[RKMappableObject new] autorelease];
    RKForm *form = [RKForm formForObject:mappableObject usingBlock:^(RKForm *form) {
        [form addRowForAttribute:@"stringTest" withControlType:RKFormControlTypeTextField usingBlock:^(RKControlTableItem *tableItem) {
            tableItem.textField.text = @"testing 123";
        }];
        [form addRowForAttribute:@"numberTest" withControlType:RKFormControlTypeSwitch usingBlock:^(RKControlTableItem *tableItem) {
            tableItem.switchControl.on = YES;
        }];
    }];
    [form commitValuesToObject];
    assertThat(mappableObject.stringTest, is(equalTo(@"testing 123")));
    assertThatBool([mappableObject.numberTest boolValue], is(equalToBool(YES)));
}

- (void)testCommitValuesBackToTheFormObjectFromUserConfiguredControls
{
    RKTestTextField *textField = [[RKTestTextField new] autorelease];
    textField.text = @"testing 123";
    UISwitch *switchControl = [[UISwitch new] autorelease];
    switchControl.on = YES;
    RKMappableObject *mappableObject = [[RKMappableObject new] autorelease];
    RKForm *form = [RKForm formForObject:mappableObject usingBlock:^(RKForm *form) {
        [form addRowMappingAttribute:@"stringTest" toKeyPath:@"text" onControl:textField];
        [form addRowMappingAttribute:@"numberTest" toKeyPath:@"controlValue" onControl:switchControl];
    }];
    [form commitValuesToObject];
    assertThat(mappableObject.stringTest, is(equalTo(@"testing 123")));
    assertThatBool([mappableObject.numberTest boolValue], is(equalToBool(YES)));
}

- (void)testCommitValuesBackToTheFormObjectFromCellKeyPaths
{
    RKMappableObject *mappableObject = [[RKMappableObject new] autorelease];
    RKForm *form = [RKForm formForObject:mappableObject usingBlock:^(RKForm *form) {
        [form addRowMappingAttribute:@"stringTest" toKeyPath:@"someTextProperty" onCellWithClass:[RKFormSpecTableViewCell class]];
    }];

    RKTableItem *tableItem = [form.tableItems lastObject];
    RKFormSpecTableViewCell *cell = [[RKFormSpecTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    cell.someTextProperty = @"testing 123";
    id mockTableController = [OCMockObject niceMockForClass:[RKTableController class]];
    [[[mockTableController expect] andReturn:cell] cellForObject:tableItem];
    [form didLoadInTableController:mockTableController];

    // Create a cell
    // Create a fake table view model
    // stub out returning the cell from the table view model

    [form commitValuesToObject];
    assertThat(mappableObject.stringTest, is(equalTo(@"testing 123")));
}

- (void)testMakeTheTableItemPassKVCInvocationsThroughToTheUnderlyingMappedControlKeyPath
{
    // TODO: Implement me
    // add a control
    // invoke valueForKey: with the control value keyPath on the table item...
}

- (void)testInvokeValueForKeyPathOnTheControlIfControlValueReturnsNil
{
    // TODO: Implement me
    // add a custom control to the form
    // the control value should return nil so that valueForKeyPath is invoked directly
}

@end
