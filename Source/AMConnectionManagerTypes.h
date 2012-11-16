//
//  AMConnectionManagerTypes.h
//  SampleProject
//
//  Created by Joan Martin on 10/5/12.
//  Copyright (c) 2012 AugiaMobile. All rights reserved.
//


// --- Asynchrounous Action Based Values -- //
/*!
 *
 */
extern NSString * const AMAsynchronousConnectionStatusDownloadProgressKey;
extern NSString * const AMAsynchronousConnectionStatusUploadProgressKey;
extern NSString * const AMAsynchronousConnectionStatusReceivedURLHeadersKey;


// --- OperationQueue-Based Connections -- //

/*!
 * @typedef AMConnectionPriority
 * @abstract These are the available priorities to assign to connection requests.
 * @constant AMConnectionPriorityVeryLow Lower priority.
 * @constant AMConnectionPriorityLow This priority is higher than AMConnectionPriorityVeryLow and lower than others.
 * @constant AMConnectionPriorityNormal This is the default priority for connections. Also it is placed in the middle of all priorities.
 * @constant AMConnectionPriorityHigh The second placed priority.
 * @constant AMConnectionPriorityVeryHigh The highest priority.
 * @discussion The AMConnectionPriority is equivalent to NSOperationQueuePriority.
 */
typedef enum {
    AMConnectionPriorityVeryLow = NSOperationQueuePriorityVeryLow,
    AMConnectionPriorityLow = NSOperationQueuePriorityLow,
    AMConnectionPriorityNormal = NSOperationQueuePriorityNormal,
    AMConnectionPriorityHigh = NSOperationQueuePriorityHigh,
    AMConnectionPriorityVeryHigh = NSOperationQueuePriorityHigh
} AMConnectionPriority;
