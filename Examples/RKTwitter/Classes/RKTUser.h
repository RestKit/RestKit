//
//  RKTUser.h
//  RKTwitter
//
//  Created by Blake Watters on 9/5/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import <RestKit/RestKit.h>

@interface RKTUser : RKObject {
	NSNumber* _userID;
	NSString* _name;
	NSString* _screenName;
}

@property (nonatomic, retain) NSNumber* userID;
@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSString* screenName;

@end
