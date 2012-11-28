//
//  AMConnectionManager.m
//  SampleProject
//
//  Created by Joan Martin on 10/3/12.
//  Copyright (c) 2012 AugiaMobile. All rights reserved.
//

#import "AMConnectionManager.h"

NSString * const AMConnectionManagerDefaultQueueIdentifier = @"AMConnectionManagerDefaultQueueIdentifier";

@interface AMConnectionManager ()

@end

@implementation AMConnectionManager
{
    NSMutableDictionary *_queues;
    
    NSInteger _numberOfActiveConnections;
    
    NSMutableDictionary *_operations;
    NSInteger _lastKey;
}

@dynamic maxConcurrentConnectionCount;

+ (AMConnectionManager*)defaultManager
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _queues = [NSMutableDictionary dictionary];
        
        _numberOfActiveConnections = 0;
        _lastKey = -1;
        _operations = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark Properties

- (NSInteger)maxConcurrentConnectionCount
{
    return [[self _queueWithIdentifier:AMConnectionManagerDefaultQueueIdentifier] maxConcurrentOperationCount];
}

- (void)setMaxConcurrentConnectionCount:(NSInteger)maxConcurrentConnectionCount
{
    [[self _queueWithIdentifier:AMConnectionManagerDefaultQueueIdentifier] setMaxConcurrentOperationCount:maxConcurrentConnectionCount];
}

#pragma mark Public Methods

- (void)setMaxConcurrentConnectionCount:(NSInteger)maxConcurrentConnectionCount inQueue:(NSString*)queueIdentifier
{
    [[self _queueWithIdentifier:queueIdentifier] setMaxConcurrentOperationCount:maxConcurrentConnectionCount];
}

- (void)cancelRequestWithKey:(NSInteger)key
{
    NSOperation *operation = [_operations objectForKey:[NSNumber numberWithInteger:key]];
    [operation cancel];    
    [_operations removeObjectForKey:[NSNumber numberWithInteger:key]];
}

- (void)changeToPriority:(AMConnectionPriority)priority requestWithKey:(NSInteger)key
{
    NSOperation *operation = [_operations objectForKey:[NSNumber numberWithInteger:key]];
    [operation setQueuePriority:priority];
}

- (NSOperationQueue*)operationQueueForIdentifier:(NSString*)identifier
{
    return [self _queueWithIdentifier:identifier];
}

- (NSInteger)performConnectionOperation:(AMAsyncConnectionOperation*)operation inQueue:(NSString*)queueIdentifier
{
    NSOperationQueue *queue = [self _queueWithIdentifier:queueIdentifier];
    
    NSInteger operationKey = [self _nextKey];
    
    NSNumber *numberKey = [NSNumber numberWithInteger:operationKey];
    [_operations setObject:operation forKey:numberKey];
    
    [operation setCompletionBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [_operations removeObjectForKey:numberKey];
            _numberOfActiveConnections -= 1;
            [self _refreshNetworkActivityIndicatorState];
        });
    }];
    
    _numberOfActiveConnections++;
    [queue addOperation:operation];
    [self _refreshNetworkActivityIndicatorState];
    
    return operationKey;
}

- (NSInteger)performRequest:(NSURLRequest*)request completionBlock:(void (^)(NSURLResponse*, NSData*, NSError*, NSInteger))completion
{
    return [self performRequest:request
                       priority:AMConnectionPriorityNormal
                 progressStatus:NULL
                completionBlock:completion];
}


- (NSInteger)performRequest:(NSURLRequest*)request priority:(AMConnectionPriority)priority completionBlock:(void (^)(NSURLResponse* response, NSData* data, NSError* error, NSInteger key))completion
{
    return [self performRequest:request
                       priority:priority
                 progressStatus:NULL
                completionBlock:completion];
}


- (NSInteger)performRequest:(NSURLRequest*)request progressStatus:(void (^)(NSDictionary *progressStatus))progressStatusBlock completionBlock:(void (^)(NSURLResponse* response, NSData* data, NSError* error, NSInteger key))completion
{
    return [self performRequest:request
                       priority:AMConnectionPriorityNormal
                 progressStatus:progressStatusBlock
                completionBlock:completion];
}

- (NSInteger)performRequest:(NSURLRequest*)request priority:(AMConnectionPriority)priority progressStatus:(void (^)(NSDictionary *progressStatus))progressStatusBlock completionBlock:(void (^)(NSURLResponse* response, NSData* data, NSError* error, NSInteger key))completion
{
    NSInteger operationKey = [self _nextKey];
    
    void (^connectionCompletion)(NSURLResponse* response, NSData* data, NSError* error) = ^(NSURLResponse* response, NSData* data, NSError* error) {
        if (completion)
            completion(response, data, error, operationKey);
    };

    AMAsyncConnectionOperation *operation = [[AMAsyncConnectionOperation alloc] initWithRequest:request completionBlock:connectionCompletion];
    operation.trustedHosts = _trustedHosts;
    operation.progressStatusBlock = progressStatusBlock;
    operation.queuePriority = priority;
    
    NSNumber *numberKey = [NSNumber numberWithInteger:operationKey];
    [_operations setObject:operation forKey:numberKey];
    
    [operation setCompletionBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [_operations removeObjectForKey:numberKey];
            _numberOfActiveConnections -= 1;
            [self _refreshNetworkActivityIndicatorState];
        });
    }];
    
    NSOperationQueue *queue = [self _queueWithIdentifier:AMConnectionManagerDefaultQueueIdentifier];
    
    _numberOfActiveConnections++;
    [queue addOperation:operation];
    [self _refreshNetworkActivityIndicatorState];
    
    return operationKey;
}

#pragma mark Private Methods

- (NSOperationQueue*)_queueWithIdentifier:(NSString*)identifier
{
    if (identifier == nil)
        identifier = AMConnectionManagerDefaultQueueIdentifier;

    NSOperationQueue *queue = [_queues valueForKey:identifier];
    
    if (!queue)
    {
        queue = [[NSOperationQueue alloc] init];
        [_queues setValue:queue forKey:identifier];
    }
    
    return queue;
}

- (void)_refreshNetworkActivityIndicatorState
{
    if (!_showsNetworkActivityIndicator)
        return;
    
    BOOL state = _numberOfActiveConnections > 0 ? YES : NO;
        
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:state];
}

- (NSInteger)_nextKey
{
    NSInteger operationKey;
    
    @synchronized(self)
    {
        operationKey = _lastKey + 1;
        _lastKey = operationKey;
    }
    
    return operationKey;
}

@end
