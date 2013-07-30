//
//  AMConnectionGroup.m
//  ConnectionManager
//
//  Created by Joan Martin on 1/11/13.
//  Copyright (c) 2013 Joan Martin. All rights reserved.
//

#import "AMConnectionGroup.h"

#import "AMConnectionManager.h"
#import "AMAsyncConnectionOperation.h"

@implementation AMConnectionGroup
{
    NSMutableIndexSet *_connectionKeys;
    NSMutableArray *_pausedConnections;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _connectionKeys = [NSMutableIndexSet indexSet];
        _pausedConnections = [NSMutableArray array];
    }
    return self;
}

#pragma mark Public Methods

- (void)addConnectionKey:(NSInteger)connectionKey
{
    if (connectionKey != NSNotFound)
        [_connectionKeys addIndex:connectionKey];
}

- (void)removeConnectionKey:(NSInteger)connectionKey
{
    [_connectionKeys removeIndex:connectionKey];
}

- (void)cancel
{
    [self _cancelCurrentConnections];
}

- (void)pause
{
    [self _pauseCurrentConnections];
}

- (void)resume
{
    [self _restartCurrentConnections];
}

#pragma mark Private Methods

- (void)_cancelCurrentConnections
{    
    AMConnectionManager *connectionManager = [AMConnectionManager defaultManager];
    
    NSIndexSet *indexSet = [_connectionKeys copy];
    
    NSInteger index = [indexSet firstIndex];
    
    while (index != NSNotFound)
    {
        [connectionManager cancelRequestWithKey:index];
        index = [indexSet indexGreaterThanIndex:index];
    }
    
    [_pausedConnections removeAllObjects];
}

- (void)_pauseCurrentConnections
{    
    AMConnectionManager *connectionManager = [AMConnectionManager defaultManager];
    
    NSIndexSet *indexSet = [_connectionKeys copy];
    
    NSInteger key = [indexSet firstIndex];
    
    while (key != NSNotFound)
    {
        AMAsyncConnectionOperation *connectionOperation = [connectionManager cancelRequestWithKey:key];
        
        if (connectionOperation)
            [_pausedConnections addObject:connectionOperation];
        
        key = [indexSet indexGreaterThanIndex:key];
    }
    
    [_connectionKeys removeAllIndexes];
}

- (void)_restartCurrentConnections
{
    AMConnectionManager *connectionManager = [AMConnectionManager defaultManager];
    
    for (AMAsyncConnectionOperation *operation in _pausedConnections)
    {
        NSInteger key = [connectionManager performConnectionOperation:operation inQueue:AMConnectionManagerDefaultQueueIdentifier useAuthentication:YES];
        [_connectionKeys addIndex:key];
    }
    
    [_pausedConnections removeAllObjects];
}

- (void)changeConnectionPrioritiesTo:(AMConnectionPriority)priority
{
    AMConnectionManager *connectionManager = [AMConnectionManager defaultManager];
    
    NSIndexSet *indexSet = [_connectionKeys copy];
    
    NSInteger key = [indexSet firstIndex];
    
    while (key != NSNotFound)
    {
        [connectionManager changeToPriority:priority requestWithKey:key];
        key = [indexSet indexGreaterThanIndex:key];
    }
    
}

@end
