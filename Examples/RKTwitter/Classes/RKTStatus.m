//
//  RKTStatus.m
//  RKTwitter
//
//  Created by Blake Watters on 9/5/10.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
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
