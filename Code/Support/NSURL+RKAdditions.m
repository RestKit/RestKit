//
//  NSURL+RKAdditions.h
//  RestKit
//
//  Created by Blake Watters on 10/11/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "NSURL+RKAdditions.h"
#import "NSDictionary+RKAdditions.h"
#import "RKFixCategoryBug.h"
#import "NSString+RKAdditions.h"

RK_FIX_CATEGORY_BUG(NSURL_RKAdditions)

@implementation NSURL (RKAdditions)

- (NSDictionary *)queryParameters
{
    return [NSDictionary dictionaryWithURLEncodedString:self.query];
}

- (NSString *)MIMETypeForPathExtension
{
    return [[self path] MIMETypeForPathExtension];
}

@end
