//
//  NSURL+RKAdditions.m
//  RestKit
//
//  Created by Rémy SAISSY on 13/05/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "NSURL+RKAdditions.h"


@implementation NSURL (RKAdditions)

- (BOOL)isEqualToURL:(NSURL*)otherURL
{
	return ([[self absoluteURL] isEqual:[otherURL absoluteURL]] 
            || ([self isFileURL] 
                && [otherURL isFileURL] 
                && [[self path] isEqual:[otherURL path]]));
}

@end
