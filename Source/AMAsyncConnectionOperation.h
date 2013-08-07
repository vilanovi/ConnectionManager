//
//  AMAsyncConnectionOperation.h
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
 * Credential for Server Trust Authentication.
 */
@property (nonatomic, assign) BOOL serverTurstAuthentication;

/*!
 * Credential used for HTTP Basic Authentication, HTTP Digest Authentication or Client Certificate Authentication
 */
@property (nonatomic, strong) NSURLCredential *credential;

/*!
 * If authentication fails, YES, otherwise NO.
 */
@property (nonatomic, assign, readonly) BOOL authenticationFailed;

/*!
 * If authentication is performed and it's invalid, this block will be called.
 */
@property (nonatomic, strong) void (^authenticationDidFail)(AMAsyncConnectionOperation *op, NSURLAuthenticationChallenge *challange);

/*!
 * Implement this block and return if it is possible to authenticate to the given protection space.
 * @discussion The value returned for this block will override any previous behavior and if NO will not consider authentication even if the properties `credential` or `serverTrustAuthentication`  are defined.
 */
@property (nonatomic, strong) BOOL (^canAuthenticateAgainstProtectionSpace)(NSURLProtectionSpace *protectionSpace);

/*!
 * Implement this block to perform the authentication.
 * @discussion By implementing this block the connection operation will ignore the properties `credential`and `serverTrustAuthentication`. It is going to be the block's implementation responsibility to perform the authentication.
 *
 * If you cancel the authentication, is your reponsibility to give feedback to the user telling why. Also, the authenticationDidFail block and the authentication delegate methods of the connection manager won't be called.
 */
@property (nonatomic, strong) void (^performAuthenticationWithChallenge)(NSURLAuthenticationChallenge *challenge);

@end
