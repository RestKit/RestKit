//
//  NSData+GZip.h
//  RestKit
//
//  Created by Stefan Walkner on 30.01.12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (GZip)

- (id) dataFromCompressedData;

@end
