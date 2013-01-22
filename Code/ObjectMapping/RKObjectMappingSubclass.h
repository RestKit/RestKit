//
//  RKObjectMappingSubclass.h
//  RestKit
//
//  Created by Marius Rackwitz on 21.01.13.
//  Copyright (c) 2013 RestKit. All rights reserved.
//

/*
 The extensions to the `RKObjectMapping` class declared in the `ForSubclassEyesOnly` category are to be used by subclasses implementations only. Code that uses `RKObjectMapping` objects must never call these methods.
 */
@interface RKObjectMapping (ForSubclassEyesOnly)

- (void)copyPropertiesFromMapping:(RKObjectMapping *)mapping;

@end
