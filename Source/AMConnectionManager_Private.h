//
//  AMConnectionManager_Private.h
//  ConnectionManager
//
//  Created by Joan Martin on 11/29/12.
//  Copyright (c) 2012 Joan Martin. All rights reserved.
//

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
- (void)AM_connectionOperation:(AMAsyncConnectionOperation*)op connectionDidFailWithError:(NSError*)error;

/*!
 * When a connection operation fail in the authentication, notifies the connection manager through this method.
 * @param op The connection operation.
 * @param challange The authentication challange responsible of failing the authentication.
 */
- (void)AM_connectionOperation:(AMAsyncConnectionOperation*)op authenticationDidFailWithAuthenticationChallenge:(NSURLAuthenticationChallenge*)challange;

@end
