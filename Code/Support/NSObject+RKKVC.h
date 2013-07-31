//
//  NSObject+RKKVC.h
//  RestKit
//
//  Created by Simon Booth on 31/07/2013.
//  Copyright (c) 2013 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (RKKVC)

- (NSString *)rk_firstKeyInKeyPath:(NSString *)keyPath;
- (id)rk_firstValueForKeyPath:(NSString *)keyPath outKeyPath:(NSString **)outKeyPath;
- (id)rk_valueForKeyPath:(NSString *)keyPath;

@end
