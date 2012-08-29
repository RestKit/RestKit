//
//  RKHTTPRequestOperation.h
//  GateGuru
//
//  Created by Blake Watters on 8/7/12.
//  Copyright (c) 2012 GateGuru, Inc. All rights reserved.
//

#import "AFNetworking.h"
#import "AFHTTPRequestOperation.h"

// TODO: AFNetworking should expose the default headers dictionary...
@interface AFHTTPClient ()
@property (readonly, nonatomic) NSDictionary *defaultHeaders;
@end

// NOTE: Accepts 2xx and 4xx status codes, application/json only.
// TODO: May want to factor this down into another more specific operation subclass to generalize the behavior
@interface RKHTTPRequestOperation : AFHTTPRequestOperation

// We allow override of status codes and content types on a per-request basis
@property (nonatomic, strong) NSIndexSet *acceptableStatusCodes; // Default nil: means defer to class level
@property (nonatomic, strong) NSSet *acceptableContentTypes;     // Default nil: means defer to class level

@end
