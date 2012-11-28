//
//  AMAsynchronousConnection.m
//  SampleProject
//
//  Created by Joan Martin on 10/5/12.
//  Copyright (c) 2012 AugiaMobile. All rights reserved.
//

#import "AMAsynchronousConnection.h"


@interface AMAsynchronousConnection () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@end

@implementation AMAsynchronousConnection
{
    NSMutableData *_data;
    NSURLResponse *_response;
    NSError *_error;
    
    NSURLConnection *_connection;
    
    long long _expectedContentLength;
}

- (id)init
{
    return [self initWithRequest:nil progressStatus:NULL completionBlock:NULL];
}

- (id)initWithRequest:(NSURLRequest*)request completionBlock:(void (^)(NSURLResponse* response, NSData* data, NSError* error))completionBlock
{
    return [self initWithRequest:request progressStatus:NULL completionBlock:completionBlock];
}

- (id)initWithRequest:(NSURLRequest*)request progressStatus:(void (^)(NSDictionary *progressStatus))progressStatusBlock completionBlock:(void (^)(NSURLResponse* response, NSData* data, NSError* error))completionBlock
{
    self = [super init];
    if (self)
    {
        _request = request;
        _progressStatusBlock = progressStatusBlock;
        _completionBlock = completionBlock;
        
        _data = [NSMutableData data];
        _expectedContentLength = 0.0f;
        _trustedHosts = @[];
    }
    return self;
}

#pragma mark Public Methods

- (void)start
{
    _connection = [[NSURLConnection alloc] initWithRequest:_request delegate:self startImmediately:NO];

    NSRunLoop * runLoop = [NSRunLoop mainRunLoop];
    [_connection scheduleInRunLoop:runLoop forMode:NSRunLoopCommonModes];
    
    [_connection start];
}

- (void)cancel
{
    [_connection cancel];
    
    if ([_delegate respondsToSelector:@selector(didFinishAsynchronousConnection:)])
        [_delegate didFinishAsynchronousConnection:self];
}

#pragma mark Private Methods


#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    _error = error;
    
    if (_completionBlock)
        _completionBlock(_response,_data,_error);
    
    if ([_delegate respondsToSelector:@selector(didFinishAsynchronousConnection:)])
        [_delegate didFinishAsynchronousConnection:self];
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        if ([_trustedHosts containsObject:challenge.protectionSpace.host])
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
            _expectedContentLength = [httpResponse expectedContentLength];
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
    if (_completionBlock)
        _completionBlock(_response,_data,_error);
    
    if ([_delegate respondsToSelector:@selector(didFinishAsynchronousConnection:)])
        [_delegate didFinishAsynchronousConnection:self];
}

@end
