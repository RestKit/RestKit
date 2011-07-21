//
//  RKRequest_Internals.h
//  RestKit
//
//  Created by Blake Watters on 5/31/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

@interface RKRequest (Internals)
- (BOOL)prepareURLRequest;
- (void)didFailLoadWithError:(NSError*)error;
@end
