//
//  AMAsynchronousConnection.h
//  SampleProject
//
//  Created by Joan Martin on 10/5/12.
//  Copyright (c) 2012 AugiaMobile. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AMConnectionManagerTypes.h"

@class AMAsynchronousConnection;

@protocol AMAsynchronousConnectionDelegate <NSObject>

@optional
- (void)didFinishAsynchronousConnection:(AMAsynchronousConnection*)connectionAction;

@end

@interface AMAsynchronousConnection : NSObject

- (id)initWithRequest:(NSURLRequest*)request completionBlock:(void (^)(NSURLResponse* response, NSData* data, NSError* error))completionBlock;
- (id)initWithRequest:(NSURLRequest*)request progressStatus:(void (^)(NSDictionary *progressStatus))progressStatusBlock completionBlock:(void (^)(NSURLResponse* response, NSData* data, NSError* error))completionBlock;

- (void)start;

@property (nonatomic, strong, readonly) NSURLRequest *request;
@property (nonatomic, strong, readonly) void (^progressStatusBlock)(NSDictionary *info);
@property (nonatomic, strong, readonly) void (^completionBlock)(NSURLResponse* response, NSData* data, NSError* error);

@property (nonatomic, strong, readwrite) NSArray *trustedHosts;

@property (nonatomic, weak) id <AMAsynchronousConnectionDelegate> delegate;

@end
