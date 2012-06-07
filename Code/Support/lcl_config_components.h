//
//  lcl_config_components.h
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
// The lcl_config_components.h file is used to define the application's log
// components.
//
// Use the code
//
//   _lcl_component(<identifier>, <header>, <name>)
//
// for defining a log component, where
//
// - <identifier> is the unique name of a log component which is used in calls
//   to lcl_log etc. A symbol 'lcl_c<identifier>' is automatically created for
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

_lcl_component(RestKit,                     "restkit",                          "RestKit")
_lcl_component(RestKitNetwork,              "restkit.network",                  "RestKit/Network")
_lcl_component(RestKitNetworkCache,         "restkit.network.cache",            "RestKit/Network/Cache")
_lcl_component(RestKitNetworkQueue,         "restkit.network.queue",            "RestKit/Network/Queue")
_lcl_component(RestKitNetworkReachability,  "restkit.network.reachability",     "RestKit/Network/Reachability")
_lcl_component(RestKitObjectMapping,        "restkit.object_mapping",           "RestKit/ObjectMapping")
_lcl_component(RestKitCoreData,             "restkit.core_data",                "RestKit/CoreData")
_lcl_component(RestKitCoreDataCache,        "restkit.core_data.cache",          "RestKit/CoreData/Cache")
_lcl_component(RestKitCoreDataSearchEngine, "restkit.core_data.search_engine",  "RestKit/CoreData/SearchEngine")
_lcl_component(RestKitSupport,              "restkit.support",                  "RestKit/Support")
_lcl_component(RestKitSupportParsers,       "restkit.support.parsers",          "RestKit/Support/Parsers")
_lcl_component(RestKitThree20,              "restkit.three20",                  "RestKit/Three20")
_lcl_component(RestKitUI,                   "restkit.ui",                       "RestKit/UI")
_lcl_component(RestKitTesting,              "restkit.testing",                  "RestKit/Testing")
_lcl_component(App,                         "app",                              "App")
