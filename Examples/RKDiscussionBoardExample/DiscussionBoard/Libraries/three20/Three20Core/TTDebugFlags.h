//
// Copyright 2009-2010 Facebook
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

/**
 * These flags are used primarily by TTDCONDITIONLOG.
 * Example:
 *
 *    TTDCONDITIONLOG(TTDFLAG_NAVIGATOR, @"TTNavigator activated");
 *
 * This will only write to the log if the TTDFLAG_NAVIGATOR is set to non-zero.
 */
#define TTDFLAG_VIEWCONTROLLERS             0
#define TTDFLAG_CONTROLLERGARBAGECOLLECTION 0
#define TTDFLAG_NAVIGATOR                   0
#define TTDFLAG_TABLEVIEWMODIFICATIONS      0
#define TTDFLAG_LAUNCHERVIEW                0
#define TTDFLAG_URLREQUEST                  0
#define TTDFLAG_URLCACHE                    0
#define TTDFLAG_XMLPARSER                   0
#define TTDFLAG_ETAGS                       0
