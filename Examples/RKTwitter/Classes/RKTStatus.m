//
//  RKTStatus.m
//  RKTwitter
//
//  Created by Blake Watters on 9/5/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKTStatus.h"

@implementation RKTStatus

@synthesize statusID = _statusID;
@synthesize createdAt = _createdAt;
@synthesize text = _text;
@synthesize urlString = _urlString;
@synthesize inReplyToScreenName = _inReplyToScreenName;
@synthesize isFavorited = _isFavorited;	
@synthesize user = _user;

#pragma mark RKObjectMappable methods

+ (NSDictionary*)elementToPropertyMappings {
	return [NSDictionary dictionaryWithKeysAndObjects:
			@"id", @"statusID",
			@"created_at", @"createdAt",
			@"text", @"text",
			@"url", @"urlString",
			@"in_reply_to_screen_name", @"inReplyToScreenName",
			@"favorited", @"isFavorited",
			nil];
}

+ (NSDictionary*)elementToRelationshipMappings {
	return [NSDictionary dictionaryWithKeysAndObjects:
			@"user", @"user",
			nil];
}

- (NSString*)description {
	return [NSString stringWithFormat:@"%@ (ID: %@)", self.text, self.statusID];
}

- (void)dealloc {
    [_statusID release];
	[_createdAt release];
	[_text release];
    [_urlString release];
    [_inReplyToScreenName release];
    [_user release];
    
    [super dealloc];
}

@end
