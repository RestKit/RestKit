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

#import <Foundation/Foundation.h>

@class TTLauncherView;
@class TTLauncherItem;

@protocol TTLauncherViewDelegate <NSObject>

@optional

- (void)launcherView:(TTLauncherView*)launcher didAddItem:(TTLauncherItem*)item;

- (void)launcherView:(TTLauncherView*)launcher didRemoveItem:(TTLauncherItem*)item;

- (void)launcherView:(TTLauncherView*)launcher didMoveItem:(TTLauncherItem*)item;

- (void)launcherView:(TTLauncherView*)launcher didSelectItem:(TTLauncherItem*)item;

- (void)launcherViewDidEndDragging:(TTLauncherView*)launcher;

- (void)launcherViewDidBeginEditing:(TTLauncherView*)launcher;

- (void)launcherViewDidEndEditing:(TTLauncherView*)launcher;

@end

