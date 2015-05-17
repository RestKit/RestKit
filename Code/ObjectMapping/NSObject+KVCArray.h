//
//  NSObject+KVCArray.h
//  RestKit
//
//  Created by Oli on 17/05/2015.
//  Copyright (c) 2015 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (KVCArray)

- (id)valueForIndexedKeyPath:(NSString *)keyPath;

@end
