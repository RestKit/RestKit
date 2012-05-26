//
//  OrderedDictionary.h
//  OrderedDictionary
//
//  Created by Matt Gallagher on 19/12/08.
//  Copyright 2008 Matt Gallagher. All rights reserved.
//
//  This software is provided 'as-is', without any express or implied
//  warranty. In no event will the authors be held liable for any damages
//  arising from the use of this software. Permission is granted to anyone to
//  use this software for any purpose, including commercial applications, and to
//  alter it and redistribute it freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//     claim that you wrote the original software. If you use this software
//     in a product, an acknowledgment in the product documentation would be
//     appreciated but is not required.
//  2. Altered source versions must be plainly marked as such, and must not be
//     misrepresented as being the original software.
//  3. This notice may not be removed or altered from any source
//     distribution.
//

#import <Foundation/Foundation.h>

/**
 The RKOrderedDictionary class declares the programmatic interface to objects that manage mutable
 associations of keys and values wherein the keys have a specific order. It adds ordered key modification
 operations to the basic operations it inherits from NSMutableDictionary.
 */
// Borrowed from Matt Gallagher - http://cocoawithlove.com/2008/12/ordereddictionary-subclassing-cocoa.html
@interface RKOrderedDictionary : NSMutableDictionary
{
    NSMutableDictionary *dictionary;
    NSMutableArray *array;
}

/**
 Inserts an object into the dictionary for a given key at a specific index.

 @param anObject The object to add the dictionary.
 @param aKey The key to store the value under.
 @param anIndex The index in the dictionary at which to insert aKey.
 */
- (void)insertObject:(id)anObject forKey:(id)aKey atIndex:(NSUInteger)anIndex;

/**
 Returns the key within the dictionary at a given index.

 @param anIndex An index within the bounds of the array keys.
 @return The key that appears at the given index.
 */
- (id)keyAtIndex:(NSUInteger)anIndex;

/**
 Returns an enumerator object that lets you access each key in the dictionary,
 in reverse order.

 @return An enumerator object that lets you access each key in the dictionary
 in reverse order.
 */
- (NSEnumerator *)reverseKeyEnumerator;

@end
