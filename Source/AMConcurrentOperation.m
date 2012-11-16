//
//  AMConcurrentOperation.m
//  SampleProject
//
//  Created by Joan Martin on 10/4/12.
//  Copyright (c) 2012 AugiaMobile. All rights reserved.
//

#import "AMConcurrentOperation.h"

@implementation AMConcurrentOperation
{
    BOOL _executing;
    BOOL _finished;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _executing = NO;
        _finished = NO;
    }
    return self;
}

- (BOOL)isConcurrent
{
    return YES;
}

- (BOOL)isExecuting
{
    return _executing;
}

- (BOOL)isFinished
{
    return _finished;
}

- (void)start
{
    if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(start) withObject:self waitUntilDone:NO];
        return;
    }
    
    if ([self isCancelled])
    {
        // Must move the operation to the finished state if it is canceled.
        [self willChangeValueForKey:@"isFinished"];
        _finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        [self operationDidFinish];
        return;
    }
    
    // If the operation is not canceled, begin executing the task.
    [self willChangeValueForKey:@"isExecuting"];
    [NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
    _executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)main
{
    @try
    {
        // Do the main work of the operation here.
        [self concurrentMain];
        
        [self performSelectorOnMainThread:@selector(completeOperation) withObject:self waitUntilDone:NO];
    }
    @catch(...)
    {
        // Do not rethrow exceptions.
    }
}

- (void)completeOperation
{
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    
    _executing = NO;
    _finished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
    
    [self operationDidFinish];
}

- (void)concurrentMain
{
    // Override in subclasses
}

- (void)operationDidFinish
{
    // Override in subclasses
}

@end
