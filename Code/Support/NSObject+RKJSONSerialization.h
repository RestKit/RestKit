//
//  NSObject+RKJSONSerialization.h
//  RestKit
//
//  Created by Blake Watters on 7/8/10.
//
//

#import "RKJSONSerialization.h"

@interface NSObject (RKJSONSerialization)

/**
 * Returns a JSON serialization representation of an object suitable
 * for submission to remote web services. This is provided as a convenience
 */
- (RKJSONSerialization*)JSONSerialization;

@end
