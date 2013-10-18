//
//  AMConnectionManager.m
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

#import "AMConnectionManager_Private.h"

#import "AMAsyncConnectionOperation_Private.h"

NSString * const AMConnectionManagerConnectionsDidStartNotification = @"AMConnectionManagerConnectionsDidStartNotification";
NSString * const AMConnectionManagerConnectionsDidFinishNotification = @"AMConnectionManagerConnectionsDidFinishNotification";
NSString * const AMConnectionManagerConnectionsQueueIdentifierKey = @"AMConnectionManagerConnectionsQueueIdentifierKey";
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
    
    UIBackgroundTaskIdentifier _bgTask;
    NSInteger _queuesNotEmpty;
    BOOL _isBackroundExecution;
    
    NSMutableDictionary *_credentials;
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
        _executeCompletionBlocksOnMainThread = NO;
        
        _queues = [NSMutableDictionary dictionary];
        _pausedOperations = [NSMutableDictionary dictionary];
        
        _backgroundExecutionQueueIdentifiers = [NSSet set];
        
        _isBackroundExecution = NO;
        _queuesNotEmpty = 0;
        _bgTask = UIBackgroundTaskInvalid;
        
        _lastKey = -1;
        _operations = [NSMutableDictionary dictionary];
        _showConnectionErrors = NO;
        
        _credentials = [NSMutableDictionary dictionary];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(AM_notificationReceived:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [nc addObserver:self selector:@selector(AM_notificationReceived:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

#pragma mark Properties

- (NSInteger)maxConcurrentConnectionCount
{
    return [[self AM_queueWithIdentifier:AMConnectionManagerDefaultQueueIdentifier] maxConcurrentOperationCount];
}

- (void)setMaxConcurrentConnectionCount:(NSInteger)maxConcurrentConnectionCount
{
    [[self AM_queueWithIdentifier:AMConnectionManagerDefaultQueueIdentifier] setMaxConcurrentOperationCount:maxConcurrentConnectionCount];
}

- (void)setBackgroundExecutionQueueIdentifiers:(NSSet *)backgroundExecutionQueueIdentifiers
{
    _backgroundExecutionQueueIdentifiers = backgroundExecutionQueueIdentifiers;
}

#pragma mark Public Methods

- (void)setMaxConcurrentConnectionCount:(NSInteger)maxConcurrentConnectionCount inQueue:(NSString*)queueIdentifier
{
    [[self AM_queueWithIdentifier:queueIdentifier] setMaxConcurrentOperationCount:maxConcurrentConnectionCount];
}

- (void)freezeQueueWithIdentifier:(NSString*)identifier
{
    NSOperationQueue *queue = [self operationQueueForIdentifier:identifier];
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
    NSOperationQueue *queue = [self operationQueueForIdentifier:identifier];
    NSMutableArray *pausedOperations = [_pausedOperations valueForKey:identifier];
    
    for (AMAsyncConnectionOperation *operation in pausedOperations)
    {
        AMAsyncConnectionOperation *newOperation = [operation copy];
        
        [_operations setObject:newOperation forKey:newOperation.connectionManagerKey];

        [queue addOperation:newOperation];
        [self AM_refreshNetworkActivityIndicatorState];
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
    return [self AM_queueWithIdentifier:identifier];
}

- (NSInteger)performConnectionOperation:(AMAsyncConnectionOperation*)operation inQueue:(NSString*)queueIdentifier
{
    return [self performConnectionOperation:operation inQueue:queueIdentifier useAuthentication:NO];
}

- (NSInteger)performConnectionOperation:(AMAsyncConnectionOperation*)operation inQueue:(NSString*)queueIdentifier useAuthentication:(BOOL)flag
{
    NSOperationQueue *queue = [self AM_queueWithIdentifier:queueIdentifier];
    
    NSInteger operationKey = [self AM_nextKey];
    
    NSNumber *numberKey = @(operationKey);
    operation.connectionManagerKey = numberKey;
    
    if (flag)
    {
        operation.serverTurstAuthentication = [_trustedHosts containsObject:operation.request.URL.host];
        operation.credential = [_credentials valueForKey:operation.request.URL.host];
    }
    
    [_operations setObject:operation forKey:numberKey];
    
    __weak AMConnectionManager *connectionManager = self;
    [operation setCompletionBlock:^{
        [_operations removeObjectForKey:numberKey];
        [connectionManager AM_refreshNetworkActivityIndicatorState];
    }];
    
    [queue addOperation:operation];
    [self AM_refreshNetworkActivityIndicatorState];
    
    return operationKey;
}

- (NSInteger)performRequest:(NSURLRequest*)request completionBlock:(void (^)(NSURLResponse*, NSData*, NSError*, NSInteger))completion
{
    return [self performRequest:request
                       priority:AMConnectionPriorityNormal
                        inQueue:nil
                 progressStatus:NULL
                completionBlock:completion];
}

- (NSInteger)performRequest:(NSURLRequest*)request
                    inQueue:(NSString*)queueIdentifier
            completionBlock:(void (^)(NSURLResponse* response, NSData* data, NSError* error, NSInteger key))completion;
{    
    return [self performRequest:request
                       priority:AMConnectionPriorityNormal
                        inQueue:queueIdentifier
                 progressStatus:NULL
                completionBlock:completion];
}


- (NSInteger)performRequest:(NSURLRequest*)request priority:(AMConnectionPriority)priority completionBlock:(void (^)(NSURLResponse* response, NSData* data, NSError* error, NSInteger key))completion
{
    return [self performRequest:request
                       priority:priority
                        inQueue:nil
                 progressStatus:NULL
                completionBlock:completion];
}


- (NSInteger)performRequest:(NSURLRequest*)request progressStatus:(void (^)(NSDictionary *progressStatus))progressStatusBlock completionBlock:(void (^)(NSURLResponse* response, NSData* data, NSError* error, NSInteger key))completion
{
    return [self performRequest:request
                       priority:AMConnectionPriorityNormal
                        inQueue:nil
                 progressStatus:progressStatusBlock
                completionBlock:completion];
}

- (NSInteger)performRequest:(NSURLRequest*)request priority:(AMConnectionPriority)priority progressStatus:(void (^)(NSDictionary *progressStatus))progressStatusBlock completionBlock:(void (^)(NSURLResponse* response, NSData* data, NSError* error, NSInteger key))completion
{
    return [self performRequest:request
                       priority:priority
                        inQueue:nil
                 progressStatus:progressStatusBlock
                completionBlock:completion];
}

- (NSInteger)performRequest:(NSURLRequest*)request
                   priority:(AMConnectionPriority)priority
                    inQueue:(NSString*)queueIdentifier
             progressStatus:(void (^)(NSDictionary *progressStatus))progressStatusBlock
            completionBlock:(void (^)(NSURLResponse* response, NSData* data, NSError* error, NSInteger key))completion
{
    NSInteger operationKey = [self AM_nextKey];
    
    void (^connectionCompletion)(NSURLResponse* response, NSData* data, NSError* error) = ^(NSURLResponse* response, NSData* data, NSError* error) {
        
        if (!completion)
            return;
        
        if (_executeCompletionBlocksOnMainThread)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(response, data, error, operationKey);
            });
        }
        else
        {
            completion(response, data, error, operationKey);
        }
    };

    AMAsyncConnectionOperation *operation = [[AMAsyncConnectionOperation alloc] initWithRequest:request completionBlock:connectionCompletion];
    operation.serverTurstAuthentication = [_trustedHosts containsObject:request.URL.host];
    operation.credential = [_credentials valueForKey:request.URL.host];
    
    operation.progressStatusBlock = progressStatusBlock;
    operation.queuePriority = priority;
    
    NSNumber *numberKey = @(operationKey);
    operation.connectionManagerKey = numberKey;
    [_operations setObject:operation forKey:numberKey];
    
    __weak AMConnectionManager *connectionManager = self;
    [operation setCompletionBlock:^{
        [_operations removeObjectForKey:numberKey];
        [connectionManager AM_refreshNetworkActivityIndicatorState];
    }];
    
    NSOperationQueue *queue = [self AM_queueWithIdentifier:queueIdentifier];
    
    [queue addOperation:operation];
    [self AM_refreshNetworkActivityIndicatorState];
    
    return operationKey;
}

- (AMAsyncConnectionOperation*)cancelRequestWithKey:(NSInteger)key
{
    NSOperation *operation = [_operations objectForKey:@(key)];
    
    AMAsyncConnectionOperation *copy = [operation copy];
    
    [operation cancel];
    
    [_operations removeObjectForKey:@(key)];
    [self AM_refreshNetworkActivityIndicatorState];
    
    return copy;
}

- (void)cancelAllRequests
{
    [[_operations allValues] makeObjectsPerformSelector:@selector(cancel)];
    [_operations removeAllObjects];
    [self AM_refreshNetworkActivityIndicatorState];
}

- (void)changeToPriority:(AMConnectionPriority)priority requestWithKey:(NSInteger)key
{
    NSOperation *operation = [_operations objectForKey:@(key)];
    [operation setQueuePriority:priority];
}

- (void)addBackgroundExecutionQueueIdentifier:(NSString*)queueIdentifier
{
    _backgroundExecutionQueueIdentifiers = [_backgroundExecutionQueueIdentifiers setByAddingObject:queueIdentifier];
}

- (void)removeBackgroundExecutionQueueIdentifier:(NSString*)queueIdentifier
{
    NSMutableSet *set = [_backgroundExecutionQueueIdentifiers mutableCopy];
    [set removeObject:queueIdentifier];
    _backgroundExecutionQueueIdentifiers = [set copy];
}

- (NSURLCredential*)credentialForHost:(NSString*)host
{
    return [_credentials valueForKey:host];
}

- (void)setCredential:(NSURLCredential*)credential forHost:(NSString*)host
{
    [_credentials setValue:credential forKey:host];
}

#pragma mark Private Methods

- (NSOperationQueue*)AM_queueWithIdentifier:(NSString*)identifier
{
    if (identifier == nil)
        identifier = AMConnectionManagerDefaultQueueIdentifier;

    NSOperationQueue *queue = [_queues valueForKey:identifier];
    
    if (!queue)
    {
        queue = [[NSOperationQueue alloc] init];
        [_queues setValue:queue forKey:identifier];
        
        [queue addObserver:self
                forKeyPath:@"operationCount"
                   options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                   context:nil];
    }
    
    return queue;
}

- (void)AM_refreshNetworkActivityIndicatorState
{
    if (!_showsNetworkActivityIndicator)
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        BOOL state = _operations.count > 0;
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:state];
    });
}

