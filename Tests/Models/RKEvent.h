//
//  RKEvent.h
//  RestKit
//
//  Created by Greg Combs on 12/23/11.
//  Copyright 2011
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


#import "NSManagedObject+ActiveRecord.h"

@interface RKEvent : NSManagedObject {

}

@property (nonatomic, retain) NSString *eventID;
@property (nonatomic, retain) NSString *eventType;
@property (nonatomic, retain) NSString *location;
@property (nonatomic, retain) NSString *summary;

@end
