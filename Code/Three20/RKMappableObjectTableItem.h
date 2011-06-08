//
//  RKMappableObjectTableItem.h
//  RestKit
//
//  Created by Blake Watters on 4/26/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Three20/Three20.h>
#import "../RestKit.h"

@interface RKMappableObjectTableItem : TTTableLinkedItem {
    NSObject* _object;
}

@property (nonatomic, retain) NSObject* object;

+ (id)itemWithObject:(NSObject*)object;

@end