- (NSInteger)AM_nextKey
{
    NSInteger operationKey;
    
    @synchronized(self)
    {
        operationKey = _lastKey + 1;
        _lastKey = operationKey;
    }
    
    return operationKey;
}

- (void)AM_presentAlertViewForError:(NSError*)error;
{
    if (!_showConnectionErrors)
        return;
        
    @synchronized(self)
    {
        if (_isShowingAlert)
            return;
        
        _isShowingAlert = YES;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection Error", @"[AMConnectionManager] AlertView title")
                                                            message:error.localizedDescription
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Dimsiss", @"[AMConnectionManager] AlertView dismiss button")
                                                  otherButtonTitles:nil];
        [alertView show];
    });
}

- (void)AM_notificationReceived:(NSNotification*)notification
{
    if ([notification.name isEqualToString:UIApplicationDidBecomeActiveNotification])
    {
        _isBackroundExecution = NO;
        _queuesNotEmpty = 0;
        [self unfreeze];
    }
    else if ([notification.name isEqualToString:UIApplicationDidEnterBackgroundNotification])
    {
        _isBackroundExecution = YES;
        _queuesNotEmpty = 0;
        
        NSArray *queueIdentifiers = [_queues allKeys];
        
        for (NSString *queueIdentifier in queueIdentifiers)
        {
            if (![_backgroundExecutionQueueIdentifiers containsObject:queueIdentifier])
                [self freezeQueueWithIdentifier:queueIdentifier];
            else
            {
                NSOperationQueue *queue = [_queues valueForKey:queueIdentifier];
                _queuesNotEmpty += queue.operationCount == 0 ? 0 : 1;
            }
        }
        
        if (_queuesNotEmpty > 0)
        {
            UIApplication *application = [UIApplication sharedApplication];
                        
            _bgTask = [application beginBackgroundTaskWithExpirationHandler: ^{
                
                [self freeze];
                
                [application endBackgroundTask:_bgTask];
                _bgTask = UIBackgroundTaskInvalid;
            }];
        }
    }
}

