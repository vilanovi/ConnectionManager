//
//  AMAsyncConnectionOperation.m
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
    
    BOOL _authenticationFailed;
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
        _serverTurstAuthentication = NO;
        _authenticationFailed = NO;
    }
    return self;
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"%@ - %@",[super description], [self.connectionManagerKey description]];
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
    
    [[AMConnectionManager defaultManager] AM_connectionOperation:self connectionDidFailWithError:error];
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    if (_canAuthenticateAgainstProtectionSpace)
        return _canAuthenticateAgainstProtectionSpace(protectionSpace);
    
    BOOL canAuthenticate = NO;
    
    if ([protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        canAuthenticate = _serverTurstAuthentication;
    }
    else
    {
        canAuthenticate = _credential != nil;
    }
        
    return canAuthenticate;
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if (_performAuthenticationWithChallenge)
    {
        _performAuthenticationWithChallenge(challenge);
    }
    else
    {
        if ([challenge previousFailureCount] == 0)
        {
            if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
            {
                [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
            }
            else
            {
                if (_credential)
                    [[challenge sender] useCredential:_credential forAuthenticationChallenge:challenge];
                else
                    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
            }
        }
        else
        {
            _authenticationFailed = YES;
            
            if (_authenticationDidFail)
                _authenticationDidFail(self, challenge);
            
            [[AMConnectionManager defaultManager] AM_connectionOperation:self authenticationDidFailWithAuthenticationChallenge:challenge];
            
            [[challenge sender] cancelAuthenticationChallenge:challenge];
        }
    }
}

- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    _authenticationFailed = YES;
    
    if (_authenticationDidFail)
        _authenticationDidFail(self, challenge);
    
    [[AMConnectionManager defaultManager] AM_connectionOperation:self authenticationDidFailWithAuthenticationChallenge:challenge];
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
