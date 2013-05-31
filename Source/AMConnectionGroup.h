//
//  AMConnectionGroup.h
//  ConnectionManager
//
//  Created by Joan Martin on 1/11/13.
//  Copyright (c) 2013 Joan Martin. All rights reserved.
//

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