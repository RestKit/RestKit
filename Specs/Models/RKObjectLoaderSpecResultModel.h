//
//  RKObjectLoaderSpecResultModel.h
//  RestKit
//
//  Created by Blake Watters on 6/23/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RKObjectLoaderSpecResultModel : NSObject {
    NSNumber* _ID;
    NSDate* _endsAt;
    NSString* _photoURL;
}

@property (nonatomic, retain) NSNumber* ID;
@property (nonatomic, retain) NSDate* endsAt;
@property (nonatomic, retain) NSString* photoURL;

@end
