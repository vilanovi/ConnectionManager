//
//  AMConnectionGroup.h
//  Created by Joan Martin.
//  Take a look to my repos at http://github.com/vilanovi
//
// Copyright (c) 2013 Joan Martin, vilanovi@gmail.com.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
// PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE

#import <Foundation/Foundation.h>

#import "AMConnectionManager.h"

/*!
 * This class allows to group connections by passing the keys of those we want to put together. Then, the class allows to manipulate those conection by cancel or pausing them.
 * @discussion Typically, use this class by holding one instance in each UIViewController and registering all connections that are created from this controller. The view controller have to cancel, pause or restart the connections or just change the priorities in the dealloc, viewDidDisappear or viewWillAppear methods.
 */
@interface AMConnectionGroup : NSObject

- (void)addConnectionKey:(NSInteger)connectionKey;
- (void)removeConnectionKey:(NSInteger)connectionKey;

- (void)cancel;
- (void)pause;
- (void)resume;

- (void)changeConnectionPrioritiesTo:(AMConnectionPriority)priority;

@end