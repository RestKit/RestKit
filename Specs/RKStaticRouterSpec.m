//
//  RKStaticRouterSpec.m
//  RestKit
//
//  Created by Blake Watters on 7/20/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKStaticRouter.h"
#import "RKHuman.h"

@interface RKStaticRouterSpec : NSObject <UISpec> {
}

@end

@implementation RKStaticRouterSpec

-(void)itShouldReturnPathsRegisteredForSpecificRequestMethods {
	RKStaticRouter* router = [[RKStaticRouter alloc] init];
	[router routeClass:[RKHuman class] toPath:@"/HumanService.asp" forMethod:RKRequestMethodGET];
//	[expectThat(
}

-(void)itShouldReturnPathsRegisteredForTheClassAsAWhole {
}

@end
