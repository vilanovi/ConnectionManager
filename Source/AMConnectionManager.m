//
//  AMConnectionManager.m
//  SampleProject
//
//  Created by Joan Martin on 10/3/12.
//  Copyright (c) 2012 AugiaMobile. All rights reserved.
//

#import "AMConnectionManager_Private.h"

#import "AMAsyncConnectionOperation_Private.h"

NSString * const AMConnectionManagerDefaultQueueIdentifier = @"AMConnectionManagerDefaultQueueIdentifier";

@interface AMConnectionManager () <UIAlertViewDelegate>

@end

@implementation AMConnectionManager
{
    NSMutableDictionary *_queues;
    NSMutableDictionary *_pausedOperations;
        
    NSMutableDictionary *_operations;
    NSInteger _lastKey;
    
    BOOL _isShowingAlert;
}

@dynamic maxConcurrentConnectionCount;

+ (AMConnectionManager*)defaultManager
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[AMConnectionManager alloc] init];
    });
    return _sharedObject;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _queues = [NSMutableDictionary dictionary];
        _pausedOperations = [NSMutableDictionary dictionary];
        
        _lastKey = -1;
        _operations = [NSMutableDictionary dictionary];
        _showConnectionErrors = YES;
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

- (void)freezeQueueWithIdentifier:(NSString*)identifier
{
    NSOperationQueue *queue = [_queues valueForKey:identifier];
    NSMutableArray *pausedOperations = [_pausedOperations valueForKey:identifier];
    
    [queue setSuspended:YES];
    
    if (!pausedOperations)
    {
        pausedOperations = [NSMutableArray array];
        [_pausedOperations setValue:pausedOperations forKey:identifier];
    }
    
    for (AMAsyncConnectionOperation *operation in queue.operations)
    {
        if (operation.isExecuting)
        {
            [operation cancel];
            [pausedOperations addObject:operation];
        }
    }
}

- (void)unfreezeQueueWithIdentifier:(NSString*)identifier
{
    NSOperationQueue *queue = [_queues valueForKey:identifier];
    NSMutableArray *pausedOperations = [_pausedOperations valueForKey:identifier];
    
    for (AMAsyncConnectionOperation *operation in pausedOperations)
    {
        AMAsyncConnectionOperation *newOperation = [[AMAsyncConnectionOperation alloc] initWithRequest:operation.request completionBlock:operation.completion];
        newOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
        newOperation.connectionManagerKey = operation.connectionManagerKey;
        
        __weak AMConnectionManager *connectionManager = self;
        [newOperation setCompletionBlock:^{
            [_operations removeObjectForKey:operation.connectionManagerKey];
            [connectionManager _refreshNetworkActivityIndicatorState];
        }];
        
        [_operations setObject:newOperation forKey:newOperation.connectionManagerKey];

        [queue addOperation:newOperation];
        [self _refreshNetworkActivityIndicatorState];
    }
    
    [pausedOperations removeAllObjects];
    [queue setSuspended:NO];
}

- (void)freeze
{
    NSArray *allKeys = [_queues allKeys];
    for (NSString *key in allKeys)
    {
        [self freezeQueueWithIdentifier:key];
    }
}

- (void)unfreeze
{
    NSArray *allKeys = [_queues allKeys];
    for (NSString *key in allKeys)
    {
        [self unfreezeQueueWithIdentifier:key];
    }
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
    operation.connectionManagerKey = numberKey;
    
    [_operations setObject:operation forKey:numberKey];
    
    __weak AMConnectionManager *connectionManager = self;
    [operation setCompletionBlock:^{
        [_operations removeObjectForKey:numberKey];
        [connectionManager _refreshNetworkActivityIndicatorState];
    }];
    
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
    operation.connectionManagerKey = numberKey;
    [_operations setObject:operation forKey:numberKey];
    
    __weak AMConnectionManager *connectionManager = self;
    [operation setCompletionBlock:^{
        [_operations removeObjectForKey:numberKey];
        [connectionManager _refreshNetworkActivityIndicatorState];
    }];
    
    NSOperationQueue *queue = [self _queueWithIdentifier:AMConnectionManagerDefaultQueueIdentifier];
    
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
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        BOOL state = _operations.count > 0;
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:state];
    });
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

- (void)_presentAlertViewForError:(NSError*)error;
{
    if (!_showConnectionErrors)
        return;
        
    @synchronized(self)
    {
        if (_isShowingAlert)
            return;
        
        _isShowingAlert = YES;
    }
    
    if (![NSThread isMainThread])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection Error",nil)
                                                                message:error.localizedDescription
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"Dimsiss",nil)
                                                      otherButtonTitles:nil];
            [alertView show];
        });
    }
}

#pragma mark UIAlertView

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    _isShowingAlert = NO;
}

@end
