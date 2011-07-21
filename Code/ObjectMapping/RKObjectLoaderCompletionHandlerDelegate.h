//
//  RKObjectLoaderCompletionHandlerDelegate.h
//  RestKit
//
//  Created by Jeff Seibert on 7/21/11.
//  Copyright 2011 Crashlytics, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKObjectLoader.h"

@interface RKObjectLoaderCompletionHandlerDelegate : NSObject <RKObjectLoaderDelegate> {
	void (^_loadHandler) (RKObjectLoader *loader, NSArray *objects);
	void (^_failureHandler) (RKObjectLoader *loader, NSError *error);
}

+ (RKObjectLoaderCompletionHandlerDelegate *)delegateWithLoadHandler:(void (^)(RKObjectLoader *loader, NSArray *objects))loadHandler
													  failureHandler:(void (^)(RKObjectLoader *loader, NSError *error))failureHandler;

@end
