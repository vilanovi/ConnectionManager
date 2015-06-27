//
//  AMConnectionManager_Private.h
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

#import "AMConnectionManager.h"

/*!
 * Connection operations may call these methods. Do not perform any call to these methods, unexpected behaviour may happen.
 */
@interface AMConnectionManager (Private)

/*!
 * When a connection operation fail notifies the connection manager through this method.
 * @param op The connection operation.
 * @param error The connection error.
 */
- (void)am_connectionOperation:(AMAsyncConnectionOperation*)op connectionDidFailWithError:(NSError*)error;

/*!
 * When a connection operation fail in the authentication, notifies the connection manager through this method.
 * @param op The connection operation.
 * @param challange The authentication challange responsible of failing the authentication.
 */
- (void)am_connectionOperation:(AMAsyncConnectionOperation*)op authenticationDidFailWithAuthenticationChallenge:(NSURLAuthenticationChallenge*)challange;

@end
