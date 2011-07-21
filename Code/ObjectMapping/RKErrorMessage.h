//
//  RKError.h
//  RestKit
//
//  Created by Jeremy Ellison on 5/10/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 A destination class for mapping simple remote error messages.
 */
@interface RKErrorMessage : NSObject {
    NSString* _errorMessage;
}

/**
 The error message string mapped from the response payload
 */
@property (nonatomic, retain) NSString* errorMessage;

@end
