//
//  RKClientOAuth.h
//  RestKit
//
//  Created by Rodrigo Garcia on 7/20/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface RKOAuthClient : NSObject {
	NSString* _clientID;
    NSString* _clientSecret;
	NSString* _authorizationCode;
    NSString* _authorizationURL;
    NSString* _accessTokenURL;
    NSString* _accessToken;
}

// General properties of the client
@property(nonatomic,retain) NSString* authorizationCode;

// OAuth Client ID and Secret
@property(nonatomic,retain) NSString* clientID;
@property(nonatomic,retain) NSString* clientSecret;

// OAuth EndPoints
@property(nonatomic,retain) NSString* authorizationURL;
@property(nonatomic,retain) NSString* accessTokenURL;

// OAuth accessToken getter
- (NSString *)getAccessToken;


- (id)initWithClientID:(NSString *)clientId 
                secret:(NSString *)secret;

- (void)validateAuthorizationCode;

@end
