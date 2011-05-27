//
//  NSURL+RKAdditions.h
//  RestKit
//
//  Created by Rémy SAISSY on 13/05/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSURL (RKAdditions)

/* Check equality of two URLs. */
- (BOOL)isEqualToURL:(NSURL*)otherURL;

@end
