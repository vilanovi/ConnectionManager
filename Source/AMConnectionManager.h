//
//  AMConnectionManager.h
//  SampleProject
//
//  Created by Joan Martin on 10/3/12.
//  Copyright (c) 2012 AugiaMobile. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AMConnectionManagerTypes.h"

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


// ---------- Asynchronous Connections  ---------- //

/*!
 * Add trusted hosts for specific requests that uses credentials.
 */
@property (nonatomic, strong) NSArray *trustedHosts;

/*!
 * This methods performs asynchornously a connection request.
 * @param request The request to perform.
 * @param progressStatus This block is potentially called multiple times, containing in the dictionary information about the headers and download & upload progress.
 * @param completionBlock This block is called when the connection ends.
 * @discussion  Because the connection is not performed within an operation queue, once this method has been called the connection starts and it is not possible to cancel or modify it. The completionBlock may retur the NSURLResponse and the NSData or the NSError specifying the connection error.
 */
- (void)performRequest:(NSURLRequest*)request progressStatus:(void (^)(NSDictionary *progressStatus))progressStatusBlock completionBlock:(void (^)(NSURLResponse* response, NSData* data, NSError* error))completionBlock;

// ---------- Asynchronous OperationQueue-Based Connections ---------- //

/*!
 * Set the maximum number of concurrent connections. By default (-1), the maximum number of operations is determined dynamically using the current system conditions.
 */
@property (nonatomic, readwrite) NSInteger maxConcurrentConnectionCount;

/*!
 * Use this method to perform a request connection asynchronously and get back the response in the main thread. 
 * @param request The request to perform.
 * @param completion The completion block with the response, the data and the error (in case of any problems).
 * @return The method returns an integer used as a key to identify the request. This identifier can be used in order to cancel the request.
 * @discussion The complation block may return all parameters nil if the request has not been performed, otherwise allways will return or a response and a data, or an error specifying the connection error. The priority of this request will be setted to AMConnectionPriorityNormal.
 */
- (NSInteger)performRequest:(NSURLRequest*)request completionBlock:(void (^)(NSURLResponse* response, NSData* data, NSError* error, NSInteger key))completion;

/*!
 * Use this method to perform a request connection asynchronously and get back the response in the main thread with a given priority.
 * @param request The request to perform.
 * @param priority
 * @param completion The completion block with the response, the data and the error (in case of any problems).
 * @return The method returns an integer used as a key to identify the request. This identifier can be used in order to cancel the request.
 * @discussion The completion block may return all parameters nil if the request has not been performed, otherwise allways will return or a response and a data, or an error specifying the connection error.
 */
- (NSInteger)performRequest:(NSURLRequest*)request priority:(AMConnectionPriority)priority completionBlock:(void (^)(NSURLResponse* response, NSData* data, NSError* error, NSInteger key))completion;

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

@end
