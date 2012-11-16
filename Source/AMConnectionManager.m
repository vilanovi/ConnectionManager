//
//  AMConnectionManager.m
//  SampleProject
//
//  Created by Joan Martin on 10/3/12.
//  Copyright (c) 2012 AugiaMobile. All rights reserved.
//

#import "AMConnectionManager.h"

#import "AMConnectionOperation.h"
#import "AMAsynchronousConnection.h"

@interface AMConnectionManager () <AMAsynchronousConnectionDelegate>

@end

@implementation AMConnectionManager
{
    NSOperationQueue *_connectionsOperaitonQueue;
    NSInteger _numberOfActiveConnections;
    
    NSMutableDictionary *_operations;
    NSInteger _lastKey;
    
    // -- Acitons -- //
    NSMutableArray *_actions;
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
        _connectionsOperaitonQueue = [[NSOperationQueue alloc] init];
        _numberOfActiveConnections = 0;
        _lastKey = -1;
        _operations = [NSMutableDictionary dictionary];
        
        _actions = [NSMutableArray array];
    }
    return self;
}

#pragma mark Properties

- (NSInteger)maxConcurrentConnectionCount
{
    return _connectionsOperaitonQueue.maxConcurrentOperationCount;
}

- (void)setMaxConcurrentConnectionCount:(NSInteger)maxConcurrentConnectionCount
{
    _connectionsOperaitonQueue.maxConcurrentOperationCount = maxConcurrentConnectionCount;
}

#pragma mark Public Methods

// ---------- Asynchronous Connections  ---------- //

- (void)performRequest:(NSURLRequest*)request progressStatus:(void (^)(NSDictionary *progressStatus))progressStatusBlock completionBlock:(void (^)(NSURLResponse* response, NSData* data, NSError* error))completionBlock;
{
    AMAsynchronousConnection *action = [[AMAsynchronousConnection alloc] initWithRequest:request progressStatus:progressStatusBlock completionBlock:completionBlock];
    action.delegate = self;
    action.trustedHosts = _trustedHosts;
    [_actions addObject:action];
    [action start];
    _numberOfActiveConnections++;
    [self _refreshNetworkActivityIndicatorState];
}

// ---------- Asynchronous OperationQueue-Based Connections ---------- //

- (NSInteger)performRequest:(NSURLRequest*)request completionBlock:(void (^)(NSURLResponse*, NSData*, NSError*, NSInteger))completion
{
    return [self performRequest:request priority:AMConnectionPriorityNormal completionBlock:completion];
}

- (NSInteger)performRequest:(NSURLRequest*)request priority:(AMConnectionPriority)priority completionBlock:(void (^)(NSURLResponse* response, NSData* data, NSError* error, NSInteger key))completion
{
    NSInteger operationKey;
    
    @synchronized(self)
    {
        operationKey = _lastKey + 1;
        _lastKey = operationKey;
    }
    
    void (^connectionCompletion)(NSURLResponse* response, NSData* data, NSError* error) = ^(NSURLResponse* response, NSData* data, NSError* error) {
        if (completion)
            completion(response, data, error, operationKey);
    };
    
    AMConnectionOperation *operation = [[AMConnectionOperation alloc] initWithRequest:request completionBlock:connectionCompletion];
    [operation setQueuePriority:priority];
    
    _numberOfActiveConnections += 1;
    
    NSNumber *numberKey = [NSNumber numberWithInteger:operationKey];
    [_operations setObject:operation forKey:numberKey];
    
    [operation setCompletionBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [_operations removeObjectForKey:numberKey];
            _numberOfActiveConnections -= 1;
            [self _refreshNetworkActivityIndicatorState];
        });
    }];
    
    [_connectionsOperaitonQueue addOperation:operation];
    [self _refreshNetworkActivityIndicatorState];
    
    return operationKey;
}

- (void)cancelRequestWithKey:(NSInteger)key
{
    NSOperation *operation = [_operations objectForKey:[NSNumber numberWithInteger:key]];
    [operation cancel];
}

- (void)changeToPriority:(AMConnectionPriority)priority requestWithKey:(NSInteger)key
{
    NSOperation *operation = [_operations objectForKey:[NSNumber numberWithInteger:key]];
    [operation setQueuePriority:priority];
}

#pragma mark Private Methods

- (void)_refreshNetworkActivityIndicatorState
{
    if (!_showsNetworkActivityIndicator)
        return;
    
    BOOL state = _numberOfActiveConnections > 0 ? YES : NO;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:state];
}

#pragma mark MMConnectionActionDelegate

- (void)didFinishAsynchronousConnection:(AMAsynchronousConnection *)connectionAction
{
    [_actions removeObjectIdenticalTo:connectionAction];
    
    _numberOfActiveConnections--;
    [self _refreshNetworkActivityIndicatorState];
}

@end
