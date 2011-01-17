//
// Copyright 2009-2010 Facebook
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <Foundation/Foundation.h>

/**
 * Creates a mutable array which does not retain references to the objects it contains.
 *
 * Typically used with arrays of delegates.
 */
NSMutableArray* TTCreateNonRetainingArray();

/**
 * Creates a mutable dictionary which does not retain references to the values it contains.
 *
 * Typically used with dictionaries of delegates.
 */
NSMutableDictionary* TTCreateNonRetainingDictionary();

/**
 * Tests if an object is an array which is not empty.
 */
BOOL TTIsArrayWithItems(id object);

/**
 * Tests if an object is a set which is not empty.
 */
BOOL TTIsSetWithItems(id object);

/**
 * Tests if an object is a string which is not empty.
 */
BOOL TTIsStringWithAnyText(id object);

/**
 * Swap the two method implementations on the given class.
 * Uses method_exchangeImplementations to accomplish this.
 */
void TTSwapMethods(Class cls, SEL originalSel, SEL newSel);
