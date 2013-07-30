//
//  AMAsyncConnectionOperation.m
//  ConnectionManager
//
//  Created by Joan Martin on 11/27/12.
//  Copyright (c) 2012 Joan Martin. All rights reserved.
//

#import "AMAsyncConnectionOperation_Private.h"

#import "AMConnectionManager_Private.h"

NSString * const AMAsynchronousConnectionStatusDownloadProgressKey = @"AMAsynchronousConnectionStatusDownloadProgressKey";
NSString * const AMAsynchronousConnectionStatusUploadProgressKey = @"AMAsynchronousConnectionStatusUploadProgressKey";
NSString * const AMAsynchronousConnectionStatusReceivedURLHeadersKey = @"AMAsynchronousConnectionStatusReceivedURLHeadersKey";

@implementation AMAsyncConnectionOperation
{
    CGFloat _expectedContentLength;
    
    NSMutableData* _data;
    NSURLResponse *_response;
    NSError *_error;
        
    NSPort *_port;
    NSRunLoop *_runLoop;
    NSURLConnection *_connection;
}

- (id)init
{
    return [self initWithRequest:nil completionBlock:NULL];
}

- (id)initWithRequest:(NSURLRequest*)request completionBlock:(void (^)(NSURLResponse*, NSData*, NSError*))completion
{
    self = [super init];
    if (self)
    {
        _request = request;
        _completion = completion;
        
        _data = [NSMutableData data];
        _expectedContentLength = 0.0f;
        _trustHost = NO;
    }
    return self;
}

- (void)cancel
{
    [super cancel];
    [self _stopConnection];
}

- (void)concurrentMain
{
    _port = [NSPort port];
    _runLoop = [NSRunLoop currentRunLoop];
    
    _connection = [[NSURLConnection alloc] initWithRequest:_request delegate:self startImmediately:NO];
    
    [_runLoop addPort:_port forMode:NSDefaultRunLoopMode];
    [_connection scheduleInRunLoop:_runLoop forMode:NSDefaultRunLoopMode];
    [_connection start];
        
    while (_connection != nil)
    {
        [_runLoop runUntilDate:[NSDate distantFuture]];
    }
}

- (void)operationDidFinish
{        
    if (!self.isCancelled)
    {
        if (_completion)
            _completion(_response,_data,_error);
    }
}

#pragma mark Private Methods

- (void)_stopConnection
{    
    [_connection cancel];
    
    [_port invalidate];
    [_runLoop removePort:_port forMode:NSDefaultRunLoopMode];
    _port = nil;
    
    _connection = nil;
}

#pragma mark - Protocols

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    AMAsyncConnectionOperation *operation = [[AMAsyncConnectionOperation allocWithZone:zone] initWithRequest:_request
                                                                                             completionBlock:_completion];
    operation.progressStatusBlock = _progressStatusBlock;
    operation.connectionManagerKey = _connectionManagerKey;
    
    operation.queuePriority = self.queuePriority;
    operation.completionBlock = self.completionBlock;
    
    return operation;
}

#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    _error = error;
    [self _stopConnection];
    
    [[AMConnectionManager defaultManager] AM_presentAlertViewForError:error];
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    BOOL canAuthenticate = NO;
    
    if ([protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodDefault])
    {
        canAuthenticate = _credential != nil;
    }
    else if ([protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        canAuthenticate = _trustHost;
    }
    
    return canAuthenticate;
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodDefault])
    {
        [[challenge sender] useCredential:_credential forAuthenticationChallenge:challenge];
    }
    else if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
    }
    
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

#pragma mark NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    _response = response;
    
    if ([response isKindOfClass:[NSHTTPURLResponse class]])
    {
        NSHTTPURLResponse *httpResponse = (id)response;
        if ([httpResponse statusCode] == 200)
        {
            _expectedContentLength = [httpResponse expectedContentLength];
        }
    }
    
    if (_progressStatusBlock)
        _progressStatusBlock(@{AMAsynchronousConnectionStatusReceivedURLHeadersKey:response});
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_data appendData:data];
    
    float progress = ((float)_data.length) / ((float)_expectedContentLength);
    
    if (_progressStatusBlock)
        _progressStatusBlock(@{AMAsynchronousConnectionStatusDownloadProgressKey:[NSNumber numberWithFloat:progress]});
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    float progress = ((float)totalBytesWritten)/((float)totalBytesExpectedToWrite);
    
    if (_progressStatusBlock)
        _progressStatusBlock(@{AMAsynchronousConnectionStatusUploadProgressKey:[NSNumber numberWithFloat:progress]});
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self _stopConnection];
}

@end
