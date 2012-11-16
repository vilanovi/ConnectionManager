//
//  AMConnectionOperation.h
//  SampleProject
//
//  Created by Joan Martin on 10/4/12.
//  Copyright (c) 2012 AugiaMobile. All rights reserved.
//

#import "AMConcurrentOperation.h"

/*!
 * This class implements a NSURLConnection in order to perform a NSURLRequest connection.
 */
@interface AMConnectionOperation : AMConcurrentOperation

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
@property (nonatomic, readonly, strong) void (^completion)(NSURLResponse* response, NSData* data, NSError* error);

@end
