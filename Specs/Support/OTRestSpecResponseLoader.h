//
//  OTRestSpecResponseLoader.h
//  OTRestFramework
//
//  Created by Blake Watters on 1/14/10.
//  Copyright 2010 Objective 3. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface OTRestSpecResponseLoader : NSObject {
	BOOL _awaitingResponse;
	id _response;
}

// The object that was loaded from the web request
@property (nonatomic, readonly) id response;

// Wait for a response to load
- (void)waitForResponse;
- (void)loadResponse:(id)response;

@end
