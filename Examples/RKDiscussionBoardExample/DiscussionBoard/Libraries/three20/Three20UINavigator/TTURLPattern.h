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
#import <UIKit/UIKit.h>

@protocol TTURLPatternText;

@interface TTURLPattern : NSObject {
  NSString*             _URL;
  NSString*             _scheme;
  NSMutableArray*       _path;
  NSMutableDictionary*  _query;
  id<TTURLPatternText>  _fragment;
  NSInteger             _specificity;
  SEL                   _selector;
}

@property (nonatomic, copy)     NSString* URL;
@property (nonatomic, readonly) NSString* scheme;
@property (nonatomic, readonly) NSInteger specificity;
@property (nonatomic, readonly) Class     classForInvocation;
@property (nonatomic)           SEL       selector;

- (void)setSelectorIfPossible:(SEL)selector;

- (void)compileURL;

@end
