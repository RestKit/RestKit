//
//  RKTUser.h
//  RKTwitter
//
//  Created by Blake Watters on 9/5/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData/CoreData.h>

@interface RKTUser : RKManagedObject {
}

@property (nonatomic, retain) NSNumber* userID;
@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSString* screenName;

@end
