//
//  RestKit.h
//  RestKit
//
//  Created by Blake Watters on 2/19/10.
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

#ifndef _RESTKIT_
#define _RESTKIT_

#import "ObjectMapping.h"
#import "Network.h"
#import "Support.h"

#ifdef _COREDATADEFINES_H
#import "CoreData.h"
#endif

/**
 Set the App logging component. This header
 file is generally only imported by apps that
 are pulling in all of RestKit. By setting the
 log component to App here, we allow the app developer
 to use RKLog() in their own app.
 */
#undef RKLogComponent
#define RKLogComponent RKlcl_cApp

#endif /* _RESTKIT_ */
