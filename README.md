ConnectionManager
=================

####Easy management for connections

Here I present a very simple framework to handle connections in a very efficient and easy way. Just give a **NSURLRequest** and you will have in return the result of a **NSURLConnection**. 

The connections are performed asynchronously and the framework allows you to:

* Cancel requests
* Set priorities
* Manage multiple connection queues
* Configure connection queues individualy
* Pause and restart connections
* Get feedback of downloading/uploading status
* Define credentials and trusted servers
* Get the return of the connection using blocks

The framework uses **NSOperationQueue** to perform concurrent connections and manipulate queued calls using asynchronous **NSOperation**s.

##Example of use

###Configuring the Connection Manager

First of all, lets get the instance of the connection manager:

	AMConnectionManager *connectionManager = [AMConnectionManager defaultManager];

We can configure the manager to display the iOS network activity indicator when some connection is being performed:

    connectionManager.showsNetworkActivityIndicator = YES; 
    
Also, we will setup the default connection queue to handle at most 10 connections at same time:
    
    connectionManager.maxConcurrentConnectionCount = 10;
    
We can configure manually a connection queue by getting the **NSOperationQueue** instance and configure it manually:

    NSOperationQueue *queue = [connectionManager operationQueueForIdentifier:@"SOME_IDENTIFIER"];
    
    // Configure the queue here
    
Use an identifier as nil or **AMConnectionManagerDefaultQueueIdentifier** to get the default connection queue.
    

###Performing connections in the default queue

Lets create a request first:

	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"SOME_URL"]];

Then, we are going to send this request using a the default connection queue:
	
    NSInteger connectionKey = [connectionManager performRequest:urlRequest completionBlock:^(NSURLResponse *response, NSData *data, NSError *error, NSInteger key) {
		// Handle here the connection response
    }];

The `key` in the completionBlock is the key returned when calling the method (in this case `connectionKey`).

There are different methods to perform a request in the default queue. For example, you can configure the progress status and the connection priority by calling:

    NSInteger connectionKey = [connectionManager performRequest:urlRequest
                                                 priority:AMConnectionPriorityNormal
                                           progressStatus:^(NSDictionary *progressStatus) {
                                              // Handle the progres status here                             
                                           } completionBlock:^(NSURLResponse *response, NSData *data, NSError *error, NSInteger key) {
                                               // Handle the connection response
                                           }];

###Using multiple queues

In order to use different queues you should create a **AMAsyncConnectionOperation** and pass it to the connection manager giving the desired queue identifier:

    AMAsyncConnectionOperation *operation = [[AMAsyncConnectionOperation alloc] initWithRequest:urlRequest completionBlock:^(NSURLResponse *response, NSData *data, NSError *error) {
            // Handle here the connection response
    }];
    
    operation.progressStatusBlock = ^(NSDictionary *info) {
        // Handle the progress status here
    };
    
    NSInteger connectionKey = [connectionManager performConnectionOperation:operation inQueue:@"SOME_IDENTIFIER"];

Use an identifier as nil or **AMConnectionManagerDefaultQueueIdentifier** to use the default connection queue.

###Changing priorities and canceling connections

We can change the priority of the request doing, for example:

	[connectionManager changeToPriority:AMConnectionPriorityVeryHigh requestWithKey:connectionKey];

Also, we can cancel queued (but not started) connections by doing:

	[connectionManager cancelRequestWithKey:connectionKey]; 
	
###Pausing and restarting connection queues 

The Connection Manager supports pausing connection queues. You can pause and restart a specific queue or all queues. When pausing a connection queue, all current queued connections are canceled and refired when restarting. 

To pause and restart a specific connection queue:

    // Pause
    [connectionManager freezeQueueWithIdentifier:@"SOME_IDENTIFIER"];
    
    // Restart
    [connectionManager unfreezeQueueWithIdentifier:@"SOME_IDENTIFIER"];

To pause and restart all connection queues:

    // Pause
    [connectionManager freeze];
    
    // Restart
    [connectionManager unfreeze];
    
The connection manager doesn't support persistent connection queues freezing through multiple app executions.

---
## Licence ##

Copyright (c) 2013 Joan Martin, vilanovi@gmail.com.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE
