//
//  AMConnectionGroup.m
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
