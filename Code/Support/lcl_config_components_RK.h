//
//  lcl_config_components_RK.h
//  RestKit
//
//  Created by Blake Watters on 6/8/11.
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

//
// The lcl_config_components_RK.h file is used to define the application's log
// components.
//
// Use the code
//
//   _RKlcl_component(<identifier>, <header>, <name>)
//
// for defining a log component, where
//
// - <identifier> is the unique name of a log component which is used in calls
//   to RKlcl_log etc. A symbol 'RKlcl_c<identifier>' is automatically created for
//   each log component.
//
// - <header> is a C string in UTF-8 which should be used by a logging back-end
//   when writing a log message for the log component. The header is a technical
//   key for identifying a log component's messages. It is recommended to use
//   a 'Reverse ICANN' naming scheme when the header contains grouping
//   information, e.g. 'example.main.component1'.
//
// - <name> is a C string in UTF-8 which contains the name of the log component
//   and its grouping information in a non-technical, human-readable way
//   which could be used by a user interface. Groups should be separated by the
//   path separator '/', e.g. 'Example/Main/Component 1'.
//


//
// RestKit Logging Components
//

_RKlcl_component(App,                         "app",                              "App")
_RKlcl_component(RestKit,                     "restkit",                          "RestKit")
_RKlcl_component(RestKitCoreData,             "restkit.core_data",                "RestKit/CoreData")
_RKlcl_component(RestKitCoreDataCache,        "restkit.core_data.cache",          "RestKit/CoreData/Cache")
_RKlcl_component(RestKitNetwork,              "restkit.network",                  "RestKit/Network")
_RKlcl_component(RestKitObjectMapping,        "restkit.object_mapping",           "RestKit/ObjectMapping")
_RKlcl_component(RestKitSearch,               "restkit.search",                   "RestKit/Search")
_RKlcl_component(RestKitSupport,              "restkit.support",                  "RestKit/Support")
_RKlcl_component(RestKitTesting,              "restkit.testing",                  "RestKit/Testing")
_RKlcl_component(RestKitUI,                   "restkit.ui",                       "RestKit/UI")
