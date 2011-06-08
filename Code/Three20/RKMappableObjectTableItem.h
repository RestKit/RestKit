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
    NSObject<RKObjectMappable>* _object;
}

@property (nonatomic, retain) NSObject<RKObjectMappable>* object;

+ (id)itemWithObject:(NSObject<RKObjectMappable>*)object;

@end
