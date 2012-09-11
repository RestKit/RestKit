//
//  RKDictionaryUtilities.h
//  RestKit
//
//  Created by Blake Watters on 9/11/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Reverse merges two dictionary to produce a new dictionary wherein the keys in the second dictionary have taken precedence in instances where keys overlap. The merge is performed recursively such that subdictionaries are reverse merged as well.
 
 @param dictionary The dictionary to be reverse merged.
 @param anotherDictionary A secondary dictionary to perform the reverse merging with.
 @return A new `NSDicionary` object that is the product of the reverse merge.
 */
NSDictionary *RKDictionaryByReverseMergingDictionaryWithDictionary(NSDictionary *dictionary, NSDictionary *anotherDictionary);

/**
 Return a new dictionary by stripping out any percent escapes (such as %20) from the given dictionary's key and values.
 
 @param dictionary The dictionary from which to remove the percent escape sequences.
 @return A new `NSDictionary` wherein any percent escape sequences in the key and values have been replaced with their literal values.
 */
NSDictionary *RKDictionaryByReplacingPercentEscapesInEntriesFromDictionary(NSDictionary *dictionary);
