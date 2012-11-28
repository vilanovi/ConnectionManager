//
//  AMConnectionOperation.m
//  SampleProject
//
//  Created by Joan Martin on 10/4/12.
//  Copyright (c) 2012 AugiaMobile. All rights reserved.
//

#import "AMConnectionOperation.h"

@implementation AMConnectionOperation
{
    NSData* _data;
    NSURLResponse *_response;
    NSError *_error;
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
    }
    return self;
}

- (void)concurrentMain
{
    NSError *error = nil;
    NSURLResponse *response = nil;

    _data = [NSURLConnection sendSynchronousRequest:_request returningResponse:&response error:&error];
    _response = response;
    _error = error;
}

- (void)operationDidFinish
{
    if (!self.isCancelled)
    {
        if (_completion)
            _completion(_response,_data,_error);
    }
}

@end
