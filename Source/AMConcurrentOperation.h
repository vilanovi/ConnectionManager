//
//  AMConcurrentOperation.h
//  SampleProject
//
//  Created by Joan Martin on 10/4/12.
//  Copyright (c) 2012 AugiaMobile. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 * This class creates concurrent capabilities to a NSOperation. 
 */
@interface AMConcurrentOperation : NSOperation

/*!
 * Subclasses should override this method in order to implement the code that will be executed asynchronously.
 */
- (void)concurrentMain;

/*!
 * This method is called when the concurrentMain method is finished. Subclasses may override this method.
 * @discussion This method is executed in the main thread and before the "completionBlock" NSOperation property.
 */
- (void)operationDidFinish;

@end