- (void)AM_stopBackgroundTask
{
    if (_queuesNotEmpty > 0)
        return;
    
    UIApplication *application = [UIApplication sharedApplication];
    [application endBackgroundTask:_bgTask];
    _bgTask = UIBackgroundTaskInvalid;
}

#pragma mark - Protocols

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"operationCount"])
    {
        NSArray *keys = [_queues allKeys];
        
        NSInteger oldOperationCount = [[change valueForKey:NSKeyValueChangeOldKey] integerValue];
        NSInteger newOperationCount = [[change valueForKey:NSKeyValueChangeNewKey] integerValue];
        
        if (newOperationCount == 0)
        {
            for (NSString *key in keys)
            {
                NSOperationQueue *queue = [_queues valueForKey:key];
                if (object == queue)
                {
                    [[NSNotificationCenter defaultCenter] postNotificationName:AMConnectionManagerConnectionsDidFinishNotification
                                                                        object:self
                                                                      userInfo:@{AMConnectionManagerConnectionsQueueIdentifierKey : key}];
                    
                    if ([_backgroundExecutionQueueIdentifiers containsObject:key] && _isBackroundExecution)
                    {
                        _queuesNotEmpty--;
                        
                        if (_queuesNotEmpty == 0)
                        {
                            // By executing this method at the end of the run loop we give a chance to the app to add new requests and cancel the background execution cancelation.
                            [self performSelector:@selector(AM_stopBackgroundTask) withObject:nil afterDelay:0.0];
                        }
                    }
                }
            }
        }
        else if (newOperationCount > 0 && oldOperationCount == 0)
        {
            for (NSString *key in keys)
            {
                NSOperationQueue *queue = [_queues valueForKey:key];
                if (object == queue)
                {
                    [[NSNotificationCenter defaultCenter] postNotificationName:AMConnectionManagerConnectionsDidStartNotification
                                                                        object:self
                                                                      userInfo:@{AMConnectionManagerConnectionsQueueIdentifierKey : key}];
                }
            }
        }
    }
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    _isShowingAlert = NO;
}

@end


@implementation AMConnectionManager (Private)

- (void)AM_connectionOperation:(AMAsyncConnectionOperation*)op connectionDidFailWithError:(NSError*)error
{
    [self AM_presentAlertViewForError:error];

    if ([_delegate respondsToSelector:@selector(connectionManager:connectionDidFailForConnectionOperation:error:)])
        [_delegate connectionManager:self connectionDidFailForConnectionOperation:op error:error];
}

- (void)AM_connectionOperation:(AMAsyncConnectionOperation*)op authenticationDidFailWithAuthenticationChallenge:(NSURLAuthenticationChallenge*)challange
{
    if ([_delegate respondsToSelector:@selector(connectionManager:authenticationDidFailForConnectionOperation:authenticationChallange:)])
        [_delegate connectionManager:self authenticationDidFailForConnectionOperation:op authenticationChallange:challange];
}

@end
