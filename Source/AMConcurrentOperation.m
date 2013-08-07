//
//  AMConcurrentOperation.m
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
