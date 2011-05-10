//
//  RKError.h
//  RestKit
//
//  Created by Jeremy Ellison on 5/10/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface RKErrorMessage : NSObject {
    NSString* _errorMessage;
}

@property (nonatomic, retain) NSString* errorMessage;

@end
