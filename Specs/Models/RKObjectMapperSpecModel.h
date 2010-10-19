//
//  RKObjectMapperSpecModel.h
//  RestKit
//
//  Created by Blake Watters on 2/18/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RKObjectMapperSpecModel : NSObject {
	NSString* _name;
	NSNumber* _age;
	NSDate* _createdAt;
}

@property (nonatomic,retain) NSString* name;
@property (nonatomic,retain) NSNumber* age;
@property (nonatomic,retain) NSDate* createdAt;

@end

