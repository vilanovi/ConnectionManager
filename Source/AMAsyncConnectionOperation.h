//
//  AMAsyncConnectionOperation.h
//  ConnectionManager
//
//  Created by Joan Martin on 11/27/12.
//  Copyright (c) 2012 Joan Martin. All rights reserved.
//

#import "AMConcurrentOperation.h"

// --- Asynchrounous Action Based Values -- //
extern NSString * const AMAsynchronousConnectionStatusDownloadProgressKey;
extern NSString * const AMAsynchronousConnectionStatusUploadProgressKey;
extern NSString * const AMAsynchronousConnectionStatusReceivedURLHeadersKey;

@interface AMAsyncConnectionOperation : AMConcurrentOperation <NSCopying, NSURLConnectionDelegate, NSURLConnectionDataDelegate>

/*!
 * Default initializer.
 * @param request The NSURLRequest to perform.
 * @param completion The completion block with the results of the connection. This Block is executed in the main thread.
 */
- (id)initWithRequest:(NSURLRequest*)request completionBlock:(void (^)(NSURLResponse* response, NSData* data, NSError* error))completion;

/*!
 * The receiver's request.
 */
@property (nonatomic, readonly, strong) NSURLRequest *request;

/*!
 * The receiver's completion block.
 */
@property (nonatomic, strong) void (^completion)(NSURLResponse* response, NSData* data, NSError* error);

/*!
 * Progress Status Block.
 */
@property (nonatomic, strong) void (^progressStatusBlock)(NSDictionary *info);

/*!
 * List of trusted hosts.
 */
@property (nonatomic, strong) NSArray *trustedHosts;

@end
