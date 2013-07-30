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

/// --------------------------------------------------------------------------------------------------------------------------------
/// @name Creating and getting instances
/// --------------------------------------------------------------------------------------------------------------------------------

/*!
 * Default initializer.
 * @param request The NSURLRequest to perform.
 * @param completion The completion block with the results of the connection. This Block is executed in the main thread.
 */
- (id)initWithRequest:(NSURLRequest*)request completionBlock:(void (^)(NSURLResponse* response, NSData* data, NSError* error))completion;

/// --------------------------------------------------------------------------------------------------------------------------------
/// @name Main attritubes
/// --------------------------------------------------------------------------------------------------------------------------------

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

/// --------------------------------------------------------------------------------------------------------------------------------
/// @name Authentication
/// --------------------------------------------------------------------------------------------------------------------------------

/*!
 * Trust the current request url host.
 */
@property (nonatomic, assign) BOOL trustHost;

/*!
 * Credential
 */
@property (nonatomic, strong) NSURLCredential *credential;

@end
