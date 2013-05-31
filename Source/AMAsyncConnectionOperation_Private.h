//
//  AMAsyncConnectionOperation_Private.h
//  ConnectionManager
//
//  Created by Joan Martin on 12/13/12.
//  Copyright (c) 2012 Joan Martin. All rights reserved.
//

#import "AMAsyncConnectionOperation.h"

@interface AMAsyncConnectionOperation ()

/*!
 * Each operation holds a reference to the AMConnectionManager assigned key.
 * @discussion This reference is used in internaly by the AMConnectionManager. Do not change the value or use it in any case. 
 */
@property (nonatomic, strong, readwrite) id connectionManagerKey;

@end
