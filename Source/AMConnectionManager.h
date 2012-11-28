//
//  AMConnectionManager.h
//  SampleProject
//
//  Created by Joan Martin on 10/3/12.
//  Copyright (c) 2012 AugiaMobile. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AMAsyncConnectionOperation.h"

extern NSString * const AMConnectionManagerDefaultQueueIdentifier;

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

@class AMConcurrentOperation;
@class AMAsyncConnectionOperation;

/*!
 * This class manages connection requests asynchronously in order to control the concurrent executions. User can set the maximum concurrent number of connections, cancel queued requests, give priorities, etc. This class implements the singleton pattern in order to share a single instance.
 */
@interface AMConnectionManager : NSObject

/*!
 * Returns the default manager instance in order to use this class as a singleton.
 * @return The default manager instance.
 */
+ (AMConnectionManager*)defaultManager;

/*!
 * This property allows to turn on/off the UIApplication's networkActivityIndicator while requests are being performed.
 */
@property (nonatomic, assign) BOOL showsNetworkActivityIndicator;

/*!
 * Set the maximum number of concurrent connections of the default queue. By default (-1), the maximum number of operations is determined dynamically using the current system conditions.
 */
@property (nonatomic, readwrite) NSInteger maxConcurrentConnectionCount;

/*!
 * Add trusted hosts for specific requests that uses credentials.
 */
@property (nonatomic, strong) NSArray *trustedHosts;


/*!
 * Configure the max number of concurrent connections for a specific queue.
 * @param maxConcurrentConnectionCount The maximum number of connections. Specify -1 (default) and the system will determine the value automatically.
 */
- (void)setMaxConcurrentConnectionCount:(NSInteger)maxConcurrentConnectionCount inQueue:(NSString*)queueIdentifier;

/*!
 * This method allow request cancelation.
 * @param key The request key.
 * @discussion If the request has been already executed or the key is unknown, this method does nothing.
 */
- (void)cancelRequestWithKey:(NSInteger)key;

/*!
 * Changes the priority of the request associated to the given key.
 * @param priority The new priority.
 * @param key The request identifier.
 * @discussion If the request has been already executed or the key is unknown, this method does nothing.
 */
- (void)changeToPriority:(AMConnectionPriority)priority requestWithKey:(NSInteger)key;

/*!
 * Returns the operation queue for the given identifier.
 * @return The operation queue
 * @discussion You can use this method in order to configure a queue manually.
 */
- (NSOperationQueue*)operationQueueForIdentifier:(NSString*)identifier;

/*!
 * Use this method to add manually a connection operation (AMConnectionOperation or AMAsyncConnectionOperation). This method enqueue the operation to the specified queue.
 * @param operation The operation to execute.
 * @param queueIdentifier An identifier of the queue. Pass nil to use the default queue.
 * @return 
 */
- (NSInteger)performConnectionOperation:(AMAsyncConnectionOperation*)operation inQueue:(NSString*)queueIdentifier;

/*!
 * Use this method to perform a request connection asynchronously and get back the response in the main thread.
 * @param request The request to perform.
 * @param completion The completion block with the response, the data and the error (in case of any problems).
 * @return The method returns an integer used as a key to identify the request. This identifier can be used in order to cancel the request.
 * @discussion The priority of this request is setted to AMConnectionPriorityNormal.
 */
- (NSInteger)performRequest:(NSURLRequest*)request
            completionBlock:(void (^)(NSURLResponse* response, NSData* data, NSError* error, NSInteger key))completion;

/*!
 * Use this method to perform a request connection asynchronously and get back the response in the main thread with a given priority.
 * @param request The request to perform.
 * @param priority
 * @param completion The completion block with the response, the data and the error (in case of any problems).
 * @return The method returns an integer used as a key to identify the request. This identifier can be used in order to cancel the request.
 */
- (NSInteger)performRequest:(NSURLRequest*)request
                   priority:(AMConnectionPriority)priority
            completionBlock:(void (^)(NSURLResponse* response, NSData* data, NSError* error, NSInteger key))completion;

/*!
 * This methods performs asynchornously a connection request.
 * @param request The request to perform.
 * @param progressStatus This block is potentially called multiple times, containing in the dictionary information about the headers and download & upload progress.
 * @param completionBlock This block is called when the connection ends.
 * @return The method returns an integer used as a key to identify the request. This identifier can be used in order to cancel the request.
 * @discussion The priority of this request is setted to AMConnectionPriorityNormal.
 */
- (NSInteger)performRequest:(NSURLRequest*)request
             progressStatus:(void (^)(NSDictionary *progressStatus))progressStatusBlock
            completionBlock:(void (^)(NSURLResponse* response, NSData* data, NSError* error, NSInteger key))completion;

/*!
 * This methods performs asynchornously a connection request.
 * @param request The request to perform.
 * @param progressStatus This block is potentially called multiple times, containing in the dictionary information about the headers and download & upload progress.
 * @param completionBlock This block is called when the connection ends.
 * @return The method returns an integer used as a key to identify the request. This identifier can be used in order to cancel the request.
 */
- (NSInteger)performRequest:(NSURLRequest*)request
                   priority:(AMConnectionPriority)priority
             progressStatus:(void (^)(NSDictionary *progressStatus))progressStatusBlock
            completionBlock:(void (^)(NSURLResponse* response, NSData* data, NSError* error, NSInteger key))completion;

@end
