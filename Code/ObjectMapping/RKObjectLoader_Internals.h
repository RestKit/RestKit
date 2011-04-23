//
//  RKObjectLoader_Internals.h
//  RestKit
//
//  Created by Blake Watters on 5/13/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RKObjectLoader (Internals) <RKObjectMapperDelegate>

@property (nonatomic, readonly) RKClient* client;

- (void)handleTargetObject;
- (void)informDelegateOfObjectLoadWithInfoDictionary:(NSDictionary*)dictionary;
- (void)performMappingOnBackgroundThread;

@end
